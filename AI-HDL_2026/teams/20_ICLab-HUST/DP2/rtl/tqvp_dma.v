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
 *
 * PPA Optimisations applied (marked [OPT-n] in code):
 *
 *  [OPT-1] DATA buffer write decoder:
 *          Original: 8-case explicit decoder (case 0x14 .. 0x30).
 *          Optimised: 3-bit computed index  wr_word_idx = address[4:2] - 3'd5
 *          which maps 0x14→0 .. 0x30→7 via mod-8 arithmetic.
 *          Saves the 8-input MUX; synthesises to a small subtractor.
 *
 *  [OPT-2] RX buffer byte write:
 *          Original: 8×4 = 32 nested case assignments.
 *          Optimised: single part-select  dbuf[word_idx][byte_lane*8 +: 8] <= ui_in
 *          Synthesis infers the same 4-to-1 byte-lane mux but from a much
 *          smaller description, reducing logic cone depth.
 *
 *  [OPT-3] TX byte read (combinatorial):
 *          Original: 8×4 = 32 nested case assignments.
 *          Optimised: single part-select  tx_byte = dbuf[word_idx][byte_lane*8 +: 8]
 *          Same benefit as [OPT-2]: read MUX inferred cleanly.
 *
 *  [OPT-4] Register read decoder – DATA range:
 *          Original: 8 explicit case entries (0x14 .. 0x30).
 *          Optimised: one default branch with computed index  address[4:2] - 3'd5
 *          Reduces case width from 14 to 6 entries.
 *
 *  [OPT-5] Clock-divider counter:
 *          Original: 8-bit up-counter with magnitude comparator (div_cnt < divisor).
 *          Optimised: 8-bit down-counter with zero-detect (div_cnt != 0).
 *          An 8-bit NOR gate replaces an 8-bit comparator → smaller, faster.
 *          Divisor is loaded into div_cnt at transfer start and on each byte tick.
 *          Timing identical to original: one byte every (divisor+1) clocks.
 *
 *  [OPT-6] Eliminated dma_done register:
 *          Original: separate 1-bit dma_done FF set on completion, cleared by
 *          CLR_IRQ, and used to trigger ST_DONE→ST_IDLE after one extra cycle.
 *          Optimised: state == ST_DONE carries the same information.
 *          CLR_IRQ now writes state = ST_IDLE directly (no extra cycle needed).
 *          Saves 1 flip-flop and removes the post-done state-check logic.
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
    // [OPT-5] Down-counter: zero-detect replaces up-counter magnitude comparator
    reg  [7:0] div_cnt;
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

    // [OPT-1] Computed word index for DATA buffer write.
    // address[4:2] - 5 maps: 0x14→0, 0x18→1, 0x1C→2, 0x20→3,
    //                        0x24→4, 0x28→5, 0x2C→6, 0x30→7  (mod-8 arithmetic).
    wire [2:0] wr_word_idx = address[4:2] - 3'd5;

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
                                // [OPT-5] Load divisor into down-counter on start
                                // (saves reloading on first tick inside the engine)
                                div_cnt  <= divisor;
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
                    // [OPT-6] Eliminated dma_done register.
                    //         state == ST_DONE encodes done status; transition
                    //         to IDLE is done here directly (one cycle faster,
                    //         saves 1 FF and the post-done state-check block).
                    6'h10: begin
                        if (state == ST_DONE) state <= ST_IDLE;
                        irq_reg <= 1'b0;
                    end

                    default: ;
                endcase

                // [OPT-1] Replace 8-case explicit decoder with 3-bit computed index.
                // Guard: word-aligned addresses in the DATA range [0x14..0x30] only.
                if (address >= 6'h14 && address <= 6'h30 && address[1:0] == 2'b00) begin
                    if (wr_byte0)  dbuf[wr_word_idx][ 7: 0] <= data_in[ 7: 0];
                    if (wr_byte1)  dbuf[wr_word_idx][15: 8] <= data_in[15: 8];
                    if (wr_byte23) dbuf[wr_word_idx][31:16] <= data_in[31:16];
                end
            end // write handling

            // ------------------------------------------------------------------
            // DMA engine
            // ------------------------------------------------------------------
            if (state == ST_RUN) begin
                // [OPT-5] Down-counter: decrement until zero, then transfer one byte.
                // Zero-detect (8-input NOR) is cheaper than magnitude comparator.
                if (div_cnt != 8'd0) begin
                    div_cnt <= div_cnt - 8'd1;
                end else begin
                    // Byte-transfer tick: reload counter for the next byte.
                    div_cnt <= divisor;

                    if (dma_mode == 1'b0) begin
                        // RX: sample ui_in into buffer
                        // [OPT-2] Replace 8×4 = 32 nested case assignments with a
                        //         single variable part-select.  Synthesis infers the
                        //         identical 4-to-1 byte-lane MUX from a smaller cone.
                        dbuf[word_idx][byte_lane*8 +: 8] <= ui_in;
                    end
                    // TX: data is driven combinatorially from buf; nothing to latch here.

                    // Advance byte counter or finish
                    if (byte_idx == count - 6'd1) begin
                        // Transfer complete
                        state   <= ST_DONE;
                        // [OPT-6] dma_done removed; ST_DONE encodes done status.
                        irq_reg <= irq_enable;
                    end else begin
                        byte_idx <= byte_idx + 6'd1;
                    end
                end
            end
            // [OPT-6] ST_DONE→ST_IDLE transition moved into CLR_IRQ write handler above.
            // No separate post-done state-check block needed.

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
            // [OPT-3] Replace 8×4 = 32 nested case assignments with a single
            //         variable part-select.  Read MUX is inferred cleanly.
            tx_byte = dbuf[word_idx][byte_lane*8 +: 8];
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
            // [OPT-6] Use state == ST_DONE directly instead of separate dma_done register.
            6'h0C: rdata = {30'd0, (state == ST_DONE), (state == ST_RUN)};
            6'h10: rdata = 32'd0;
            // [OPT-4] Replace 8 explicit DATA case entries with a single default branch.
            //         Computed index: address[4:2] - 5  (mod-8 arithmetic, same as OPT-1).
            //         Guard restricts to word-aligned addresses in [0x14..0x30].
            default: rdata = (address >= 6'h14 && address <= 6'h30 && address[1:0] == 2'b00) ?
                              dbuf[address[4:2] - 3'd5] : 32'd0;
        endcase
    end

    assign data_out   = rdata;
    assign data_ready = 1'b1;     // All register accesses complete in 1 clock

    assign user_interrupt = irq_reg;

    // Suppress unused-input warnings
    wire _unused = &{data_read_n, 1'b0};

endmodule
