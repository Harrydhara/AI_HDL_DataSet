/*
 * Copyright (c) 2025 ICLab_HUST
 * SPDX-License-Identifier: Apache-2.0
 *
 *  Register Map (byte-addressed, word-aligned accesses):
 *
 *  0x00  CTRL    [W] bit0 = start (self-clearing; SEC_KEY=0xA5 must be written first)
 *                    bit1 = mode  (0 = RX: ui_in → buffer,
 *                                  1 = TX: buffer → uo_out)
 *                    bit2 = irq_enable
 *                    Note: mode and irq_enable are write-locked while DMA is running.
 *
 *  0x04  COUNT   [RW] Number of bytes to transfer (1-32).
 *                     Write-locked while DMA is running.
 *
 *  0x08  DIVISOR [RW] Output/sample clock divisor.
 *                     One byte is transferred every (DIVISOR+1) clocks.
 *                     Reset default: 63 → ~1 MHz at 64 MHz clock.
 *                     Write-locked while DMA is running.
 *
 *  0x0C  STATUS  [R]  bit0 = busy
 *                     bit1 = done
 *                     bit2 = key_valid  (SEC_KEY has been armed, ready for start)
 *
 *  0x10  CLR_IRQ [W]  Write any value to clear 'done' and deassert interrupt.
 *
 *  0x14  DATA0   [RW] Buffer bytes  3: 0  (write-locked while DMA is running)
 *  0x18  DATA1   [RW] Buffer bytes  7: 4
 *  0x1C  DATA2   [RW] Buffer bytes 11: 8
 *  0x20  DATA3   [RW] Buffer bytes 15:12
 *  0x24  DATA4   [RW] Buffer bytes 19:16
 *  0x28  DATA5   [RW] Buffer bytes 23:20
 *  0x2C  DATA6   [RW] Buffer bytes 27:24
 *  0x30  DATA7   [RW] Buffer bytes 31:28
 *
 *  0x34  SEC_KEY [W]  Write 8'hA5 to arm the start-unlock key.
 *                     The key is consumed (cleared) on every CTRL write,
 *                     whether or not start fires.  CTRL[start] is silently
 *                     ignored unless SEC_KEY was last written with 8'hA5.
 *
 * Operation:
 *   TX mode  – CPU fills DATA[0..N/4], sets COUNT, optionally sets DIVISOR,
 *              writes 8'hA5 to SEC_KEY, then writes 0x3 (start | mode) to CTRL.
 *              The DMA clocks each byte out on uo_out[7:0] at the configured
 *              rate and sets STATUS[done] when the last byte has been sent.
 *
 *   RX mode  – CPU sets COUNT, optionally sets DIVISOR,
 *              writes 8'hA5 to SEC_KEY, then writes 0x1 (start) to CTRL.
 *              The DMA samples ui_in[7:0] at the configured rate, fills
 *              DATA[0..N/4], and sets STATUS[done] when COUNT bytes are captured.
 *              The data buffer is zeroized at start to prevent stale-data leakage.
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
 *
 * Security Countermeasures applied (marked [SEC-n] in code):
 *
 *  [SEC-1] Transfer-active register lock:
 *          CTRL (mode / irq_enable), COUNT, DIVISOR, and all DATA buffer
 *          registers are write-locked while state == ST_RUN (DMA engine active).
 *          Prevents TOCTOU (Time-Of-Check / Time-Of-Use) attacks where software
 *          modifies count or mode mid-transfer, which could cause out-of-bounds
 *          buffer writes or direction confusion.
 *          CWE-362 (Race Condition), CWE-787 (Out-of-bounds Write).
 *          STRIDE: Tampering.  DREAD score: 8/10.
 *          PPA overhead: 1-bit combinatorial gate (cfg_write_ok) gating
 *          each affected write path – negligible area and zero timing impact.
 *
 *  [SEC-2] Start-unlock key (data-input authentication):
 *          A write of 8'hA5 to SEC_KEY (0x34) must precede every
 *          CTRL[start] assertion.  The key is consumed (cleared) on every
 *          CTRL byte-0 write, whether start fires or not, so a pre-armed
 *          key cannot be "stored" across a busy period.
 *          Prevents rogue or replayed writes from launching unintended DMA
 *          transfers without explicit software intent.
 *          CWE-284 (Improper Access Control).
 *          STRIDE: Elevation of Privilege, Tampering.  DREAD score: 7/10.
 *          PPA overhead: 1 flip-flop (sec_key_valid) + 1 comparator
 *          (data_in[7:0] == 8'hA5) + 1 AND gate into start condition.
 *          Estimated +2 cells, < 0.1 % area increase.
 *
 *  [SEC-3] TX output zeroization on completion:
 *          uo_out is explicitly driven to 8'h00 whenever the DMA is not
 *          in ST_RUN TX mode, preventing residual last-byte data from
 *          lingering on the output bus after a transfer finishes.
 *          CWE-226 (Sensitive Information Uncleared Before Storage or Transfer).
 *          CIA: Confidentiality.  DREAD score: 5/10.
 *          PPA overhead: zero – the default-zero assignment already existed
 *          in the original; this countermeasure makes it architecturally
 *          explicit and documents the security intent.
 *
 *  [SEC-4] RX buffer zeroization on transfer start:
 *          The entire dbuf is cleared to 0 when a new RX transfer begins.
 *          Ensures stale data from a prior capture cannot alias into a
 *          partial new result (e.g., if the new COUNT is smaller than the
 *          previous one, the tail words would otherwise retain old bytes).
 *          CWE-212 (Improper Removal of Sensitive Information Before Storage).
 *          CIA: Confidentiality, Integrity.  DREAD score: 6/10.
 *          PPA overhead: 8 × 32-bit synchronous clear paths, active only
 *          for one clock cycle at RX start.  Adds reset fanout to dbuf FFs
 *          but no new logic cone; estimated < 0.5 % area increase.
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

    // [SEC-2] Start-unlock key flag: must be set by writing 8'hA5 to SEC_KEY
    //         before CTRL[start] is accepted.
    reg        sec_key_valid;

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

    // [SEC-1] Write-lock guard: configuration and data registers are frozen
    //         while the DMA engine is actively running (state == ST_RUN).
    //         Prevents TOCTOU attacks from altering count/mode mid-transfer.
    wire cfg_write_ok = (state != ST_RUN);

    integer i;
    always @(posedge clk) begin
        if (!rst_n) begin
            dma_mode      <= 0;
            irq_enable    <= 0;
            count         <= 6'd1;
            divisor       <= 8'd63;
            state         <= ST_IDLE;
            byte_idx      <= 0;
            div_cnt       <= 0;
            irq_reg       <= 0;
            sec_key_valid <= 1'b0;  // [SEC-2] key invalid after reset
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
                            // [SEC-1] mode and irq_enable writes are locked
                            //         while the DMA engine is running.
                            if (cfg_write_ok) begin
                                irq_enable <= data_in[2];
                                dma_mode   <= data_in[1];
                            end
                            // [SEC-2] start requires prior SEC_KEY=0xA5 write.
                            //         The key is consumed here on every CTRL
                            //         byte-0 write (fired or not), preventing
                            //         a pre-armed key from surviving a busy period.
                            if (data_in[0] && state == ST_IDLE && sec_key_valid) begin
                                state    <= ST_RUN;
                                byte_idx <= 6'd0;
                                // [OPT-5] Load divisor into down-counter on start
                                div_cnt  <= divisor;
                                irq_reg  <= 1'b0;
                                // [SEC-4] Zeroize the data buffer before an RX
                                //         transfer to prevent stale data from a
                                //         prior capture aliasing into the new result.
                                //         (TX mode: buffer is pre-filled by CPU, so
                                //          clearing is skipped to preserve TX data.)
                                if (data_in[1] == 1'b0) begin  // RX mode
                                    for (i = 0; i < 8; i = i + 1)
                                        dbuf[i] <= 32'd0;
                                end
                            end
                            sec_key_valid <= 1'b0;  // [SEC-2] consume key unconditionally
                        end
                    end

                    // 0x04 – COUNT  [SEC-1] write-locked during ST_RUN
                    6'h04: begin
                        if (wr_byte0 && cfg_write_ok) begin
                            // Clamp to 1..32
                            if (data_in[5:0] == 6'd0)
                                count <= 6'd1;
                            else if (data_in[5:0] > 6'd32)
                                count <= 6'd32;
                            else
                                count <= data_in[5:0];
                        end
                    end

                    // 0x08 – DIVISOR  [SEC-1] write-locked during ST_RUN
                    6'h08: begin
                        if (wr_byte0 && cfg_write_ok) divisor <= data_in[7:0];
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

                    // 0x34 – SEC_KEY  [SEC-2] arm the start-unlock key.
                    //         Only the value 8'hA5 sets the key; any other
                    //         value clears it, allowing software to explicitly
                    //         revoke a previously armed key.
                    6'h34: begin
                        if (wr_byte0)
                            sec_key_valid <= (data_in[7:0] == 8'hA5);
                    end

                    default: ;
                endcase

                // [OPT-1] Replace 8-case explicit decoder with 3-bit computed index.
                // Guard: word-aligned addresses in the DATA range [0x14..0x30] only.
                // [SEC-1] Additionally gated by cfg_write_ok to prevent mid-transfer
                //         CPU writes from corrupting the TX buffer or racing with
                //         the RX DMA engine writing to the same buffer words.
                if (cfg_write_ok &&
                    address >= 6'h14 && address <= 6'h30 && address[1:0] == 2'b00) begin
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
    // [SEC-3] Explicit zeroization: uo_out is held at 8'h00 in all states
    //         other than ST_RUN TX.  This prevents the last transmitted byte
    //         from remaining visible on the output bus after the transfer
    //         completes (residual data leakage / CWE-226).
    //         The original code already drove 0 in non-TX states; this
    //         countermeasure makes the security intent architecturally explicit.
    // -----------------------------------------------------------------------
    reg [7:0] tx_byte;
    always @(*) begin
        tx_byte = 8'd0;  // [SEC-3] default-zero: safe value in idle / done / RX states
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
            // [SEC-2] STATUS bit2 exposes sec_key_valid so software can confirm the
            //         key is armed before writing CTRL[start].
            6'h0C: rdata = {29'd0, sec_key_valid, (state == ST_DONE), (state == ST_RUN)};
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
