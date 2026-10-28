/*
 * Copyright (c) 2025 ICLab_HUST
 * SPDX-License-Identifier: Apache-2.0
 *
 *  Register Map (byte-addressed, word-aligned accesses):
 *
 *  0x00  CTRL    [W] bit0 = start (self-clearing)
 *                    bit1 = mode  (0 = RX: ui_in → buffer,
 *                                  1 = TX: buffer → uo_out)
 *                    bit2 = irq_enable
 *
 *  0x04  COUNT   [RW] Number of bytes to transfer (1-32)
 *
 *  0x08  DIVISOR [RW] Output/sample clock divisor.
 *                     One byte is transferred every (DIVISOR+1) clocks.
 *                     Reset default: 63 → ~1 MHz at 64 MHz clock.
 *
 *  0x0C  STATUS  [R]  bit0 = busy
 *                     bit1 = done
 *
 *  0x10  CLR_IRQ [W]  Write any value to clear 'done' and deassert interrupt.
 *
 *  0x14  DATA0   [RW] Buffer bytes  3: 0
 *  0x18  DATA1   [RW] Buffer bytes  7: 4
 *  0x1C  DATA2   [RW] Buffer bytes 11: 8
 *  0x20  DATA3   [RW] Buffer bytes 15:12
 *  0x24  DATA4   [RW] Buffer bytes 19:16
 *  0x28  DATA5   [RW] Buffer bytes 23:20
 *  0x2C  DATA6   [RW] Buffer bytes 27:24
 *  0x30  DATA7   [RW] Buffer bytes 31:28
 *
 * Operation:
 *   TX mode  – CPU fills DATA[0..N/4], sets COUNT, optionally sets DIVISOR,
 *              then writes 1 to CTRL[start]. The DMA clocks each byte out on
 *              uo_out[7:0] at the configured rate and sets STATUS[done] when
 *              the last byte has been sent.
 *
 *   RX mode  – CPU sets COUNT, optionally sets DIVISOR, then writes 1 to
 *              CTRL[start] with bit1 = 0. The DMA samples ui_in[7:0] at the
 *              configured rate, fills DATA[0..N/4], and sets STATUS[done] when
 *              COUNT bytes have been captured.
 *
 *   In both modes the interrupt line is asserted on completion when
 *   CTRL[irq_enable] is set. Write any value to CLR_IRQ to deassert.
 */

`default_nettype none

module tqvp_dma (
    input         clk,          // Clock - the TinyQV project clock is normally set to 64MHz.
    input         rst_n,        // Reset_n - low to reset.

    input  [7:0]  ui_in,        // The input PMOD, always available.  Note that ui_in[7] is normally used for UART RX.
                                // The inputs are synchronized to the clock, note this will introduce 2 cycles of delay on the inputs.

    output [7:0]  uo_out,       // The output PMOD.  Each wire is only connected if this peripheral is selected.
                                // Note that uo_out[0] is normally used for UART TX.

    input [5:0]   address,      // Address within this peripheral's address space
    input [31:0]  data_in,      // Data in to the peripheral, bottom 8, 16 or all 32 bits are valid on write.

    // Data read and write requests from the TinyQV core.
    input [1:0]   data_write_n, // 11 = no write, 00 = 8-bits, 01 = 16-bits, 10 = 32-bits
    input [1:0]   data_read_n,  // 11 = no read,  00 = 8-bits, 01 = 16-bits, 10 = 32-bits
    
    output [31:0] data_out,     // Data out from the peripheral, bottom 8, 16 or all 32 bits are valid on read when data_ready is high.
    output        data_ready,

    output        user_interrupt  // Dedicated interrupt request for this peripheral
);

    // -----------------------------------------------------------------------
    // Configuration registers
    // -----------------------------------------------------------------------
    reg        dma_mode;        // 0=RX, 1=TX
    reg        irq_enable;
    reg  [5:0] count;           // bytes to transfer (1..32)
    reg  [7:0] divisor;         // clock divisor

    // 32-byte data buffer addressed as 8 × 32-bit words
    reg [31:0] dbuf [0:7];

    // -----------------------------------------------------------------------
    // DMA state machine
    // -----------------------------------------------------------------------
    localparam ST_IDLE = 2'd0,
               ST_RUN  = 2'd1,
               ST_DONE = 2'd2;

    reg  [1:0] state;
    reg  [5:0] byte_idx;     // byte counter (0 .. count-1)
    reg  [7:0] div_cnt;      // clock-divider counter
    reg        dma_done;
    reg        irq_reg;

    // Convenience: which 32-bit word and byte lane for byte_idx
    wire [2:0] word_idx  = byte_idx[4:2];
    wire [1:0] byte_lane = byte_idx[1:0];

    // -----------------------------------------------------------------------
    // Register write decoder
    // -----------------------------------------------------------------------
    // Byte-enable helper: which bytes of data_in are being written?
    wire wr_byte0  = (data_write_n != 2'b11);
    wire wr_byte1  = (data_write_n[1] != data_write_n[0]);   // 16/32-bit
    wire wr_byte23 = (data_write_n == 2'b10);                 // 32-bit only

    // Writes are decoded on the posedge
    integer i;
    always @(posedge clk) begin
        if (!rst_n) begin
            dma_mode   <= 0;
            irq_enable <= 0;
            count      <= 6'd1;
            divisor    <= 8'd63;
            state      <= ST_IDLE;
            byte_idx   <= 0;
            div_cnt    <= 0;
            dma_done   <= 0;
            irq_reg    <= 0;
            for (i = 0; i < 8; i = i + 1) dbuf[i] <= 32'd0;

        end else begin

            // ------------------------------------------------------------------
            // Register write handling
            // ------------------------------------------------------------------
            if (data_write_n != 2'b11) begin
                case (address)
                    // 0x00 – CTRL  (byte 0 carries the control bits)
                    6'h00: begin
                        if (wr_byte0) begin
                            irq_enable <= data_in[2];
                            dma_mode   <= data_in[1];
                            // start: kick off a new transfer
                            if (data_in[0] && state == ST_IDLE) begin
                                state    <= ST_RUN;
                                byte_idx <= 6'd0;
                                div_cnt  <= 8'd0;
                                dma_done <= 1'b0;
                                irq_reg  <= 1'b0;
                            end
                        end
                    end

                    // 0x04 – COUNT
                    6'h04: begin
                        if (wr_byte0) begin
                            // Clamp to 1..32
                            if (data_in[5:0] == 6'd0)
                                count <= 6'd1;
                            else if (data_in[5:0] > 6'd32)
                                count <= 6'd32;
                            else
                                count <= data_in[5:0];
                        end
                    end

                    // 0x08 – DIVISOR
                    6'h08: begin
                        if (wr_byte0) divisor <= data_in[7:0];
                    end

                    // 0x10 – CLR_IRQ  (any write clears done + irq)
                    6'h10: begin
                        dma_done <= 1'b0;
                        irq_reg  <= 1'b0;
                    end

                    // 0x14..0x30 – DATA buffer (addresses 6'h14..6'h30)
                    // Decoded as: dbuf[addr[4:2]] with per-byte enables
                    default: begin
                        if (address >= 6'h14 && address <= 6'h30) begin
                            // address[4:2] gives the word index within the buffer
                            // but address is 6 bits and buffer base is 0x14 = 20
                            // word = (address - 6'h14) >> 2 = address[4:2] - 5 ... simpler:
                            // We'll use a dedicated comparison block below.
                        end
                    end
                endcase

                // Buffer word writes need the word index: (address[4:2] - 3'h5)
                // because 0x14 >> 2 = 5, 0x18 >> 2 = 6, ... 0x30 >> 2 = 12
                // word_wr_idx = (address >> 2) - 5  where address[5:2] is the word address
                if (address >= 6'h14 && address <= 6'h30) begin
                    // word_wr_idx: 0x14->0, 0x18->1, ..., 0x30->7
                    case (address)
                        6'h14: begin
                            if (wr_byte0)  dbuf[0][ 7: 0] <= data_in[ 7: 0];
                            if (wr_byte1)  dbuf[0][15: 8] <= data_in[15: 8];
                            if (wr_byte23) dbuf[0][31:16] <= data_in[31:16];
                        end
                        6'h18: begin
                            if (wr_byte0)  dbuf[1][ 7: 0] <= data_in[ 7: 0];
                            if (wr_byte1)  dbuf[1][15: 8] <= data_in[15: 8];
                            if (wr_byte23) dbuf[1][31:16] <= data_in[31:16];
                        end
                        6'h1C: begin
                            if (wr_byte0)  dbuf[2][ 7: 0] <= data_in[ 7: 0];
                            if (wr_byte1)  dbuf[2][15: 8] <= data_in[15: 8];
                            if (wr_byte23) dbuf[2][31:16] <= data_in[31:16];
                        end
                        6'h20: begin
                            if (wr_byte0)  dbuf[3][ 7: 0] <= data_in[ 7: 0];
                            if (wr_byte1)  dbuf[3][15: 8] <= data_in[15: 8];
                            if (wr_byte23) dbuf[3][31:16] <= data_in[31:16];
                        end
                        6'h24: begin
                            if (wr_byte0)  dbuf[4][ 7: 0] <= data_in[ 7: 0];
                            if (wr_byte1)  dbuf[4][15: 8] <= data_in[15: 8];
                            if (wr_byte23) dbuf[4][31:16] <= data_in[31:16];
                        end
                        6'h28: begin
                            if (wr_byte0)  dbuf[5][ 7: 0] <= data_in[ 7: 0];
                            if (wr_byte1)  dbuf[5][15: 8] <= data_in[15: 8];
                            if (wr_byte23) dbuf[5][31:16] <= data_in[31:16];
                        end
                        6'h2C: begin
                            if (wr_byte0)  dbuf[6][ 7: 0] <= data_in[ 7: 0];
                            if (wr_byte1)  dbuf[6][15: 8] <= data_in[15: 8];
                            if (wr_byte23) dbuf[6][31:16] <= data_in[31:16];
                        end
                        6'h30: begin
                            if (wr_byte0)  dbuf[7][ 7: 0] <= data_in[ 7: 0];
                            if (wr_byte1)  dbuf[7][15: 8] <= data_in[15: 8];
                            if (wr_byte23) dbuf[7][31:16] <= data_in[31:16];
                        end
                        default: ;
                    endcase
                end
            end // write handling

            // ------------------------------------------------------------------
            // DMA engine
            // ------------------------------------------------------------------
            if (state == ST_RUN) begin
                if (div_cnt < divisor) begin
                    div_cnt <= div_cnt + 8'd1;
                end else begin
                    // Time to transfer one byte
                    div_cnt <= 8'd0;

                    if (dma_mode == 1'b0) begin
                        // RX: sample ui_in into buffer
                        case (word_idx)
                            3'd0: case (byte_lane)
                                2'd0: dbuf[0][ 7: 0] <= ui_in;
                                2'd1: dbuf[0][15: 8] <= ui_in;
                                2'd2: dbuf[0][23:16] <= ui_in;
                                2'd3: dbuf[0][31:24] <= ui_in;
                            endcase
                            3'd1: case (byte_lane)
                                2'd0: dbuf[1][ 7: 0] <= ui_in;
                                2'd1: dbuf[1][15: 8] <= ui_in;
                                2'd2: dbuf[1][23:16] <= ui_in;
                                2'd3: dbuf[1][31:24] <= ui_in;
                            endcase
                            3'd2: case (byte_lane)
                                2'd0: dbuf[2][ 7: 0] <= ui_in;
                                2'd1: dbuf[2][15: 8] <= ui_in;
                                2'd2: dbuf[2][23:16] <= ui_in;
                                2'd3: dbuf[2][31:24] <= ui_in;
                            endcase
                            3'd3: case (byte_lane)
                                2'd0: dbuf[3][ 7: 0] <= ui_in;
                                2'd1: dbuf[3][15: 8] <= ui_in;
                                2'd2: dbuf[3][23:16] <= ui_in;
                                2'd3: dbuf[3][31:24] <= ui_in;
                            endcase
                            3'd4: case (byte_lane)
                                2'd0: dbuf[4][ 7: 0] <= ui_in;
                                2'd1: dbuf[4][15: 8] <= ui_in;
                                2'd2: dbuf[4][23:16] <= ui_in;
                                2'd3: dbuf[4][31:24] <= ui_in;
                            endcase
                            3'd5: case (byte_lane)
                                2'd0: dbuf[5][ 7: 0] <= ui_in;
                                2'd1: dbuf[5][15: 8] <= ui_in;
                                2'd2: dbuf[5][23:16] <= ui_in;
                                2'd3: dbuf[5][31:24] <= ui_in;
                            endcase
                            3'd6: case (byte_lane)
                                2'd0: dbuf[6][ 7: 0] <= ui_in;
                                2'd1: dbuf[6][15: 8] <= ui_in;
                                2'd2: dbuf[6][23:16] <= ui_in;
                                2'd3: dbuf[6][31:24] <= ui_in;
                            endcase
                            3'd7: case (byte_lane)
                                2'd0: dbuf[7][ 7: 0] <= ui_in;
                                2'd1: dbuf[7][15: 8] <= ui_in;
                                2'd2: dbuf[7][23:16] <= ui_in;
                                2'd3: dbuf[7][31:24] <= ui_in;
                            endcase
                        endcase
                    end
                    // TX: data is driven combinatorially from buf; nothing more to latch here.

                    // Advance byte counter
                    if (byte_idx == count - 6'd1) begin
                        // Transfer complete
                        state    <= ST_DONE;
                        dma_done <= 1'b1;
                        irq_reg  <= irq_enable;
                    end else begin
                        byte_idx <= byte_idx + 6'd1;
                    end
                end
            end else if (state == ST_DONE) begin
                // Stay done until CPU clears, then go idle
                if (!dma_done) state <= ST_IDLE;
            end

        end // rst_n
    end // always

    // -----------------------------------------------------------------------
    // TX output: drive uo_out from the current byte of the buffer.
    // In RX mode (or idle/done) drive 0.
    // -----------------------------------------------------------------------
    reg [7:0] tx_byte;
    always @(*) begin
        tx_byte = 8'd0;
        if (state == ST_RUN && dma_mode == 1'b1) begin
            case (word_idx)
                3'd0: case (byte_lane) 2'd0: tx_byte = dbuf[0][ 7: 0];
                                       2'd1: tx_byte = dbuf[0][15: 8];
                                       2'd2: tx_byte = dbuf[0][23:16];
                                       2'd3: tx_byte = dbuf[0][31:24]; endcase
                3'd1: case (byte_lane) 2'd0: tx_byte = dbuf[1][ 7: 0];
                                       2'd1: tx_byte = dbuf[1][15: 8];
                                       2'd2: tx_byte = dbuf[1][23:16];
                                       2'd3: tx_byte = dbuf[1][31:24]; endcase
                3'd2: case (byte_lane) 2'd0: tx_byte = dbuf[2][ 7: 0];
                                       2'd1: tx_byte = dbuf[2][15: 8];
                                       2'd2: tx_byte = dbuf[2][23:16];
                                       2'd3: tx_byte = dbuf[2][31:24]; endcase
                3'd3: case (byte_lane) 2'd0: tx_byte = dbuf[3][ 7: 0];
                                       2'd1: tx_byte = dbuf[3][15: 8];
                                       2'd2: tx_byte = dbuf[3][23:16];
                                       2'd3: tx_byte = dbuf[3][31:24]; endcase
                3'd4: case (byte_lane) 2'd0: tx_byte = dbuf[4][ 7: 0];
                                       2'd1: tx_byte = dbuf[4][15: 8];
                                       2'd2: tx_byte = dbuf[4][23:16];
                                       2'd3: tx_byte = dbuf[4][31:24]; endcase
                3'd5: case (byte_lane) 2'd0: tx_byte = dbuf[5][ 7: 0];
                                       2'd1: tx_byte = dbuf[5][15: 8];
                                       2'd2: tx_byte = dbuf[5][23:16];
                                       2'd3: tx_byte = dbuf[5][31:24]; endcase
                3'd6: case (byte_lane) 2'd0: tx_byte = dbuf[6][ 7: 0];
                                       2'd1: tx_byte = dbuf[6][15: 8];
                                       2'd2: tx_byte = dbuf[6][23:16];
                                       2'd3: tx_byte = dbuf[6][31:24]; endcase
                3'd7: case (byte_lane) 2'd0: tx_byte = dbuf[7][ 7: 0];
                                       2'd1: tx_byte = dbuf[7][15: 8];
                                       2'd2: tx_byte = dbuf[7][23:16];
                                       2'd3: tx_byte = dbuf[7][31:24]; endcase
                default: tx_byte = 8'd0;
            endcase
        end
    end

    assign uo_out = tx_byte;

    // -----------------------------------------------------------------------
    // Register read decoder
    // -----------------------------------------------------------------------
    reg [31:0] rdata;
    always @(*) begin
        case (address)
            6'h00: rdata = {29'd0, irq_enable, dma_mode, 1'b0};
            6'h04: rdata = {26'd0, count};
            6'h08: rdata = {24'd0, divisor};
            6'h0C: rdata = {30'd0, dma_done, (state == ST_RUN)};
            6'h10: rdata = 32'd0;
            6'h14: rdata = dbuf[0];
            6'h18: rdata = dbuf[1];
            6'h1C: rdata = dbuf[2];
            6'h20: rdata = dbuf[3];
            6'h24: rdata = dbuf[4];
            6'h28: rdata = dbuf[5];
            6'h2C: rdata = dbuf[6];
            6'h30: rdata = dbuf[7];
            default: rdata = 32'd0;
        endcase
    end

    assign data_out   = rdata;
    assign data_ready = 1'b1;     // All register accesses complete in 1 clock

    assign user_interrupt = irq_reg;

    // Suppress unused-input warnings
    wire _unused = &{data_read_n, 1'b0};

endmodule
