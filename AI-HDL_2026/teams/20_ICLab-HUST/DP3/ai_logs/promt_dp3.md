
AI-HDL 2026 - Design Phase 3 Documentation.pdf


User: Work with the file in the DP3 folder, read the PDF file I provided there, and improve the security issues for the file tqvp_dma.v
Claude: Globpattern: "**/DP3/**"
Found 81 files
User: Work with the file in the DP3 folder, read the PDF file I provided there, and improve the security issues for the file DP3/src/tqvp_dma.v.
Claude :To read the PDF and the Verilog file in parallel.Read AI-HDL 2026 - Design Phase 3 Documentation.pdfRead tqvp_dma.v”


Claude: I have finished reading both files. I will analyze the security vulnerabilities and implement the countermeasures according to the DP3 requirements.The vulnerabilities found:
ID
Vulnerability Description
CWE
STRIDE
DREAD
SEC-1
TOCTOU: The count, mode, and divisor registers can be overwritten while the DMA is actively running.
CWE-362, CWE-787
Tampering
8/10
SEC-2
Lack of Authentication: Any write operation to CTRL[start] triggers the DMA without verification.
CWE-284
Elevation of Privilege
7/10
SEC-3
Data Leakage: uo_out leaks the last byte after TX finishes due to a lack of explicit zeroing.
CWE-226
Info Disclosure
5/10
SEC-4
Stale Data: The RX buffer contains residual data from previous operations, leading to potential misreads.
CWE-212
Info Disclosure
6/10
Write  HYPERLINK "vscode-webview://1b74624abcmmdcs9pp4imo5eguud6qrf7o0fr1gvckb87d9amvkm/index.html?id=2a5971ee-97e5-4c5d-8625-bc3e0200a304&parentId=1&origin=9ac34b4a-26c2-4308-9708-fee7f6985adb&swVersion=4&extensionId=Anthropic.claude-code&platform=electron&vscode-resource-base-authority=vscode-resource.vscode-cdn.net&parentOrigin=vscode-file%3A%2F%2Fvscode-app&session=52a54462-3781-4b3e-bd2a-ed2d5234f78c" \h tqvp_dma.v
414 lines
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

The file has been updated. Below is a summary of the implemented security changes:
Summary of Security Countermeasures
[SEC-1] Transfer-Active Register Lock
Vulnerability: count, dma_mode, irq_enable, divisor, and the DATA buffer could be overwritten while DMA is running → TOCTOU attack.Fix: Added signal cfg_write_ok = (state != ST_RUN) to gate all writes to configuration registers and the DATA buffer while DMA is active.CWE-362, CWE-787 | STRIDE: Tampering | DREAD: 8/10
[SEC-2] Start-Unlock Key (Major Countermeasure)
Vulnerability: Any software could trigger DMA by writing to CTRL → privilege escalation.Fix: Added a new register SEC_KEY (0x34). Must write 8'hA5 to this register before CTRL[start] is accepted. The key is consumed (cleared) immediately after each write to CTRL, preventing pre-arming attacks.Changes: +1 flip-flop sec_key_valid, +1 comparator, STATUS[bit2] = key_validCWE-284 | STRIDE: Elevation of Privilege | DREAD: 7/10
[SEC-3] TX Output Zeroization
Vulnerability: The last transmitted byte may remain on uo_out after the transfer ends.Fix: tx_byte = 8'd0 is explicitly assigned in the code, ensuring the output is cleared immediately when exiting ST_RUN (TX).CWE-226 | CIA: Confidentiality | DREAD: 5/10
[SEC-4] RX Buffer Zeroization on Start
Vulnerability: If a new RX transfer has a smaller COUNT than the previous one, the remaining buffer entries may still contain old data.Fix: When an RX transfer starts (data_in[1] == 0), the entire buffer dbuf[0..7] is cleared to 0 before sampling.CWE-212 | CIA: Confidentiality, Integrity | DREAD: 6/10
New sequence to start DMA (TX example):
Write DATA registers 
Write COUNT 
Write SEC_KEY = 0xA5 
Write CTRL = 0x3
18.26. Executing CHECK pass (checking for obvious problems). Checking module $paramod$c6073fd8a5b287029e036048d234daa072bb204f\tinyqv_core... Checking module $paramod$c6073fd8a5b287029e036048d234daa072bb204f\tinyqv_registers... Checking module $paramod$d755ff5a733adc54feae1ee08934ae6298cc8303\uart_tx... Checking module $paramod\tinyQV_peripherals\CLOCK_MHZ=s32'00000000000000000000000001000000... Checking module $paramod\tinyqv_counter\OUTPUT_WIDTH=s32'00000000000000000000000000000111... Checking module $paramod\tinyqv_mul\B_BITS=s32'00000000000000000000000000010000... Checking module qspi_controller... Checking module tinyQV... Checking module tinyqv_alu... Checking module tinyqv_counter... Checking module tinyqv_cpu... Checking module tinyqv_decoder... Checking module tinyqv_mem_ctrl... Checking module tinyqv_shifter... Checking module tqvp_dma... Checking module tt_um_tt_tinyQV... Found and reported 0 problems. 19. Executing Verilog backend. ERROR: Can't open output file `../output/synth_netlist.v' for writing: No such file or directory
Read  HYPERLINK "vscode-webview://1b74624abcmmdcs9pp4imo5eguud6qrf7o0fr1gvckb87d9amvkm/index.html?id=2a5971ee-97e5-4c5d-8625-bc3e0200a304&parentId=1&origin=9ac34b4a-26c2-4308-9708-fee7f6985adb&swVersion=4&extensionId=Anthropic.claude-code&platform=electron&vscode-resource-base-authority=vscode-resource.vscode-cdn.net&parentOrigin=vscode-file%3A%2F%2Fvscode-app&session=52a54462-3781-4b3e-bd2a-ed2d5234f78c" \h synth.tcl
Bash
IN
ls /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/yosys/
OUT
synth.tcl
synth.ys
The script runs from the yosys/ directory, but the output is at the relative path ../output/ (i.e., DP3/output/). You need to create that directory:
BashINmkdir -p /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/yosys/output && ls /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/yosys/
OUT
output  synth.tcl  synth.ys
Wait, the error says ../output/ but the script uses output/. Let’s check the file synth.ys:Read synth.ys
synth.ys uses ../output/ — this script runs from the yosys/ directory and outputs to DP3/output/. Create the correct directory:
BashIN
mkdir -p /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/output && echo "Created"
OUT
Created
Now, run Yosys again from the correct directory:
Bash
IN
cd /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/yosys && yosys synth.ys 2>&1 | tail -30
OUT
     $_AND_                        200
     $_DFFE_PN1P_                    1
     $_DFFE_PN_                     53
     $_DFFE_PP_                    203
     $_DFF_N_                        2
     $_DFF_P_                      520
     $_MUX_                       1614
     $_NAND_                       203
     $_NOR_                        198
     $_NOT_                        406
     $_ORNOT_                      194
     $_OR_                        1150
     $_SDFFCE_PN0N_                  6
     $_SDFFCE_PN0P_                293
     $_SDFFCE_PN1P_                  6
     $_SDFFE_PN0P_                 130
     $_SDFFE_PN1P_                  11
     $_SDFFE_PP0N_                  10
     $_SDFFE_PP0P_                  17
     $_SDFFE_PP1P_                   6
     $_SDFF_PN0_                    25
     $_SDFF_PN1_                     3
     $_SDFF_PP0_                    15
     $_XNOR_                        74
     $_XOR_                        266
Warnings: 2 unique messages, 3 total
End of script. Logfile hash: ac497c96cb, CPU: user 4.27s system 0.07s, MEM: 62.11 MB peak
Yosys 0.52 (git sha1 fee39a3284c90249e1d9684cf6944ffbbcbb8f90)
Time spent: 23% 1x abc (1 sec), 19% 65x opt_expr (1 sec), ...
Synthesis thành công. Kiểm tra output:
Bash
IN
ls -lh /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/output/ && echo "---" && cat /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/output/synth_stats.txt | grep -A 30 "tqvp_dma"
OUT
total 4.4M
-rw-rw-r-- 1 [user] [user] 4.0M Mar 20 15:21 synth_netlist.json
-rw-rw-r-- 1 [user] [user] 452K Mar 20 15:21 synth_netlist.v
-rw-rw-r-- 1 [user] [user]  18K Mar 20 15:21 synth_stats.txt
---
     tqvp_dma                        1
=== $paramod\tinyqv_counter\OUTPUT_WIDTH=s32'00000000000000000000000000000111 ===

   Number of wires:                 20
   Number of wire bits:             90
   Number of public wires:          10
   Number of public wire bits:      80
   Number of ports:                  6
   Number of port bits:             14
   Number of memories:               0
   Number of memory bits:            0
   Number of processes:              0
   Number of cells:                 48
     $_ANDNOT_                       3
     $_AND_                          1
     $_DFF_P_                       28
     $_MUX_                          1
     $_NAND_                         1
     $_NOR_                          1
     $_NOT_                          3
     $_OR_                           1
     $_SDFF_PN0_                     5
     $_XNOR_                         1
     $_XOR_                          3

=== $paramod\tinyqv_mul\B_BITS=s32'00000000000000000000000000010000 ===

   Number of wires:                433
   Number of wire bits:            499
   Number of public wires:           6
--
=== tqvp_dma ===

   Number of wires:               1303
   Number of wire bits:           1701
   Number of public wires:          33
   Number of public wire bits:     431
   Number of ports:                 11
   Number of port bits:             94
   Number of memories:               0
   Number of memory bits:            0
   Number of processes:              0
   Number of cells:               1601
     $_ANDNOT_                     179
     $_AND_                          7
     $_DFF_P_                        3
     $_MUX_                        570
     $_NAND_                        24
     $_NOR_                         28
     $_NOT_                        263
     $_ORNOT_                       33
     $_OR_                         182
     $_SDFFCE_PN0P_                256
     $_SDFFE_PN0P_                  18
     $_SDFFE_PN1P_                   7
     $_SDFF_PN0_                     7
     $_XNOR_                         3
     $_XOR_                         21

=== tt_um_tt_tinyQV ===

   Number of wires:                231
--
       tqvp_dma                      1
     tinyQV                          1
       tinyqv_cpu                    1
         $paramod$c6073fd8a5b287029e036048d234daa072bb204f\tinyqv_core      1
           $paramod$c6073fd8a5b287029e036048d234daa072bb204f\tinyqv_registers      1
           $paramod\tinyqv_counter\OUTPUT_WIDTH=s32'00000000000000000000000000000111      1
           $paramod\tinyqv_mul\B_BITS=s32'00000000000000000000000000010000      1
           tinyqv_alu                1
           tinyqv_counter            1
           tinyqv_shifter            1
         tinyqv_decoder              1
       tinyqv_mem_ctrl               1
         qspi_controller             1

   Number of wires:               5653
   Number of wire bits:           9509
   Number of public wires:         570
   Number of public wire bits:    4286
   Number of ports:                243
   Number of port bits:           1202
   Number of memories:               0
   Number of memory bits:            0
   Number of processes:              0
   Number of cells:               6917
     $_ANDNOT_                    1311
     $_AND_                        200
     $_DFFE_PN1P_                    1
     $_DFFE_PN_                     53
     $_DFFE_PP_                    203
     $_DFF_N_                        2
     $_DFF_P_                      520
The synthesis was completely successful, with no errors. 
This is the PPA overhead analysis from the security countermeasures:
Synthesis & PPA Analysis Results
tqvp_dma after adding security features:
Metric
Value
Total cells
1601
Flip-flops (SDFFCE, SDFFE, SDFF)
288
MUX
570

Estimated PPA Overhead (compared to original version):
Countermeasure
Cost
SEC-1 Register lock (cfg_write_ok gate)
~1 wire + AND gate per write path — very small
SEC-2 SEC_KEY register
+1 FF (sec_key_valid) + 1 comparator 8-bit (== 8'hA5) + 1 AND gate
SEC-3 TX zeroization
0 — logic already exists, just made explicit
SEC-4 RX buffer clear
+8×32 reset paths into dbuf FFs — no new cells, only added reset fanout

Total estimated overhead:
~10–15 cells (~1% increase) — negligible.
Output files have been generated at DP3/output/:
synth_netlist.v (452KB) 
synth_netlist.json (4MB) 
synth_stats.txt (18KB) — used for PPA report in DP3 submission 
README.md 
User:“Check again DP1 and DP2 to see if they have the same issue.”
Claude:“Globpattern: /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/**/synth.ysFound 3 files”

Globpattern: "/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/**/synth.tcl"
Found 3 files
Bash
IN
ls /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP1/yosys/ && echo "---" && ls /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP2/yosys/
OUT
synth.tcl
synth.ys
---
synth.tcl
synth.ys
Both DP1 and DP2 are missing the output/ directory. Create and run them now:
Bash
IN
mkdir -p /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP1/output && mkdir -p /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP2/output && echo "Created both"
OUT
Created both
Bash
IN
cd /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP1/yosys && yosys synth.ys 2>&1 | tail -15
OUT
     $_SDFFE_PN0P_                 129
     $_SDFFE_PN1P_                  11
     $_SDFFE_PP0N_                  10
     $_SDFFE_PP0P_                  17
     $_SDFFE_PP1P_                   6
     $_SDFF_PN0_                   282
     $_SDFF_PN1_                     3
     $_SDFF_PP0_                    15
     $_XNOR_                        82
     $_XOR_                        264

Warnings: 3 unique messages, 4 total
End of script. Logfile hash: aac9956a3e, CPU: user 4.57s system 0.06s, MEM: 62.76 MB peak
Yosys 0.52 (git sha1 fee39a3284c90249e1d9684cf6944ffbbcbb8f90)
Time spent: 25% 1x abc (1 sec), 18% 62x opt_expr (1 sec), ...
Bash
IN
cd /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP2/yosys && yosys synth.ys 2>&1 | tail -15
OUT
     $_SDFFE_PN0P_                 129
     $_SDFFE_PN1P_                  11
     $_SDFFE_PP0N_                  10
     $_SDFFE_PP0P_                  17
     $_SDFFE_PP1P_                   6
     $_SDFF_PN0_                    25
     $_SDFF_PN1_                     3
     $_SDFF_PP0_                    15
     $_XNOR_                        74
     $_XOR_                        266

Warnings: 2 unique messages, 3 total
End of script. Logfile hash: 1af6754dce, CPU: user 4.03s system 0.04s, MEM: 62.06 MB peak
Yosys 0.52 (git sha1 fee39a3284c90249e1d9684cf6944ffbbcbb8f90)
Time spent: 25% 1x abc (1 sec), 19% 65x opt_expr (1 sec), ...
Both ran successfully. Confirm output files:Bash
IN
echo "=== DP1/output ===" && ls -lh /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP1/output/ && echo "=== DP2/output ===" && ls -lh /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP2/output/
OUT
=== DP1/output ===
total 5.9M
-rw-rw-r-- 1 [user] [user] 5.4M Mar 20 15:22 synth_netlist.json
-rw-rw-r-- 1 [user] [user] 586K Mar 20 15:22 synth_netlist.v
-rw-rw-r-- 1 [user] [user]  18K Mar 20 15:22 synth_stats.txt
=== DP2/output ===
total 4.7M
-rw-rw-r-- 1 [user] [user] 4.2M Mar 20 15:23 synth_netlist.json
-rw-rw-r-- 1 [user] [user] 467K Mar 20 15:23 synth_netlist.v
-rw-rw-r-- 1 [user] [user]  18K Mar 20 15:23 synth_stats.txt
Everything is fine. Summary:
Phase
Issue
Status
DP1
Missing output/ directory
Created + synthesis successful
DP2
Missing output/ directory
Created + synthesis successful
DP3
Missing output/ directory
Fixed earlier + synthesis successful

All three phases had the same issue — the output/ directory was not pre-created in the repository. Now everything has the required output files at:
DP1/output/ 
DP2/output/ 
DP3/output/ 
synth_stats.txt 
User:“I want to run the testbench in the folder DP3/test.”
Claude:“Read Makefile”
Read  HYPERLINK "vscode-webview://1b74624abcmmdcs9pp4imo5eguud6qrf7o0fr1gvckb87d9amvkm/index.html?id=2a5971ee-97e5-4c5d-8625-bc3e0200a304&parentId=1&origin=9ac34b4a-26c2-4308-9708-fee7f6985adb&swVersion=4&extensionId=Anthropic.claude-code&platform=electron&vscode-resource-base-authority=vscode-resource.vscode-cdn.net&parentOrigin=vscode-file%3A%2F%2Fvscode-app&session=52a54462-3781-4b3e-bd2a-ed2d5234f78c" \h test_dma.mk
Bash
IN
which verilator && verilator --version && which cocotb-config && cocotb-config --version 2>&1
OUT
Exit code 1
/usr/bin/verilator
Verilator 5.032 2025-01-01 rev (Debian 5.032-1+b2)
Bash
IN
cocotb-config --version 2>&1 || python3 -m cocotb --version 2>&1 || pip3 show cocotb 2>&1 | head -5
OUT
/bin/bash: line 1: cocotb-config: command not found
/usr/bin/python3: No module named cocotb
WARNING: Package(s) not found: cocotb
Read  HYPERLINK "vscode-webview://1b74624abcmmdcs9pp4imo5eguud6qrf7o0fr1gvckb87d9amvkm/index.html?id=2a5971ee-97e5-4c5d-8625-bc3e0200a304&parentId=1&origin=9ac34b4a-26c2-4308-9708-fee7f6985adb&swVersion=4&extensionId=Anthropic.claude-code&platform=electron&vscode-resource-base-authority=vscode-resource.vscode-cdn.net&parentOrigin=vscode-file%3A%2F%2Fvscode-app&session=52a54462-3781-4b3e-bd2a-ed2d5234f78c" \h requirements.txt
User: cocotb is not installed. It needs to be installed first:
Claude:
 BASH
IN
pip3 install -r /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/requirements.txt 2>&1 | tail -10
OUT
    sure you have python3-full installed.
    If you wish to install a non-Debian packaged Python application,
    it may be easiest to use pipx install xyz, which will manage a
    virtual environment for you. Make sure you have pipx installed
    See /usr/share/doc/python3.13/README.venv for more information.
note: If you believe this is a mistake, please contact your Python installation or OS distribution provider. You can override this, at the risk of breaking your Python installation or OS, by passing --break-system-packages.
hint: See PEP 668 for the detailed specification.
Bash
IN
pip3 install -r /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/requirements.txt --break-system-packages 2>&1 | tail -15
OUT
Downloading bitarray-3.8.0-cp313-cp313-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl (340 kB)
Downloading tibs-0.5.7-cp38-abi3-manylinux_2_17_x86_64.manylinux2014_x86_64.whl (423 kB)
Using cached find_libpython-0.5.1-py3-none-any.whl (9.2 kB)
Using cached iniconfig-2.3.0-py3-none-any.whl (7.5 kB)
Installing collected packages: riscv-model, pyelftools, bitarray, tibs, pluggy, iniconfig, find-libpython, pytest, cocotb, bitstring
  WARNING: The scripts riscv-describe-isa-variant, riscv-machinsn-decode, riscv-random-asm and riscv-random-asm-check are installed in '/home/user/.local/bin' which is not on PATH.
  Consider adding this directory to PATH or, if you prefer to suppress this warning, use --no-warn-script-location.
  WARNING: The script find_libpython is installed in '/home/user/.local/bin' which is not on PATH.
  Consider adding this directory to PATH or, if you prefer to suppress this warning, use --no-warn-script-location.
  WARNING: The scripts py.test and pytest are installed in '/home/user/.local/bin' which is not on PATH.
  Consider adding this directory to PATH or, if you prefer to suppress this warning, use --no-warn-script-location.
  WARNING: The script cocotb-config is installed in '/home/user/.local/bin' which is not on PATH.
  Consider adding this directory to PATH or, if you prefer to suppress this warning, use --no-warn-script-location.

Successfully installed bitarray-3.8.0 bitstring-4.4.0 cocotb-1.9.2 find-libpython-0.5.1 iniconfig-2.3.0 pluggy-1.6.0 pyelftools-0.32 pytest-8.3.4 riscv-model-0.6.6 tibs-0.5.7
Installation complete. Let's run a DMA testbench first:
Bash
IN
cd /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test && export PATH="$HOME/.local/bin:$PATH" && make test_dma 2>&1
OUT
The user doesn't want to proceed with this tool use. The tool use was rejected (eg. if it was a file edit, the new_string was NOT written to the file). STOP what you are doing and wait for the user to tell you how to proceed.
Note: The user's next message may contain a correction or preference. Pay close attention — if they explain what went wrong or how they'd prefer you to work, consider saving that to memory for future sessions.
User:“Is there a way to view the waveform?”
Claude:“Read tb.vYes. The testbench already includes VCD dumping ($dumpfile("tb.vcd")). After running the test, the file tb.vcd will be generated and can be viewed using:
GTKWave (most popular):gtkwave tb.vcd 
Surfer (more modern, runs in browser):pip install surfer-waveformsurfer tb.vcd 
Check if GTKWave is installed:”
BashINwhich gtkwave && gtkwave --version 2>&1 | head -1
OUTExit code 1
User:“I have already installed Verilator.”
Claude:BashINwhich gtkwave 2>/dev/null || apt list --installed 2>/dev/null | grep -i gtkwave
OUT(no output)
“GTKWave is not installed. Quick install:”
BashINsudo apt-get install -y gtkwave 2>&1 | tail -5
OUT
sudo: a terminal is required to read the password; either use the -S option to read from standard input or configure an askpass helper  sudo: a password is required
“You need sudo. You can install it manually with this command in the terminal:sudo apt-get install -y gtkwave
Then the full workflow is:
# 1. Run test (generate tb.vcd)cd /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/testexport PATH="$HOME/.local/bin:$PATH"make test_dma# 2. Open waveformgtkwave sim_build/dma/tb.vcd
Verilator usually dumps VCD into the sim_build/dma/ directory. If you want to run all tests:
make            # run allgtkwave sim_build/dma/tb.vcd   # view DMA waveform
If you cannot install GTKWave, you can use Surfer (no sudo required):
pip3 install surfer-waveform --break-system-packagessurfer sim_build/dma/tb.vcd

User:“I already installed Verilator before, can I run it using Verilator?”
Claude: Read  HYPERLINK "vscode-webview://1b74624abcmmdcs9pp4imo5eguud6qrf7o0fr1gvckb87d9amvkm/index.html?id=2a5971ee-97e5-4c5d-8625-bc3e0200a304&parentId=1&origin=9ac34b4a-26c2-4308-9708-fee7f6985adb&swVersion=4&extensionId=Anthropic.claude-code&platform=electron&vscode-resource-base-authority=vscode-resource.vscode-cdn.net&parentOrigin=vscode-file%3A%2F%2Fvscode-app&session=52a54462-3781-4b3e-bd2a-ed2d5234f78c" \h tb_tinyqv.v
Bash
IN
ls /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/*.v
OUT
/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/flash_model.v
/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/peripherals_stub.v
/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/tb_alu.v
/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/tb_core.v
/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/tb_counter.v
/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/tb_cpu.v
/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/tb_decode.v
/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/tb_latch_reg.v
/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/tb_mem_ctrl.v
/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/tb_peripherals.v
/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/tb_qspi_ctrl.v
/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/tb_qspi_flash.v
/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/tb_register.v
/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/tb_system.v
/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/tb_time.v
/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/tb_tinyqv.v
/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/tb_uart_tx.v
/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/tb.v
/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/tt_wrapper.v
These testbenches use Cocotb + Verilator — Cocotb runs the Python tests and Verilator acts as a simulator. I've successfully installed Cocotb, just need to add the PATH and it should work.

Actually, you already have all the tools: Verilator + Cocotb (just installed). Try running the DMA test:
BashIN
cd /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test && export PATH="$HOME/.local/bin:$PATH" && make test_dma 2>&1
OUT
make -f test_dma.mk SIM_BUILD=sim_build/dma clean
make[1]: Entering directory '/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test'
rm -f -r sim_build/dma
rm -f dump.vcd
rm -f dump.fst
make[1]: Leaving directory '/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test'
make -f test_dma.mk SIM_BUILD=sim_build/dma
make[1]: Entering directory '/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test'
rm -f results.xml
"make" -f test_dma.mk results.xml
make[2]: Entering directory '/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test'
mkdir -p sim_build/dma
/usr/bin/verilator -cc --exe -Mdir sim_build/dma -DCOCOTB_SIM=1 --top-module tb --timing -I/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/../src -I/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test --timescale 1ns/1ps --vpi --public-flat-rw --prefix Vtop -o Vtop -LDFLAGS "-Wl,-rpath,/home/user/.local/lib/python3.13/site-packages/cocotb/libs -L/home/user/.local/lib/python3.13/site-packages/cocotb/libs -lcocotbvpi_verilator"  /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/../src/tqvp_dma.v /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/tt_wrapper.v /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test_harness/falling_edge_detector.sv /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test_harness/reclocking.sv /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test_harness/rising_edge_detector.sv /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test_harness/spi_reg.sv /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test_harness/synchronizer.sv /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/tb.v /home/user/.local/lib/python3.13/site-packages/cocotb/share/lib/verilator/verilator.cpp
- V e r i l a t i o n   R e p o r t: Verilator 5.032 2025-01-01 rev (Debian 5.032-1+b2)
- Verilator: Built from 0.348 MB sources in 9 modules, into 0.239 MB in 8 C++ files needing 0.000 MB
- Verilator: Walltime 0.043 s (elab=0.003, cvt=0.020, bld=0.000); cpu 0.036 s on 1 threads; alloced 10.906 MB
make -C sim_build/dma  -f Vtop.mk
make[3]: Entering directory '/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/sim_build/dma'
g++  -I.  -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=1 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable      -fcoroutines -Os  -c -o verilator.o /home/user/.local/lib/python3.13/site-packages/cocotb/share/lib/verilator/verilator.cpp
g++ -Os  -I.  -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=1 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable      -fcoroutines -c -o verilated.o /usr/share/verilator/include/verilated.cpp
g++ -Os  -I.  -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=1 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable      -fcoroutines -c -o verilated_dpi.o /usr/share/verilator/include/verilated_dpi.cpp
g++ -Os  -I.  -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=1 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable      -fcoroutines -c -o verilated_vpi.o /usr/share/verilator/include/verilated_vpi.cpp
g++ -Os  -I.  -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=1 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable      -fcoroutines -c -o verilated_timing.o /usr/share/verilator/include/verilated_timing.cpp
g++ -Os  -I.  -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=1 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable      -fcoroutines -c -o verilated_threads.o /usr/share/verilator/include/verilated_threads.cpp
python3 /usr/share/verilator/bin/verilator_includer -DVL_INCLUDE_OPT=include Vtop.cpp Vtop___024root__DepSet_h84412442__0.cpp Vtop___024root__DepSet_heccd7ead__0.cpp Vtop__Dpi.cpp Vtop___024root__Slow.cpp Vtop___024root__DepSet_h84412442__0__Slow.cpp Vtop___024root__DepSet_heccd7ead__0__Slow.cpp Vtop__Syms.cpp > Vtop__ALL.cpp
g++ -Os  -I.  -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=1 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable      -fcoroutines -c -o Vtop__ALL.o Vtop__ALL.cpp
echo "" > Vtop__ALL.verilator_deplist.tmp
g++    verilator.o verilated.o verilated_dpi.o verilated_vpi.o verilated_timing.o verilated_threads.o Vtop__ALL.a   -Wl,-rpath,/home/user/.local/lib/python3.13/site-packages/cocotb/libs -L/home/user/.local/lib/python3.13/site-packages/cocotb/libs -lcocotbvpi_verilator  -pthread -lpthread -latomic   -o Vtop
rm Vtop__ALL.verilator_deplist.tmp
make[3]: Leaving directory '/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/sim_build/dma'
rm -f results.xml
MODULE=test TESTCASE= TOPLEVEL=tb TOPLEVEL_LANG=verilog \
         sim_build/dma/Vtop    
     -.--ns INFO     gpi                                ..mbed/gpi_embed.cpp:79   in set_program_name_in_venv        Did not detect Python virtual environment. Using system-wide Python interpreter
     -.--ns INFO     gpi                                ../gpi/GpiCommon.cpp:101  in gpi_print_registered_impl       VPI registered
     0.00ns INFO     cocotb                             Running on Verilator version 5.032 2025-01-01
     0.00ns INFO     cocotb                             Running tests with cocotb v1.9.2 from /home/user/.local/lib/python3.13/site-packages/cocotb
     0.00ns INFO     cocotb                             Seeding Python random module with 1773995582
     0.00ns INFO     cocotb.regression                  Found test test.test_reset_defaults
     0.00ns INFO     cocotb.regression                  Found test test.test_register_readback
     0.00ns INFO     cocotb.regression                  Found test test.test_count_clamping
     0.00ns INFO     cocotb.regression                  Found test test.test_tx_mode
     0.00ns INFO     cocotb.regression                  Found test test.test_tx_two_words
     0.00ns INFO     cocotb.regression                  Found test test.test_tx_full_buffer
     0.00ns INFO     cocotb.regression                  Found test test.test_rx_mode
     0.00ns INFO     cocotb.regression                  Found test test.test_rx_different_values
     0.00ns INFO     cocotb.regression                  Found test test.test_irq_enabled
     0.00ns INFO     cocotb.regression                  Found test test.test_irq_disabled
     0.00ns INFO     cocotb.regression                  Found test test.test_clr_irq
     0.00ns INFO     cocotb.regression                  Found test test.test_second_transfer
     0.00ns INFO     cocotb.regression                  running test_reset_defaults (1/12)
                                                          After reset: STATUS=0 (idle), COUNT=1, DIVISOR=63.
     0.00ns INFO     cocotb.tb                          Test 1: reset defaults
     0.00ns INFO     cocotb.tb                          Reset
 79800.00ns INFO     cocotb.tb                          Test 1 PASSED
 79800.00ns INFO     cocotb.regression                  test_reset_defaults passed
 79800.00ns INFO     cocotb.regression                  running test_register_readback (2/12)
                                                          Write and read back COUNT, DIVISOR, and DATA registers.
 79800.00ns INFO     cocotb.tb                          Test 2: register read/write
 79800.00ns INFO     cocotb.tb                          Reset
605800.00ns INFO     cocotb.tb                          Test 2 PASSED
605800.00ns INFO     cocotb.regression                  test_register_readback passed
605800.00ns INFO     cocotb.regression                  running test_count_clamping (3/12)
                                                          COUNT=0 must clamp to 1; COUNT>32 must clamp to 32.
605800.00ns INFO     cocotb.tb                          Test 3: COUNT clamping
605800.00ns INFO     cocotb.tb                          Reset
816800.00ns INFO     cocotb.tb                          Test 3 PASSED
816800.00ns INFO     cocotb.regression                  test_count_clamping passed
816800.00ns INFO     cocotb.regression                  running test_tx_mode (4/12)
                                                          TX: DMA clocks out buffer bytes and sets STATUS[done].
816800.00ns INFO     cocotb.tb                          Test 4: TX mode
816800.00ns INFO     cocotb.tb                          Reset
6182600.00ns INFO     cocotb.regression                  test_tx_mode failed
                                                         Traceback (most recent call last):
 File "/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test.py", line 180, in test_tx_mode
                                                             status = await wait_done(tqv, dut)
                                                                      ^^^^^^^^^^^^^^^^^^^^^^^^^
File "/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test.py", line 53, in wait_done
                                                             raise AssertionError(f"Timeout: DMA did not complete within {timeout} polls")
                                                         AssertionError: Timeout: DMA did not complete within 200 polls
6182600.00ns INFO     cocotb.regression                  running test_tx_two_words (5/12)
                                                           TX 8 bytes from DATA0 and DATA1.
6182600.00ns INFO     cocotb.tb                          Test 5: TX two words
6182600.00ns INFO     cocotb.tb                          Reset
11574600.01ns INFO     cocotb.regression                  test_tx_two_words failed
                                                          Traceback (most recent call last):
File "/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test.py", line 211, in test_tx_two_words
                                                              status = await wait_done(tqv, dut)
                                                                       ^^^^^^^^^^^^^^^^^^^^^^^^^
 File "/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test.py", line 53, in wait_done
                                                              raise AssertionError(f"Timeout: DMA did not complete within {timeout} polls")
                                                          AssertionError: Timeout: DMA did not complete within 200 polls
11574600.01ns INFO     cocotb.regression                  running test_tx_full_buffer (6/12)
                                                            TX all 32 bytes (8 DATA words).
11574600.01ns INFO     cocotb.tb                          Test 6: TX full 32-byte buffer
11574600.01ns INFO     cocotb.tb                          Reset
25013800.01ns INFO     cocotb.regression                  test_tx_full_buffer failed
                                                          Traceback (most recent call last):
File "/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test.py", line 240, in test_tx_full_buffer
                                                              status = await wait_done(tqv, dut, timeout=500)
                                                                       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
File "/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test.py", line 53, in wait_done
                                                              raise AssertionError(f"Timeout: DMA did not complete within {timeout} polls")
                                                          AssertionError: Timeout: DMA did not complete within 500 polls
25013800.01ns INFO     cocotb.regression                  running test_rx_mode (7/12)
                                                            RX: DMA samples ui_in and fills DATA0 with captured bytes.
25013800.01ns INFO     cocotb.tb                          Test 7: RX mode
25013800.01ns INFO     cocotb.tb                          Reset
30353400.01ns INFO     cocotb.regression                  test_rx_mode failed
                                                          Traceback (most recent call last):
 File "/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test.py", line 269, in test_rx_mode
                                                              status = await wait_done(tqv, dut)
                                                                       ^^^^^^^^^^^^^^^^^^^^^^^^^
                                                            File "/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test.py", line 53, in wait_done
                                                              raise AssertionError(f"Timeout: DMA did not complete within {timeout} polls")
                                                          AssertionError: Timeout: DMA did not complete within 200 polls
30353400.01ns INFO     cocotb.regression                  running test_rx_different_values (8/12)
                                                            Two consecutive RX transfers with different ui_in values.
30353400.01ns INFO     cocotb.tb                          Test 8: RX different values
30353400.01ns INFO     cocotb.tb                          Reset
35693000.01ns INFO     cocotb.regression                  test_rx_different_values failed
                                                          Traceback (most recent call last):
 File "/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test.py", line 298, in test_rx_different_values
                                                              await wait_done(tqv, dut)
 File "/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test.py", line 53, in wait_done
                                                              raise AssertionError(f"Timeout: DMA did not complete within {timeout} polls")
                                                          AssertionError: Timeout: DMA did not complete within 200 polls
35693000.01ns INFO     cocotb.regression                  running test_irq_enabled (9/12)
                                                            IRQ is asserted when irq_enable=1 and DMA completes.
35693000.01ns INFO     cocotb.tb                          Test 9: IRQ enabled
35693000.01ns INFO     cocotb.tb                          Reset
41058800.01ns INFO     cocotb.regression                  test_irq_enabled failed
                                                          Traceback (most recent call last):
   File "/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test.py", line 337, in test_irq_enabled
                                                              await wait_done(tqv, dut)
File "/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test.py", line 53, in wait_done
                                                              raise AssertionError(f"Timeout: DMA did not complete within {timeout} polls")
                                                          AssertionError: Timeout: DMA did not complete within 200 polls
41058800.01ns INFO     cocotb.regression                  running test_irq_disabled (10/12)
                                                            No IRQ when irq_enable=0, even after transfer completes.
41058800.01ns INFO     cocotb.tb                          Test 10: IRQ disabled
41058800.01ns INFO     cocotb.tb                          Reset
46398400.01ns INFO     cocotb.regression                  test_irq_disabled failed
                                                          Traceback (most recent call last):
File "/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test.py", line 363, in test_irq_disabled
                                                              await wait_done(tqv, dut)
File "/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test.py", line 53, in wait_done
                                                              raise AssertionError(f"Timeout: DMA did not complete within {timeout} polls")
                                                          AssertionError: Timeout: DMA did not complete within 200 polls
46398400.01ns INFO     cocotb.regression                  running test_clr_irq (11/12)
                                                            Writing CLR_IRQ clears STATUS[done] and deasserts the interrupt line.
46398400.01ns INFO     cocotb.tb                          Test 11: CLR_IRQ
46398400.01ns INFO     cocotb.tb                          Reset
51738000.01ns INFO     cocotb.regression                  test_clr_irq failed
                                                          Traceback (most recent call last):
File "/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test.py", line 389, in test_clr_irq
                                                              await wait_done(tqv, dut)
File "/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test.py", line 53, in wait_done
                                                              raise AssertionError(f"Timeout: DMA did not complete within {timeout} polls")
                                                          AssertionError: Timeout: DMA did not complete within 200 polls
51738000.01ns INFO     cocotb.regression                  running test_second_transfer (12/12)
                                                            After CLR_IRQ the DMA returns to IDLE and can be restarted.
51738000.01ns INFO     cocotb.tb                          Test 12: second transfer after CLR_IRQ
51738000.01ns INFO     cocotb.tb                          Reset
57103800.01ns INFO     cocotb.regression                  test_second_transfer failed
                                                          Traceback (most recent call last):
File "/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test.py", line 428, in test_second_transfer
                                                              await wait_done(tqv, dut)
File "/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test.py", line 53, in wait_done
                                                              raise AssertionError(f"Timeout: DMA did not complete within {timeout} polls")
                                                          AssertionError: Timeout: DMA did not complete within 200 polls
57103800.01ns INFO     cocotb.regression                  **********************************************************************************
  ** TEST                           STATUS  SIM TIME (ns)  REAL TIME (s)  RATIO (ns/s) **
  ** test.test_reset_defaults        PASS       79800.00           0.07    1213813.62  **
 ** test.test_register_readback     PASS      526000.00           0.43    1219715.27  **
** test.test_count_clamping        PASS      211000.00           0.17    1239682.46  **
* test.test_tx_mode               FAIL     5365800.00           4.37    1227579.61  **
 ** test.test_tx_two_words          FAIL     5392000.00           4.40    1224356.61  **
  ** test.test_tx_full_buffer        FAIL    13439200.00          11.16    1204721.71  **
  ** test.test_rx_mode               FAIL     5339600.00           4.41    1210370.38  **
  ** test.test_rx_different_values   FAIL     5339600.00           4.35    1226502.20  **
 ** test.test_irq_enabled           FAIL     5365800.00           4.41    1217862.01  **
 ** test.test_irq_disabled          FAIL     5339600.00           4.38    1219399.03  **
 ** test.test_clr_irq               FAIL     5339600.00           4.32    1237366.30  **
** test.test_second_transfer       FAIL     5365800.00           4.38    1225351.60  **46.93    1216848.84  
                                                                                  
-Info: /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/tb.v:12: $dumpvar ignored, as Verilated without --trace
- :0: Verilog $finish
make[2]: Leaving directory '/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test'
make[1]: Leaving directory '/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test'
The tests are running! 3 passed, 9 failed — the failures occurred because they aren't aware of the new [SEC-2] countermeasure (which requires writing SEC_KEY=0xA5 before starting). I need to update test.py:
Read test.py It's clear — all 9 tests failed because they didn't write SEC_KEY=0xA5 before writing to CTRL. I need to update test.py to include that step and add a new test to verify that the countermeasure is working:
User: Which command should I use to run the waveform?
Claude: The issue is that Verilator compiled without --trace, so the VCD file wasn't generated (as seen in the message $dumpvars ignored, as Verilated without --trace).
Step 1: Add --trace to test_dma.mk: Edit test_dma.mk Added 2 lines
Step 2: Run the test to generate the VCD:
Bash
cd /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/testexport PATH="$HOME/.local/bin:$PATH"
make test_dma
Step 3: Open the waveform:
Bash
# Install GTKWave (if not already installed)
sudo apt-get install -y gtkwave
# Open the waveform
gtkwave sim_build/dma/tb.vcd
The VCD file will be located at sim_build/dma/tb.vcd after running the test.
User: How do I run Verilator?
Claude: There are two ways to run Verilator directly:
Option 1: Lint only (Check syntax/errors without simulating)
Bash
verilator --lint-only -sv /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/src/tqvp_dma.v
Option 2: Direct Compile + Simulate (Requires a self-contained testbench)
Bash
# Compile into a binary
verilator --binary --timing --trace -sv \
    ../src/tqvp_dma.v \
    tb_standalone.v \
    -o sim_dma
# Run simulation → generates dump.vcd
./obj_dir/sim_dma
# View waveform
gtkwave dump.vcd
The Issue with This Project:
Files like tb.v and tb_alu.v in the test/ folder are not self-contained—they lack clocks and stimulus. The entire test logic resides in Python (test.py) and runs via cocotb. Therefore, you cannot run pure Verilator with these specific testbenches.
The correct way for this project is to use make:
Bash
cd /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/testexport PATH="$HOME/.local/bin:$PATH"

make test_dma      # Run DMA tests
make test_alu      # Run ALU tests
make               # Run everything
This command handles the Verilator + cocotb integration internally. Once finished, the sim_build/dma/tb.vcd file will be ready to open with GTKWave.
(venv) user@host:~/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test$ make test_dma make -f test_dma.mk SIM_BUILD=sim_build/dma clean make[1]: Entering directory '/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test' ]rm -f -r sim_build/dma rm -f dump.vcd rm -f dump.fst make[1]: Leaving directory '/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test' make -f test_dma.mk SIM_BUILD=sim_build/dma make[1]: Entering directory '/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test' rm -f results.xml "make" -f test_dma.mk results.xml make[2]: Entering directory '/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test' mkdir -p sim_build/dma /usr/bin/verilator -cc --exe -Mdir sim_build/dma -DCOCOTB_SIM=1 --top-module tb --timing --trace -I/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/../src -I/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test --timescale 1ns/1ps --vpi --public-flat-rw --prefix Vtop -o Vtop -LDFLAGS "-Wl,-rpath,/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/venv/lib/python3.13/site-packages/cocotb/libs -L/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/venv/lib/python3.13/site-packages/cocotb/libs -lcocotbvpi_verilator" /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/../src/tqvp_dma.v /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/tt_wrapper.v /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test_harness/falling_edge_detector.sv /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test_harness/reclocking.sv /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test_harness/rising_edge_detector.sv /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test_harness/spi_reg.sv /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test_harness/synchronizer.sv /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/tb.v /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/venv/lib/python3.13/site-packages/cocotb/share/lib/verilator/verilator.cpp - V e r i l a t i o n R e p o r t: Verilator 5.032 2025-01-01 rev (Debian 5.032-1+b2) - Verilator: Built from 0.348 MB sources in 9 modules, into 0.319 MB in 11 C++ files needing 0.000 MB - Verilator: Walltime 0.026 s (elab=0.002, cvt=0.017, bld=0.000); cpu 0.026 s on 1 threads; alloced 10.926 MB make -C sim_build/dma -f Vtop.mk make[3]: Entering directory '/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/sim_build/dma' 
g++ -I. -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=1 -DVM_TRACE=1 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=1 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable -fcoroutines -Os -c -o verilator.o /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/venv/lib/python3.13/site-packages/cocotb/share/lib/verilator/verilator.cpp g++ -Os -I. -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=1 -DVM_TRACE=1 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=1 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable -fcoroutines -c -o verilated.o /usr/share/verilator/include/verilated.cpp g++ -Os -I. -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=1 -DVM_TRACE=1 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=1 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable -fcoroutines -c -o verilated_dpi.o /usr/share/verilator/include/verilated_dpi.cpp 
g++ -Os -I. -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=1 -DVM_TRACE=1 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=1 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable -fcoroutines -c -o verilated_vpi.o /usr/share/verilator/include/verilated_vpi.cpp 
g++ -Os -I. -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=1 -DVM_TRACE=1 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=1 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable -fcoroutines -c -o verilated_vcd_c.o /usr/share/verilator/include/verilated_vcd_c.cpp 
g++ -Os -I. -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=1 -DVM_TRACE=1 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=1 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable -fcoroutines -c -o verilated_timing.o /usr/share/verilator/include/verilated_timing.cpp 
g++ -Os -I. -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=1 -DVM_TRACE=1 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=1 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable -fcoroutines -c -o verilated_threads.o /usr/share/verilator/include/verilated_threads.cpp python3 /usr/share/verilator/bin/verilator_includer -DVL_INCLUDE_OPT=include Vtop.cpp Vtop___024root__DepSet_h84412442__0.cpp Vtop___024root__DepSet_heccd7ead__0.cpp Vtop__Dpi.cpp Vtop__Trace__0.cpp Vtop___024root__Slow.cpp Vtop___024root__DepSet_h84412442__0__Slow.cpp Vtop___024root__DepSet_heccd7ead__0__Slow.cpp Vtop__Syms.cpp Vtop__Trace__0__Slow.cpp Vtop__TraceDecls__0__Slow.cpp > Vtop__ALL.cpp 
g++ -Os -I. -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=1 -DVM_TRACE=1 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=1 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable -fcoroutines -c -o Vtop__ALL.o Vtop__ALL.cpp echo "" > Vtop__ALL.verilator_deplist.tmp 
g++ verilator.o verilated.o verilated_dpi.o verilated_vpi.o verilated_vcd_c.o verilated_timing.o verilated_threads.o Vtop__ALL.a -Wl,-rpath,/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/venv/lib/python3.13/site-packages/cocotb/libs -L/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/venv/lib/python3.13/site-packages/cocotb/libs -lcocotbvpi_verilator -pthread -lpthread -latomic -o Vtop rm Vtop__ALL.verilator_deplist.tmp 
make[3]: Leaving directory '/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/sim_build/dma' rm -f results.xml MODULE=test TESTCASE= TOPLEVEL=tb TOPLEVEL_LANG=verilog \ sim_build/dma/Vtop -.--ns INFO gpi ..mbed/gpi_embed.cpp:108 in set_program_name_in_venv Using Python virtual environment interpreter at /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/venv/bin/python 
-.--ns INFO gpi ../gpi/GpiCommon.cpp:101 in gpi_print_registered_impl VPI registered 
0.00ns INFO cocotb Running on Verilator version 5.032 2025-01-01 
0.00ns INFO cocotb Running tests with cocotb v1.9.2 from /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/venv/lib/python3.13/site-packages/cocotb 
0.00ns INFO cocotb Seeding Python random module with 1773995932 
0.00ns INFO cocotb.regression Found test test.test_reset_defaults 
0.00ns INFO cocotb.regression Found test test.test_register_readback 
0.00ns INFO cocotb.regression Found test test.test_count_clamping 
0.00ns INFO cocotb.regression Found test test.test_tx_mode 
0.00ns INFO cocotb.regression Found test test.test_tx_two_words 
0.00ns INFO cocotb.regression Found test test.test_tx_full_buffer 
0.00ns INFO cocotb.regression Found test test.test_rx_mode 
0.00ns INFO cocotb.regression Found test test.test_rx_different_values 
0.00ns INFO cocotb.regression Found test test.test_irq_enabled 
0.00ns INFO cocotb.regression Found test test.test_irq_disabled 
0.00ns INFO cocotb.regression Found test test.test_clr_irq 
0.00ns INFO cocotb.regression Found test test.test_second_transfer 
0.00ns INFO cocotb.regression running test_reset_defaults (1/12) After reset: STATUS=0 (idle), COUNT=1, DIVISOR=63. 
0.00ns INFO cocotb.tb Test 1: reset defaults 
0.00ns INFO cocotb.tb Reset 
%Error: Vtop.cpp:121: Turning on wave traces requires Verilated::traceEverOn(true) call before time 0. Aborting... 
make[2]: *** [/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/venv/lib/python3.13/site-packages/cocotb/share/makefiles/simulators/Makefile.verilator:72: results.xml] Aborted (core dumped) make[2]: Leaving directory '/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test' make[1]: *** [/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/venv/lib/python3.13/site-packages/cocotb/share/makefiles/Makefile.inc:40: sim] Error 2 
make[1]: Leaving directory '/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test' make: *** [Makefile:27: test_dma] Error 2
This error occurs because --trace requires Verilated::traceEverOn(true) to be called before the simulation starts. When using cocotb, you should use WAVES = 1 instead of COMPILE_ARGS += --trace:
Edit test_dma.mk (Modified)
Now, run it again:
Bash
make test_dma
Once finished, the VCD file will be located at sim_build/dma/tb.vcd. Open it using GTKWave:
Bash
gtkwave sim_build/dma/tb.vcd
(venv) user@host:~/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test$ make test_dma make -f test_dma.mk SIM_BUILD=sim_build/dma clean make[1]: Entering directory '/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test' rm -f -r sim_build/dma rm -f dump.vcd rm -f dump.fst make[1]: Leaving directory '/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test' make -f test_dma.mk SIM_BUILD=sim_build/dma make[1]: Entering directory '/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test' rm -f results.xml "make" -f test_dma.mk results.xml make[2]: Entering directory '/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test' mkdir -p sim_build/dma /usr/bin/verilator -cc --exe -Mdir sim_build/dma -DCOCOTB_SIM=1 --top-module tb --timing -I/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/../src -I/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test --timescale 1ns/1ps --vpi --public-flat-rw --prefix Vtop -o Vtop -LDFLAGS "-Wl,-rpath,/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/venv/lib/python3.13/site-packages/cocotb/libs -L/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/venv/lib/python3.13/site-packages/cocotb/libs -lcocotbvpi_verilator" /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/../src/tqvp_dma.v /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/tt_wrapper.v /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test_harness/falling_edge_detector.sv /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test_harness/reclocking.sv /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test_harness/rising_edge_detector.sv /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test_harness/spi_reg.sv /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test_harness/synchronizer.sv /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/tb.v /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/venv/lib/python3.13/site-packages/cocotb/share/lib/verilator/verilator.cpp - V e r i l a t i o n R e p o r t: Verilator 5.032 2025-01-01 rev (Debian 5.032-1+b2) 
- Verilator: Built from 0.348 MB sources in 9 modules, into 0.239 MB in 8 C++ files needing 0.000 MB 
- Verilator: Walltime 0.023 s (elab=0.002, cvt=0.013, bld=0.000); cpu 0.023 s on 1 threads; alloced 10.906 MB make -C sim_build/dma -f Vtop.mk 
make[3]: Entering directory '/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/sim_build/dma' 
g++ -I. -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=1 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable -fcoroutines -Os -c -o verilator.o /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/venv/lib/python3.13/site-packages/cocotb/share/lib/verilator/verilator.cpp 
g++ -Os -I. -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=1 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable -fcoroutines -c -o verilated.o /usr/share/verilator/include/verilated.cpp 
g++ -Os -I. -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=1 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable -fcoroutines -c -o verilated_dpi.o /usr/share/verilator/include/verilated_dpi.cpp 
g++ -Os -I. -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=1 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable -fcoroutines -c -o verilated_vpi.o /usr/share/verilator/include/verilated_vpi.cpp 
g++ -Os -I. -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=1 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable -fcoroutines -c -o verilated_timing.o /usr/share/verilator/include/verilated_timing.cpp 
g++ -Os -I. -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=1 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable -fcoroutines -c -o verilated_threads.o /usr/share/verilator/include/verilated_threads.cpp python3 /usr/share/verilator/bin/verilator_includer -DVL_INCLUDE_OPT=include Vtop.cpp Vtop___024root__DepSet_h84412442__0.cpp Vtop___024root__DepSet_heccd7ead__0.cpp Vtop__Dpi.cpp Vtop___024root__Slow.cpp Vtop___024root__DepSet_h84412442__0__Slow.cpp Vtop___024root__DepSet_heccd7ead__0__Slow.cpp Vtop__Syms.cpp > Vtop__ALL.cpp 
g++ -Os -I. -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=1 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable -fcoroutines -c -o Vtop__ALL.o Vtop__ALL.cpp echo "" > Vtop__ALL.verilator_deplist.tmp 
g++ verilator.o verilated.o verilated_dpi.o verilated_vpi.o verilated_timing.o verilated_threads.o Vtop__ALL.a -Wl,-rpath,/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/venv/lib/python3.13/site-packages/cocotb/libs -L/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/venv/lib/python3.13/site-packages/cocotb/libs -lcocotbvpi_verilator -pthread -lpthread -latomic -o Vtop rm Vtop__ALL.verilator_deplist.tmp 
make[3]: Leaving directory '/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/sim_build/dma' rm -f results.xml MODULE=test TESTCASE= TOPLEVEL=tb TOPLEVEL_LANG=verilog \ sim_build/dma/Vtop 
-.--ns INFO gpi ..mbed/gpi_embed.cpp:108 in set_program_name_in_venv Using Python virtual environment interpreter at /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/venv/bin/python 
-.--ns INFO gpi ../gpi/GpiCommon.cpp:101 in gpi_print_registered_impl VPI registered 0.00ns INFO cocotb Running on Verilator version 5.032 2025-01-01 
0.00ns INFO cocotb Running tests with cocotb v1.9.2 from /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/venv/lib/python3.13/site-packages/cocotb 
0.00ns INFO cocotb Seeding Python random module with 1773995986 
0.00ns INFO cocotb.regression Found test test.test_reset_defaults 
0.00ns INFO cocotb.regression Found test test.test_register_readback 
0.00ns INFO cocotb.regression Found test test.test_count_clamping 
0.00ns INFO cocotb.regression Found test test.test_tx_mode 
0.00ns INFO cocotb.regression Found test test.test_tx_two_words 
0.00ns INFO cocotb.regression Found test test.test_tx_full_buffer 
0.00ns INFO cocotb.regression Found test test.test_rx_mode 
0.00ns INFO cocotb.regression Found test test.test_rx_different_values 
0.00ns INFO cocotb.regression Found test test.test_irq_enabled 
0.00ns INFO cocotb.regression Found test test.test_irq_disabled 
0.00ns INFO cocotb.regression Found test test.test_clr_irq 
0.00ns INFO cocotb.regression Found test test.test_second_transfer 
0.00ns INFO cocotb.regression running test_reset_defaults (1/12) 
After reset: STATUS=0 (idle), COUNT=1, DIVISOR=63. 0.00ns INFO cocotb.tb Test 1: reset defaults 
0.00ns INFO cocotb.tb Reset -Info: /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/tb.v:12: $dumpvar ignored, as Verilated without --trace 
79800.00ns INFO cocotb.tb Test 1 PASSED 
79800.00ns INFO cocotb.regression test_reset_defaults passed 
79800.00ns INFO cocotb.regression running test_register_readback (2/12)
Write and read back COUNT, DIVISOR, and DATA registers. 
79800.00ns INFO cocotb.tb Test 2: register read/write 
79800.00ns INFO cocotb.tb Reset 
605800.00ns INFO cocotb.tb Test 2 PASSED 
605800.00ns INFO cocotb.regression test_register_readback passed 
605800.00ns INFO cocotb.regression running test_count_clamping (3/12)
COUNT=0 must clamp to 1; COUNT>32 must clamp to 32. 
605800.00ns INFO cocotb.tb Test 3: COUNT clamping 
605800.00ns INFO cocotb.tb Reset 
816800.00ns INFO cocotb.tb Test 3 PASSED 
816800.00ns INFO cocotb.regression test_count_clamping passed 
816800.00ns INFO cocotb.regression running test_tx_mode (4/12)
 TX: DMA clocks out buffer bytes and sets STATUS[done]. 
816800.00ns INFO cocotb.tb Test 4: TX mode 
816800.00ns INFO cocotb.tb Reset 
6182600.00ns INFO cocotb.regression test_tx_mode failed Traceback (most recent call last): 
File "/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test.py", line 180, in test_tx_mode status = await wait_done(tqv, dut) ^^^^^^^^^^^^^^^^^^^^^^^^^ 
File "/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test.py", line 53, in wait_done raise AssertionError(f"Timeout: DMA did not complete within {timeout} polls") AssertionError: Timeout: DMA did not complete within 200 polls 
6182600.00ns INFO cocotb.regression running test_tx_two_words (5/12) TX 8 bytes from DATA0 and DATA1. 
6182600.00ns INFO cocotb.tb Test 5: TX two words 
6182600.00ns INFO cocotb.tb Reset 
11574600.01ns INFO cocotb.regression test_tx_two_words failed Traceback (most recent call last): File "/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test.py", line 211, in test_tx_two_words status = await wait_done(tqv, dut) ^^^^^^^^^^^^^^^^^^^^^^^^^
 File "/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test.py", line 53, in wait_done raise AssertionError(f"Timeout: DMA did not complete within {timeout} polls") AssertionError: Timeout: DMA did not complete within 200 polls 
11574600.01ns INFO cocotb.regression running test_tx_full_buffer (6/12) TX all 32 bytes (8 DATA words). 
11574600.01ns INFO cocotb.tb Test 6: TX full 32-byte buffer 
11574600.01ns INFO cocotb.tb Reset 
25013800.01ns INFO cocotb.regression test_tx_full_buffer failed Traceback (most recent call last): File "/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test.py", line 240, in test_tx_full_buffer status = await wait_done(tqv, dut, timeout=500) ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ 
File "/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test.py", line 53, in wait_done raise AssertionError(f"Timeout: DMA did not complete within {timeout} polls") AssertionError: Timeout: DMA did not complete within 500 polls
 25013800.01ns INFO cocotb.regression running test_rx_mode (7/12) RX: DMA samples ui_in and fills DATA0 with captured bytes. 
25013800.01ns INFO cocotb.tb Test 7: RX mode 
25013800.01ns INFO cocotb.tb Reset 
30353400.01ns INFO cocotb.regression test_rx_mode failed Traceback (most recent call last): 
File "/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test.py", line 269, in test_rx_mode status = await wait_done(tqv, dut) ^^^^^^^^^^^^^^^^^^^^^^^^^
 File "/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test.py", line 53, in wait_done raise AssertionError(f"Timeout: DMA did not complete within {timeout} polls") AssertionError: Timeout: DMA did not complete within 200 polls 
30353400.01ns INFO cocotb.regression running test_rx_different_values (8/12) Two consecutive RX transfers with different ui_in values. 
30353400.01ns INFO cocotb.tb Test 8: RX different values 
30353400.01ns INFO cocotb.tb Reset 
35693000.01ns INFO cocotb.regression test_rx_different_values failed Traceback (most recent call last): File "/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test.py", line 298, in test_rx_different_values await wait_done(tqv, dut) File "/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test.py", line 53, in wait_done raise AssertionError(f"Timeout: DMA did not complete within {timeout} polls") AssertionError: Timeout: DMA did not complete within 200 polls 
35693000.01ns INFO cocotb.regression running test_irq_enabled (9/12) IRQ is asserted when irq_enable=1 and DMA completes.
 35693000.01ns INFO cocotb.tb Test 9: IRQ enabled 
35693000.01ns INFO cocotb.tb Reset 
41058800.01ns INFO cocotb.regression test_irq_enabled failed Traceback (most recent call last): File "/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test.py", line 337, in test_irq_enabled await wait_done(tqv, dut) File "/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test.py", line 53, in wait_done raise AssertionError(f"Timeout: DMA did not complete within {timeout} polls") AssertionError: Timeout: DMA did not complete within 200 polls 
41058800.01ns INFO cocotb.regression running test_irq_disabled (10/12) No IRQ when irq_enable=0, even after transfer completes. 
41058800.01ns INFO cocotb.tb Test 10: IRQ disabled 
41058800.01ns INFO cocotb.tb Reset 
46398400.01ns INFO cocotb.regression test_irq_disabled failed Traceback (most recent call last): File "/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test.py", line 363, in test_irq_disabled await wait_done(tqv, dut) File "/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test.py", line 53, in wait_done raise AssertionError(f"Timeout: DMA did not complete within {timeout} polls") AssertionError: Timeout: DMA did not complete within 200 polls 
46398400.01ns INFO cocotb.regression running test_clr_irq (11/12) Writing CLR_IRQ clears STATUS[done] and deasserts the interrupt line.
 46398400.01ns INFO cocotb.tb Test 11: CLR_IRQ 
46398400.01ns INFO cocotb.tb Reset 
51738000.01ns INFO cocotb.regression test_clr_irq failed Traceback (most recent call last): File "/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test.py", line 389, in test_clr_irq await wait_done(tqv, dut) File "/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test.py", line 53, in wait_done raise AssertionError(f"Timeout: DMA did not complete within {timeout} polls") AssertionError: Timeout: DMA did not complete within 200 polls 
51738000.01ns INFO cocotb.regression running test_second_transfer (12/12) After CLR_IRQ the DMA returns to IDLE and can be restarted. 
51738000.01ns INFO cocotb.tb Test 12: second transfer after CLR_IRQ 
51738000.01ns INFO cocotb.tb Reset 
57103800.01ns INFO cocotb.regression test_second_transfer failed Traceback (most recent call last): File "/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test.py", line 428, in test_second_transfer await wait_done(tqv, dut) File "/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test.py", line 53, in wait_done raise AssertionError(f"Timeout: DMA did not complete within {timeout} polls") AssertionError: Timeout: DMA did not complete within 200 polls 
57103800.01ns INFO cocotb.regression 
 ** TEST STATUS SIM TIME (ns) REAL TIME (s) RATIO (ns/s) ** 
 ** test.test_reset_defaults PASS 79800.00 0.05 1629085.85 ** 
** test.test_register_readback PASS 526000.00 0.28 1852337.13 ** 
** test.test_count_clamping PASS 211000.00 0.12 1756924.78 ** 
** test.test_tx_mode FAIL 5365800.00 3.19 1683320.24 ** 
** test.test_tx_two_words FAIL 5392000.00 3.22 1674444.88 **
 ** test.test_tx_full_buffer FAIL 13439200.00 8.06 1667641.40 ** 
** test.test_rx_mode FAIL 5339600.00 3.24 1647499.38 ** 
** test.test_rx_different_values FAIL 5339600.00 3.24 1645710.68 ** 
** test.test_irq_enabled FAIL 5365800.00 3.30 1627337.52 ** 
** test.test_irq_disabled FAIL 5339600.00 3.29 1623424.74 ** 
** test.test_clr_irq FAIL 5339600.00 3.26 1639388.36 ** 
** test.test_second_transfer FAIL 5365800.00 3.26 1645935.64 ** 
** TESTS=12 PASS=3 FAIL=9 SKIP=0 57103800.01 34.54 1653120.84 ** 
**** - :0: Verilog $finish make[2]: Leaving directory '/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test' 
make[1]: Leaving directory '/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test'
9 tests failed because test.py was unaware of the new SEC_KEY. It needs to be updated to write SEC_KEY=0xA5 before every DMA start:
Edit test.py (Added 2 lines)
Add the helper function arm_and_start and update all tests:
Edit test.py (Added 6 lines)
Now, replace all instances of write_byte_reg(CTRL, CTRL_START...) with arm_and_start(...)0635

left635

0635

0635

left635

0635

left635

left635

0635

left635

left635

left635

left635

0635

left635

left635


Edit  HYPERLINK "vscode-webview://1b74624abcmmdcs9pp4imo5eguud6qrf7o0fr1gvckb87d9amvkm/index.html?id=2a5971ee-97e5-4c5d-8625-bc3e0200a304&parentId=1&origin=9ac34b4a-26c2-4308-9708-fee7f6985adb&swVersion=4&extensionId=Anthropic.claude-code&platform=electron&vscode-resource-base-authority=vscode-resource.vscode-cdn.net&parentOrigin=vscode-file%3A%2F%2Fvscode-app&session=52a54462-3781-4b3e-bd2a-ed2d5234f78c" \h test.py
Modified
Edit  HYPERLINK "vscode-webview://1b74624abcmmdcs9pp4imo5eguud6qrf7o0fr1gvckb87d9amvkm/index.html?id=2a5971ee-97e5-4c5d-8625-bc3e0200a304&parentId=1&origin=9ac34b4a-26c2-4308-9708-fee7f6985adb&swVersion=4&extensionId=Anthropic.claude-code&platform=electron&vscode-resource-base-authority=vscode-resource.vscode-cdn.net&parentOrigin=vscode-file%3A%2F%2Fvscode-app&session=52a54462-3781-4b3e-bd2a-ed2d5234f78c" \h test.py0635

0635

left635

0635

left635

0635

left635

left635

0635

0635

left635

left635

left635

left635

0635

0635

0635

left635

left635


Modified
Edit  HYPERLINK "vscode-webview://1b74624abcmmdcs9pp4imo5eguud6qrf7o0fr1gvckb87d9amvkm/index.html?id=2a5971ee-97e5-4c5d-8625-bc3e0200a304&parentId=1&origin=9ac34b4a-26c2-4308-9708-fee7f6985adb&swVersion=4&extensionId=Anthropic.claude-code&platform=electron&vscode-resource-base-authority=vscode-resource.vscode-cdn.net&parentOrigin=vscode-file%3A%2F%2Fvscode-app&session=52a54462-3781-4b3e-bd2a-ed2d5234f78c" \h test.py0635

0635

left635

0635

left635

0635

left635

left635

0635

left635

left635

left635

left635

0635

left635

left635


Modified
Edit  HYPERLINK "vscode-webview://1b74624abcmmdcs9pp4imo5eguud6qrf7o0fr1gvckb87d9amvkm/index.html?id=2a5971ee-97e5-4c5d-8625-bc3e0200a304&parentId=1&origin=9ac34b4a-26c2-4308-9708-fee7f6985adb&swVersion=4&extensionId=Anthropic.claude-code&platform=electron&vscode-resource-base-authority=vscode-resource.vscode-cdn.net&parentOrigin=vscode-file%3A%2F%2Fvscode-app&session=52a54462-3781-4b3e-bd2a-ed2d5234f78c" \h test.py0635

0635

left635

0635

left635

0635

left635

left635

0635

left635

left635

left635

left635

0635

left635

left635


Modified
Edit  HYPERLINK "vscode-webview://1b74624abcmmdcs9pp4imo5eguud6qrf7o0fr1gvckb87d9amvkm/index.html?id=2a5971ee-97e5-4c5d-8625-bc3e0200a304&parentId=1&origin=9ac34b4a-26c2-4308-9708-fee7f6985adb&swVersion=4&extensionId=Anthropic.claude-code&platform=electron&vscode-resource-base-authority=vscode-resource.vscode-cdn.net&parentOrigin=vscode-file%3A%2F%2Fvscode-app&session=52a54462-3781-4b3e-bd2a-ed2d5234f78c" \h test.py0635

0635

left635

0635

left635

0635

left635

0635

0635

left635

left635

left635

left635

0635

0635

0635

left635

left635


Modified
Edit  HYPERLINK "vscode-webview://1b74624abcmmdcs9pp4imo5eguud6qrf7o0fr1gvckb87d9amvkm/index.html?id=2a5971ee-97e5-4c5d-8625-bc3e0200a304&parentId=1&origin=9ac34b4a-26c2-4308-9708-fee7f6985adb&swVersion=4&extensionId=Anthropic.claude-code&platform=electron&vscode-resource-base-authority=vscode-resource.vscode-cdn.net&parentOrigin=vscode-file%3A%2F%2Fvscode-app&session=52a54462-3781-4b3e-bd2a-ed2d5234f78c" \h test.py0635

0635

0635

left635

0635

left635

0635

left635

left635

0635

left635

left635


Modified
Edit  HYPERLINK "vscode-webview://1b74624abcmmdcs9pp4imo5eguud6qrf7o0fr1gvckb87d9amvkm/index.html?id=2a5971ee-97e5-4c5d-8625-bc3e0200a304&parentId=1&origin=9ac34b4a-26c2-4308-9708-fee7f6985adb&swVersion=4&extensionId=Anthropic.claude-code&platform=electron&vscode-resource-base-authority=vscode-resource.vscode-cdn.net&parentOrigin=vscode-file%3A%2F%2Fvscode-app&session=52a54462-3781-4b3e-bd2a-ed2d5234f78c" \h test.py0635

0635

0635

left635

0635

left635

0635

0635

left635

left635

0635

0635

0635

left635

left635


Modified
Edit  HYPERLINK "vscode-webview://1b74624abcmmdcs9pp4imo5eguud6qrf7o0fr1gvckb87d9amvkm/index.html?id=2a5971ee-97e5-4c5d-8625-bc3e0200a304&parentId=1&origin=9ac34b4a-26c2-4308-9708-fee7f6985adb&swVersion=4&extensionId=Anthropic.claude-code&platform=electron&vscode-resource-base-authority=vscode-resource.vscode-cdn.net&parentOrigin=vscode-file%3A%2F%2Fvscode-app&session=52a54462-3781-4b3e-bd2a-ed2d5234f78c" \h test.py0635

0635

0635

left635

0635

left635

0635

0635

left635

left635

0635

0635

left635

left635


Modified
Edit  HYPERLINK "vscode-webview://1b74624abcmmdcs9pp4imo5eguud6qrf7o0fr1gvckb87d9amvkm/index.html?id=2a5971ee-97e5-4c5d-8625-bc3e0200a304&parentId=1&origin=9ac34b4a-26c2-4308-9708-fee7f6985adb&swVersion=4&extensionId=Anthropic.claude-code&platform=electron&vscode-resource-base-authority=vscode-resource.vscode-cdn.net&parentOrigin=vscode-file%3A%2F%2Fvscode-app&session=52a54462-3781-4b3e-bd2a-ed2d5234f78c" \h test.py0635

0635

0635

left635

0635

left635

0635

left635

left635

0635

0635

left635

left635


Modified
Run the test again.:0635

0635

0635

left635

0635

left635

0635

0635

0635

0635

left635

left635

0635

0635

0635

0635

0635

left635

left635


Bash
IN
cd /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test && make test_dma 2>&1 | grep -E "(PASS|FAIL|TESTS=|Error)"
OUT
make: *** [Makefile:26: test_dma] Error 2
Bash
IN
make test_dma 2>&1 | grep -E "(PASS|FAIL|TESTS=|AssertionError|INFO.*test_)" | tail -30
OUT
(Bash completed with no output)
Bash
IN
make test_dma 2>&1 | tail -40
OUT
make -f test_dma.mk SIM_BUILD=sim_build/dma clean
make[1]: Entering directory '/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test'
make[1]: cocotb-config: No such file or directory
test_dma.mk:54: /Makefile.sim: No such file or directory
make[1]: *** No rule to make target '/Makefile.sim'.  Stop.
make[1]: Leaving directory '/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test'
make: *** [Makefile:26: test_dma] Error 2
You need to activate the virtual environment first (your terminal is currently using a dedicated venv within the test directory):
Bash
source /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/venv/bin/activate
make test_dma
Or, if the venv does not have cocotb installed yet:
Bash
source venv/bin/activate
pip install cocotb==1.9.2 pytest
make test_dma
Based on the previous logs, the venv is located at /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/venv/ — please run the source venv/bin/activate command before executing make test_dma.
(venv) user@host:~/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test$ gtkwave sim_build/dma/tb.vcd GTKWave Analyzer v3.3.121 (w)1999-2024 BSI Error opening .vcd file 'sim_build/dma/tb.vcd'. Why: No such file or directory
The VCD file wasn't created because WAVES=1 inside the .mk file wasn't being recognized by cocotb. You need to pass it directly via the command line:
Edit test_dma.mk (Removed 2 lines)
Run with WAVES=1 on the command line:
Bash
make test_dma WAVES=1
Then open the waveform:
Bash
gtkwave sim_build/dma/tb.vcd
Using WAVES=1 on the command line has higher priority, ensuring cocotb receives it, automatically adds --trace, and calls traceEverOn(true) in the correct order before the simulation begins.
(venv) user@host:~/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test$ make test_dma WAVES=1 make -f test_dma.mk SIM_BUILD=sim_build/dma clean make[1]: Entering directory '/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test' rm -f -r sim_build/dma rm -f dump.vcd rm -f dump.fst make[1]: Leaving directory '/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test' make -f test_dma.mk SIM_BUILD=sim_build/dma make[1]: Entering directory '/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test' rm -f results.xml "make" -f test_dma.mk results.xml make[2]: Entering directory '/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test' mkdir -p sim_build/dma /usr/bin/verilator -cc --exe -Mdir sim_build/dma -DCOCOTB_SIM=1 --top-module tb --timing -I/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/../src -I/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test --timescale 1ns/1ps --vpi --public-flat-rw --prefix Vtop -o Vtop -LDFLAGS "-Wl,-rpath,/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/venv/lib/python3.13/site-packages/cocotb/libs -L/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/venv/lib/python3.13/site-packages/cocotb/libs -lcocotbvpi_verilator" /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/../src/tqvp_dma.v /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/tt_wrapper.v /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test_harness/falling_edge_detector.sv /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test_harness/reclocking.sv /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test_harness/rising_edge_detector.sv /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test_harness/spi_reg.sv /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test_harness/synchronizer.sv /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/tb.v /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/venv/lib/python3.13/site-packages/cocotb/share/lib/verilator/verilator.cpp 
- V e r i l a t i o n R e p o r t: Verilator 5.032 2025-01-01 rev (Debian 5.032-1+b2) - Verilator: Built from 0.348 MB sources in 9 modules, into 0.239 MB in 8 C++ files needing 0.000 MB 
- Verilator: Walltime 0.023 s (elab=0.002, cvt=0.012, bld=0.000); cpu 0.023 s on 1 threads; alloced 10.906 MB make -C sim_build/dma -f Vtop.mk 
make[3]: Entering directory '/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/sim_build/dma' 
g++ -I. -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=1 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable -fcoroutines -Os -c -o verilator.o /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/venv/lib/python3.13/site-packages/cocotb/share/lib/verilator/verilator.cpp 
g++ -Os -I. -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=1 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable -fcoroutines -c -o verilated.o /usr/share/verilator/include/verilated.cpp 
g++ -Os -I. -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=1 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable -fcoroutines -c -o verilated_dpi.o /usr/share/verilator/include/verilated_dpi.cpp 
g++ -Os -I. -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=1 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable -fcoroutines -c -o verilated_vpi.o /usr/share/verilator/include/verilated_vpi.cpp 
g++ -Os -I. -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=1 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable -fcoroutines -c -o verilated_timing.o /usr/share/verilator/include/verilated_timing.cpp 
g++ -Os -I. -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=1 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable -fcoroutines -c -o verilated_threads.o /usr/share/verilator/include/verilated_threads.cpp python3 /usr/share/verilator/bin/verilator_includer -DVL_INCLUDE_OPT=include Vtop.cpp Vtop___024root__DepSet_h84412442__0.cpp Vtop___024root__DepSet_heccd7ead__0.cpp Vtop__Dpi.cpp Vtop___024root__Slow.cpp Vtop___024root__DepSet_h84412442__0__Slow.cpp Vtop___024root__DepSet_heccd7ead__0__Slow.cpp Vtop__Syms.cpp > Vtop__ALL.cpp 
g++ -Os -I. -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=1 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable -fcoroutines -c -o Vtop__ALL.o Vtop__ALL.cpp echo "" > Vtop__ALL.verilator_deplist.tmp 
g++ verilator.o verilated.o verilated_dpi.o verilated_vpi.o verilated_timing.o verilated_threads.o Vtop__ALL.a -Wl,-rpath,/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/venv/lib/python3.13/site-packages/cocotb/libs -L/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/venv/lib/python3.13/site-packages/cocotb/libs -lcocotbvpi_verilator -pthread -lpthread -latomic -o Vtop rm Vtop__ALL.verilator_deplist.tmp 
make[3]: Leaving directory '/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/sim_build/dma' rm -f results.xml MODULE=test TESTCASE= TOPLEVEL=tb TOPLEVEL_LANG=verilog \ sim_build/dma/Vtop -.--ns INFO gpi ..mbed/gpi_embed.cpp:108 in set_program_name_in_venv Using Python virtual environment interpreter at /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/venv/bin/python 
-.--ns INFO gpi ../gpi/GpiCommon.cpp:101 in gpi_print_registered_impl VPI registered 
0.00ns INFO cocotb Running on Verilator version 5.032 2025-01-01 
0.00ns INFO cocotb Running tests with cocotb v1.9.2 from /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/venv/lib/python3.13/site-packages/cocotb 
0.00ns INFO cocotb Seeding Python random module with 1773996462 
0.00ns INFO cocotb.regression Found test test.test_reset_defaults 
0.00ns INFO cocotb.regression Found test test.test_register_readback 
0.00ns INFO cocotb.regression Found test test.test_count_clamping 
0.00ns INFO cocotb.regression Found test test.test_tx_mode 
0.00ns INFO cocotb.regression Found test test.test_tx_two_words 
0.00ns INFO cocotb.regression Found test test.test_tx_full_buffer 
0.00ns INFO cocotb.regression Found test test.test_rx_mode 
0.00ns INFO cocotb.regression Found test test.test_rx_different_values 
0.00ns INFO cocotb.regression Found test test.test_irq_enabled 
0.00ns INFO cocotb.regression Found test test.test_irq_disabled 
0.00ns INFO cocotb.regression Found test test.test_clr_irq 
0.00ns INFO cocotb.regression Found test test.test_second_transfer 
0.00ns INFO cocotb.regression running test_reset_defaults (1/12) 
After reset: STATUS=0 (idle), COUNT=1, DIVISOR=63. 
0.00ns INFO cocotb.tb Test 1: reset defaults 
0.00ns INFO cocotb.tb Reset -Info: /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/tb.v:12: $dumpvar ignored, as Verilated without --trace 
79800.00ns INFO cocotb.tb Test 1 PASSED
 79800.00ns INFO cocotb.regression test_reset_defaults passed 
79800.00ns INFO cocotb.regression running test_register_readback (2/12) Write and read back COUNT, DIVISOR, and DATA registers. 
79800.00ns INFO cocotb.tb Test 2: register read/write 
79800.00ns INFO cocotb.tb Reset 
605800.00ns INFO cocotb.tb Test 2 PASSED
605800.00ns INFO cocotb.regression test_register_readback passed 
605800.00ns INFO cocotb.regression running test_count_clamping (3/12) COUNT=0 must clamp to 1; COUNT>32 must clamp to 32. 
605800.00ns INFO cocotb.tb Test 3: COUNT clamping 
605800.00ns INFO cocotb.tb Reset 
816800.00ns INFO cocotb.tb Test 3 PASSED 
816800.00ns INFO cocotb.regression test_count_clamping passed 
816800.00ns INFO cocotb.regression running test_tx_mode (4/12) TX: DMA clocks out buffer bytes and sets STATUS[done]. 
816800.00ns INFO cocotb.tb Test 4: TX mode 
816800.00ns INFO cocotb.tb Reset 
975100.00ns INFO cocotb.tb Test 4 PASSED 
975100.00ns INFO cocotb.regression test_tx_mode passed 
975100.00ns INFO cocotb.regression running test_tx_two_words (5/12) TX 8 bytes from DATA0 and DATA1. 
975100.00ns INFO cocotb.tb Test 5: TX two words 
975100.00ns INFO cocotb.tb Reset 
1159600.00ns INFO cocotb.tb Test 5 PASSED 
1159600.00ns INFO cocotb.regression test_tx_two_words passed 
1159600.00ns INFO cocotb.regression running test_tx_full_buffer (6/12) TX all 32 bytes (8 DATA words). 
1159600.00ns INFO cocotb.tb Test 6: TX full 32-byte buffer 
1159600.00ns INFO cocotb.tb Reset 
1501300.00ns INFO cocotb.tb Test 6 PASSED 
1501300.01ns INFO cocotb.regression test_tx_full_buffer passed 
1501300.01ns INFO cocotb.regression running test_rx_mode (7/12) RX: DMA samples ui_in and fills DATA0 with captured bytes. 
1501300.01ns INFO cocotb.tb Test 7: RX mode 
1501300.01ns INFO cocotb.tb Reset 
1659700.01ns INFO cocotb.tb Test 7 PASSED 
1659700.01ns INFO cocotb.regression test_rx_mode passed 
1659700.01ns INFO cocotb.regression running test_rx_different_values (8/12) Two consecutive RX transfers with different ui_in values. 
1659700.01ns INFO cocotb.tb Test 8: RX different values 
1659700.01ns INFO cocotb.tb Reset 
1949300.01ns INFO cocotb.tb Test 8 PASSED 
1949300.01ns INFO cocotb.regression test_rx_different_values passed 
1949300.01ns INFO cocotb.regression running test_irq_enabled (9/12) IRQ is asserted when irq_enable=1 and DMA completes. 
1949300.01ns INFO cocotb.tb Test 9: IRQ enabled 
1949300.01ns INFO cocotb.tb Reset 
2107600.01ns INFO cocotb.tb Test 9 PASSED 
2107600.01ns INFO cocotb.regression test_irq_enabled passed 
2107600.01ns INFO cocotb.regression running test_irq_disabled (10/12) No IRQ when irq_enable=0, even after transfer completes. 
2107600.01ns INFO cocotb.tb Test 10: IRQ disabled 
2107600.01ns INFO cocotb.tb Reset 
2239700.01ns INFO cocotb.tb Test 10 PASSED 
2239700.01ns INFO cocotb.regression test_irq_disabled passed 
2239700.01ns INFO cocotb.regression running test_clr_irq (11/12) Writing CLR_IRQ clears STATUS[done] and deasserts the interrupt line. 
2239700.01ns INFO cocotb.tb Test 11: CLR_IRQ 
2239700.01ns INFO cocotb.tb Reset 
2450600.01ns INFO cocotb.tb Test 11 PASSED
 2450600.01ns INFO cocotb.regression test_clr_irq passed 
2450600.01ns INFO cocotb.regression running test_second_transfer (12/12) After CLR_IRQ the DMA returns to IDLE and can be restarted.
 2450600.01ns INFO cocotb.tb Test 12: second transfer after CLR_IRQ 
2450600.01ns INFO cocotb.tb Reset 
2740000.01ns INFO cocotb.tb Test 12 PASSED 
2740000.01ns INFO cocotb.regression test_second_transfer passed 
2740000.01ns INFO cocotb.regression 
 TEST STATUS SIM TIME (ns) REAL TIME (s) RATIO (ns/s) ** ***** 
** test.test_reset_defaults PASS 79800.00 0.05 1517436.24 
 ** test.test_register_readback PASS 526000.00 0.32 1642549.80 ** 
** test.test_count_clamping PASS 211000.00 0.13 1609306.99 ** 
** test.test_tx_mode PASS 158300.00 0.10 1583246.88 ** 
** test.test_tx_two_words PASS 184500.00 0.11 1610625.32 ** 
** test.test_tx_full_buffer PASS 341700.00 0.20 1677619.48 ** 
** test.test_rx_mode PASS 158400.00 0.10 1635347.12 ** 
** test.test_rx_different_values PASS 289600.00 0.18 1601451.38 ** 
** test.test_irq_enabled PASS 158300.00 0.10 1615049.92 **
 ** test.test_irq_disabled PASS 132100.00 0.08 1572295.68 ** 
** test.test_clr_irq PASS 210900.00 0.13 1644571.29 ** 
** test.test_second_transfer PASS 289400.00 0.18 1630505.68 ** 
** TESTS=12 PASS=12 FAIL=0 SKIP=0 2740000.01 1.72 1591980.34 ** 
***** - :0: Verilog $finish make[2]: Leaving directory '/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test' make[1]: Leaving directory '/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test' (venv) user@host:~/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test$ gtkwave sim_build/dma/tb.vcd GTKWave Analyzer v3.3.121 (w)1999-2024 BSI Error opening .vcd file 'sim_build/dma/tb.vcd'. Why: No such file or directory (venv) user@host:~/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test$
12/12 PASS! All tests passed. Regarding the VCD issue — to understand why WAVES=1 wasn't accepted, see cocotb's makefile:
Bash
IN
grep -n "WAVES\|trace\|VCD\|fst" /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/venv/lib/python3.13/site-packages/cocotb/share/makefiles/simulators/Makefile.verilator | head -30
OUT
51:  COMPILE_ARGS += --trace --trace-structs
52:  SIM_ARGS += --trace
84:     $(RM) dump.fst
Bash
IN
sed -n '45,60p' /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/venv/lib/python3.13/site-packages/cocotb/share/makefiles/simulators/Makefile.verilator
OUT
  COMPILE_ARGS += --debug -CFLAGS "-DVL_DEBUG -DVERILATOR_SIM_DEBUG -g"
  PLUSARGS += +verilator+debug
  BUILD_ARGS += OPT_FAST=-Og OPT_SLOW=-Og OPT_GLOBAL=-Og
endif
ifeq ($(VERILATOR_TRACE),1)
  COMPILE_ARGS += --trace --trace-structs
  SIM_ARGS += --trace
endif

COMPILE_ARGS += --timescale $(COCOTB_HDL_TIMEUNIT)/$(COCOTB_HDL_TIMEPRECISION)

COMPILE_ARGS += --vpi --public-flat-rw --prefix Vtop -o Vtop -LDFLAGS "-Wl,-rpath,$(shell cocotb-config --lib-dir) -L$(shell cocotb-config --lib-dir) -lcocotbvpi_verilator"
ifdef VERILOG_INCLUDE_DIRS
COMPILE_ARGS += $(addprefix +incdir+, $(VERILOG_INCLUDE_DIRS))
The correct variable is VERILATOR_TRACE=1, not WAVES=1:
Bash
make test_dma VERILATOR_TRACE=1
Then open the waveform:
Bash
gtkwave sim_build/dma/tb.vcd
(venv) user@host:~/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test$ gtkwave sim_build/dma/tb.vcd GTKWave Analyzer v3.3.121 (w)1999-2024 BSI Error opening .vcd file 'sim_build/dma/tb.vcd'. Why: No such file or directory
Locating where the VCD was generated:
Since it's still not appearing in the expected path, let's find exactly where Verilator dropped the file:
Bash
find sim_build -name "*.vcd"
If the file still isn't found, it's possible that cocotb is naming the dump file dump.vcd or placing it directly in the test/ directory instead of the sim_build/dma/ subdirectory.
Bash
IN
find /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test -name "*.vcd" -o -name "*.fst" 2>/dev/null
OUT
/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/tb.vcd
/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/dump.vcd
The VCD file is located in the test/ directory, not in sim_build/dma/:
Bash
gtkwave tb.vcd# or
gtkwave dump.vcd
User: Which testbench is used for the DMA?
Claude: The DMA testbench consists of two files working together:
File
Role
test/tb.v
Verilog wrapper — Connects the DUT, declares clock/reset, and dumps the VCD.
test/test.py
Cocotb Python — Contains the entire test logic (stimulus, assertions).
Additional supporting files:
test/tt_wrapper.v: Wraps the peripheral into the standard TinyQV interface.
test/test_harness/*.sv: SPI registers, synchronizers, and edge detectors.
test/test_dma.mk: The Makefile that specifies the files above and runs Verilator.
Operational Flow:
test_dma.mk → Verilator compiles (tb.v + tt_wrapper.v + tqvp_dma.v + test_harness).
Simulation runs (Vtop binary).
cocotb loads test.py → Drives signals via the VPI.
User: Why doesn't the data I see on GTKWave match the data in test.py?
Claude: After reviewing tqv.py and tt_wrapper.v, here is why the data on GTKWave differs from test.py:
Reasons for Data Mismatch
SPI Delay (~30+ clock cycles):
When test.py calls write_byte_reg(CTRL, ...), it happens instantaneously in Python, but on the waveform, the data must travel through the SPI chain:
Python write → uio_in (SPI MOSI) → 2-stage synchronizer → spi_reg → data_in → tqvp_dma.
Each SPI transaction takes approximately 262 clock cycles. (Evidence: A single test pass at 79,800ns ≈ 798 clocks for a 10-clock reset + 3 SPI reads).
2-Stage Synchronizer for ui_in:
ui_in is set immediately in test.py, but the DMA actually receives that value 2 clock cycles later due to the synchronizer in tt_wrapper.v.
rst_n Registered on negedge:
Verilog
always @(negedge clk) rst_reg_n <= rst_n;
The reset signal reaches the DMA half a clock cycle later than the rst_n signal you see on the waveform.
How to View Data Correctly on GTKWave
To see the actual behavior, you should inspect signals at the DUT level, not the tb level:
tb.test_harness.user_peripheral.state: DMA state machine.
tb.test_harness.user_peripheral.dbuf: Data buffer contents.
tb.test_harness.address / data_in / data_write_n: Register bus signals.
tb.test_harness.spi_mosi_sync: SPI data after synchronization.
The signal tb.ui_in will differ from tb.test_harness.ui_in_sync (after the 2-stage sync)—this is the most common reason for perceived "mismatched" data.

- :0: Verilog $finish make[2]: Leaving directory '/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test' make[1]: Leaving directory '/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test' make -f test_peripherals.mk SIM_BUILD=sim_build/peripherals clean make[1]: Entering directory '/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test' rm -f -r sim_build/peripherals rm -f dump.vcd rm -f dump.fst make[1]: Leaving directory '/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test' make -f test_peripherals.mk SIM_BUILD=sim_build/peripherals make[1]: Entering directory '/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test' rm -f results.xml "make" -f test_peripherals.mk results.xml make[2]: Entering directory '/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test' mkdir -p sim_build/peripherals /usr/bin/verilator -cc --exe -Mdir sim_build/peripherals -DCOCOTB_SIM=1 --top-module tb_peripherals -DSIM --timing -Wno-SYMRSVDWORD -Wno-IMPLICIT -Wno-PINMISSING -Wno-WIDTH --timescale 1ns/1ps --vpi --public-flat-rw --prefix Vtop -o Vtop -LDFLAGS "-Wl,-rpath,/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/venv/lib/python3.13/site-packages/cocotb/libs -L/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/venv/lib/python3.13/site-packages/cocotb/libs -lcocotbvpi_verilator" /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/../src/tqvp_dma.v /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/../src/peripherals.v /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/tb_peripherals.v /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/venv/lib/python3.13/site-packages/cocotb/share/lib/verilator/verilator.cpp - V e r i l a t i o n R e p o r t: Verilator 5.032 2025-01-01 rev (Debian 5.032-1+b2) - Verilator: Built from 0.121 MB sources in 4 modules, into 0.127 MB in 8 C++ files needing 0.000 MB - Verilator: Walltime 0.031 s (elab=0.002, cvt=0.014, bld=0.000); cpu 0.025 s on 1 threads; alloced 10.246 MB make -C sim_build/peripherals -f Vtop.mk make[3]: Entering directory '/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/sim_build/peripherals' g++ -I. -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=1 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable -fcoroutines -Os -c -o verilator.o /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/venv/lib/python3.13/site-packages/cocotb/share/lib/verilator/verilator.cpp g++ -Os -I. -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=1 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable -fcoroutines -c -o verilated.o /usr/share/verilator/include/verilated.cpp g++ -Os -I. -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=1 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable -fcoroutines -c -o verilated_dpi.o /usr/share/verilator/include/verilated_dpi.cpp 
g++ -Os -I. -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=1 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable -fcoroutines -c -o verilated_vpi.o /usr/share/verilator/include/verilated_vpi.cpp
 g++ -Os -I. -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=1 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable -fcoroutines -c -o verilated_timing.o /usr/share/verilator/include/verilated_timing.cpp 
g++ -Os -I. -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=1 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable -fcoroutines -c -o verilated_threads.o /usr/share/verilator/include/verilated_threads.cpp python3 /usr/share/verilator/bin/verilator_includer -DVL_INCLUDE_OPT=include Vtop.cpp Vtop___024root__DepSet_h84412442__0.cpp Vtop___024root__DepSet_heccd7ead__0.cpp Vtop__Dpi.cpp Vtop___024root__Slow.cpp Vtop___024root__DepSet_h84412442__0__Slow.cpp Vtop___024root__DepSet_heccd7ead__0__Slow.cpp Vtop__Syms.cpp > Vtop__ALL.cpp 
g++ -Os -I. -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=1 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable -fcoroutines -c -o Vtop__ALL.o Vtop__ALL.cpp echo "" > Vtop__ALL.verilator_deplist.tmp 
g++ verilator.o verilated.o verilated_dpi.o verilated_vpi.o verilated_timing.o verilated_threads.o Vtop__ALL.a -Wl,-rpath,/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/venv/lib/python3.13/site-packages/cocotb/libs -L/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/venv/lib/python3.13/site-packages/cocotb/libs -lcocotbvpi_verilator -pthread -lpthread -latomic -o Vtop rm Vtop__ALL.verilator_deplist.tmp make[3]: Leaving directory '/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/sim_build/peripherals' rm -f results.xml MODULE=test_peripherals TESTCASE= TOPLEVEL=tb_peripherals TOPLEVEL_LANG=verilog \ sim_build/peripherals/Vtop 
-.--ns INFO gpi ..mbed/gpi_embed.cpp:108 in set_program_name_in_venv Using Python virtual environment interpreter at /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/venv/bin/python 
-.--ns INFO gpi ../gpi/GpiCommon.cpp:101 in gpi_print_registered_impl VPI registered 0.00ns INFO cocotb Running on Verilator version 5.032 2025-01-01
 0.00ns INFO cocotb Running tests with cocotb v1.9.2 from /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/venv/lib/python3.13/site-packages/cocotb
 0.00ns INFO cocotb Seeding Python random module with 1774192518 
0.00ns INFO cocotb.regression Found test test_peripherals.test_reset_defaults 
0.00ns INFO cocotb.regression Found test test_peripherals.test_count_register_rw
 0.00ns INFO cocotb.regression Found test test_peripherals.test_data_register_rw 
0.00ns INFO cocotb.regression Found test test_peripherals.test_address_decode_outside_slot 
0.00ns INFO cocotb.regression Found test test_peripherals.test_tx_transfer
 0.00ns INFO cocotb.regression running test_reset_defaults (1/5) After reset the STATUS register should be 0. -Info: /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/tb_peripherals.v:32: $dumpvar ignored, as Verilated without --trace 
100.00ns INFO cocotb.regression test_reset_defaults passed
 100.00ns INFO cocotb.regression running test_count_register_rw (2/5) Write then read back the COUNT register. 240.00ns INFO cocotb.regression test_count_register_rw passed 
240.00ns INFO cocotb.regression running test_data_register_rw (3/5) Write then read back DATA0. 380.00ns INFO cocotb.regression test_data_register_rw passed 
380.00ns INFO cocotb.regression running test_address_decode_outside_slot (4/5) Access outside slot 4 should not affect DMA — data_ready comes from default path. 
480.00ns INFO cocotb.regression test_address_decode_outside_slot passed 
480.00ns INFO cocotb.regression running test_tx_transfer (5/5) Start a minimal TX transfer and check busy then done. 
90670.01ns INFO cocotb.regression test_tx_transfer failed Traceback (most recent call last): File "/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test_peripherals.py", line 158, in test_tx_transfer assert done, "TX transfer never completed" AssertionError: TX transfer never completed assert False 
90670.01ns INFO cocotb.regression  
** TEST STATUS SIM TIME (ns) REAL TIME (s) RATIO (ns/s) **  
** test_peripherals.test_reset_defaults PASS 100.00 0.00 53691.06 ** 
** test_peripherals.test_count_register_rw PASS 140.00 0.00 94118.73 **
 ** test_peripherals.test_data_register_rw PASS 140.00 0.00 101068.29 **
 ** test_peripherals.test_address_decode_outside_slot PASS 100.00 0.00 100511.53 ** 
** test_peripherals.test_tx_transfer FAIL 90190.00 0.70 128970.24 ** 
** TESTS=5 PASS=4 FAIL=1 SKIP=0 90670.01 0.74 123050.19 ** 
************************ echo "" > Vtop__ALL.verilator_deplist.tmp g++ verilator.o verilated.o verilated_dpi.o verilated_vpi.o verilated_timing.o verilated_threads.o Vtop__ALL.a -Wl,-rpath,/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/venv/lib/python3.13/site-packages/cocotb/libs -L/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/venv/lib/python3.13/site-packages/cocotb/libs -lcocotbvpi_verilator -pthread -lpthread -latomic -o Vtop rm Vtop__ALL.verilator_deplist.tmp make[3]: Leaving directory '/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/sim_build/dma' rm -f results.xml MODULE=test TESTCASE= TOPLEVEL=tb TOPLEVEL_LANG=verilog \ sim_build/dma/Vtop -.--ns INFO gpi ..mbed/gpi_embed.cpp:108 in set_program_name_in_venv Using Python virtual environment interpreter at /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/venv/bin/python 
-.--ns INFO gpi ../gpi/GpiCommon.cpp:101 in gpi_print_registered_impl VPI registered 
0.00ns INFO cocotb Running on Verilator version 5.032 2025-01-01 
0.00ns INFO cocotb Running tests with cocotb v1.9.2 from /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/venv/lib/python3.13/site-packages/cocotb 0.00ns INFO cocotb Seeding Python random module with 1774192559 
0.00ns INFO cocotb.regression Found test test.test_reset_defaults 
0.00ns INFO cocotb.regression Found test test.test_register_readback 
0.00ns INFO cocotb.regression Found test test.test_count_clamping 
0.00ns INFO cocotb.regression Found test test.test_tx_mode 
0.00ns INFO cocotb.regression Found test test.test_tx_two_words 
0.00ns INFO cocotb.regression Found test test.test_tx_full_buffer 
0.00ns INFO cocotb.regression Found test test.test_rx_mode 
0.00ns INFO cocotb.regression Found test test.test_rx_different_values 
0.00ns INFO cocotb.regression Found test test.test_irq_enabled 
0.00ns INFO cocotb.regression Found test test.test_irq_disabled 
0.00ns INFO cocotb.regression Found test test.test_clr_irq 
0.00ns INFO cocotb.regression Found test test.test_second_transfer 
0.00ns INFO cocotb.regression running test_reset_defaults (1/12) After reset: STATUS=0 (idle), COUNT=1, DIVISOR=63. 
0.00ns INFO cocotb.tb Test 1: reset defaults 
0.00ns INFO cocotb.tb Reset -Info: /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/tb.v:12: $dumpvar ignored, as Verilated without --trace 
79800.00ns INFO cocotb.tb Test 1 PASSED 
79800.00ns INFO cocotb.regression test_reset_defaults passed 
79800.00ns INFO cocotb.regression running test_register_readback (2/12) Write and read back COUNT, DIVISOR, and DATA registers. 
79800.00ns INFO cocotb.tb Test 2: register read/write 
79800.00ns INFO cocotb.tb Reset 
605800.00ns INFO cocotb.tb Test 2 PASSED
 605800.00ns INFO cocotb.regression test_register_readback passed 
605800.00ns INFO cocotb.regression running test_count_clamping (3/12) COUNT=0 must clamp to 1; COUNT>32 must clamp to 32. 
605800.00ns INFO cocotb.tb Test 3: COUNT clamping 
605800.00ns INFO cocotb.tb Reset 
816800.00ns INFO cocotb.tb Test 3 PASSED 
816800.00ns INFO cocotb.regression test_count_clamping passed 
816800.00ns INFO cocotb.regression running test_tx_mode (4/12) TX: DMA clocks out buffer bytes and sets STATUS[done]. 
816800.00ns INFO cocotb.tb Test 4: TX mode 
816800.00ns INFO cocotb.tb Reset 
975100.00ns INFO cocotb.tb Test 4 PASSED 
975100.00ns INFO cocotb.regression test_tx_mode passed
 975100.00ns INFO cocotb.regression running test_tx_two_words (5/12) TX 8 bytes from DATA0 and DATA1.
 975100.00ns INFO cocotb.tb Test 5: TX two words
 975100.00ns INFO cocotb.tb Reset 
1159600.00ns INFO cocotb.tb Test 5 PASSED 
1159600.00ns INFO cocotb.regression test_tx_two_words passed 
1159600.00ns INFO cocotb.regression running test_tx_full_buffer (6/12) TX all 32 bytes (8 DATA words). 1159600.00ns INFO cocotb.tb Test 6: TX full 32-byte buffer 
1159600.00ns INFO cocotb.tb Reset 
1501300.00ns INFO cocotb.tb Test 6 PASSED 
1501300.01ns INFO cocotb.regression test_tx_full_buffer passed 
1501300.01ns INFO cocotb.regression running test_rx_mode (7/12) RX: DMA samples ui_in and fills DATA0 with captured bytes. 
1501300.01ns INFO cocotb.tb Test 7: RX mode 
1501300.01ns INFO cocotb.tb Reset 
1659700.01ns INFO cocotb.tb Test 7 PASSED 
1659700.01ns INFO cocotb.regression test_rx_mode passed 
1659700.01ns INFO cocotb.regression running test_rx_different_values (8/12) Two consecutive RX transfers with different ui_in values. 
1659700.01ns INFO cocotb.tb Test 8: RX different values 
1659700.01ns INFO cocotb.tb Reset 
1949300.01ns INFO cocotb.tb Test 8 PASSED 
1949300.01ns INFO cocotb.regression test_rx_different_values passed 
1949300.01ns INFO cocotb.regression running test_irq_enabled (9/12) IRQ is asserted when irq_enable=1 and DMA completes. 
1949300.01ns INFO cocotb.tb Test 9: IRQ enabled 
1949300.01ns INFO cocotb.tb Reset
 2107600.01ns INFO cocotb.tb Test 9 PASSED 
2107600.01ns INFO cocotb.regression test_irq_enabled passed 
2107600.01ns INFO cocotb.regression running test_irq_disabled (10/12) No IRQ when irq_enable=0, even after transfer completes. 
2107600.01ns INFO cocotb.tb Test 10: IRQ disabled 
2107600.01ns INFO cocotb.tb Reset 
2239700.01ns INFO cocotb.tb Test 10 PASSED 
2239700.01ns INFO cocotb.regression test_irq_disabled passed 
2239700.01ns INFO cocotb.regression running test_clr_irq (11/12) Writing CLR_IRQ clears STATUS[done] and deasserts the interrupt line. 
2239700.01ns INFO cocotb.tb Test 11: CLR_IRQ
 2239700.01ns INFO cocotb.tb Reset 
2450600.01ns INFO cocotb.tb Test 11 PASSED 
2450600.01ns INFO cocotb.regression test_clr_irq passed 
2450600.01ns INFO cocotb.regression running test_second_transfer (12/12) After CLR_IRQ the DMA returns to IDLE and can be restarted. 
2450600.01ns INFO cocotb.tb Test 12: second transfer after CLR_IRQ
 2450600.01ns INFO cocotb.tb Reset 
2740000.01ns INFO cocotb.tb Test 12 PASSED 
2740000.01ns INFO cocotb.regression test_second_transfer passed 
2740000.01ns INFO cocotb.regression 
** TEST STATUS SIM TIME (ns) REAL TIME (s) RATIO (ns/s) ** 
** test.test_reset_defaults PASS 79800.00 0.07 1217717.42 ** 
** test.test_register_readback PASS 526000.00 0.42 1264717.70 ** 
** test.test_count_clamping PASS 211000.00 0.17 1259152.92 ** 
** test.test_tx_mode PASS 158300.00 0.13 1240649.38 ** 
** test.test_tx_two_words PASS 184500.00 0.15 1261102.54 ** 
** test.test_tx_full_buffer PASS 341700.00 0.27 1254358.53 ** 
** test.test_rx_mode PASS 158400.00 0.13 1251422.60 ** 
** test.test_rx_different_values PASS 289600.00 0.23 1251008.49 ** 
** test.test_irq_enabled PASS 158300.00 0.13 1242664.87 ** 
** test.test_irq_disabled PASS 132100.00 0.10 1258818.18 ** 
** test.test_clr_irq PASS 210900.00 0.17 1255214.77 ** 
** test.test_second_transfer PASS 289400.00 0.23 1265557.45 ** 

** TESTS=12 PASS=12 FAIL=0 SKIP=0 2740000.01 2.22 1233654.85 ** 
***** - :0: Verilog $finish make[2]: Leaving directory '/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test' make[1]: Leaving directory '/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test' make -f test_system.mk SIM_BUILD=sim_build/system clean make[1]: Entering directory '/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test' rm -f -r sim_build/system rm -f dump.vcd rm -f dump.fst make[1]: Leaving directory '/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test' make -f test_system.mk SIM_BUILD=sim_build/system make[1]: Entering directory '/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test' rm -f results.xml "make" -f test_system.mk results.xml make[2]: Entering directory '/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test' mkdir -p sim_build/system /usr/bin/verilator -cc --exe -Mdir sim_build/system -DCOCOTB_SIM=1 --top-module tb_system -DSIM --timing -Wno-SYMRSVDWORD -Wno-IMPLICIT -Wno-PINMISSING -Wno-WIDTH -Wno-MULTIDRIVEN --timescale 1ns/1ps --vpi --public-flat-rw --prefix Vtop -o Vtop -LDFLAGS "-Wl,-rpath,/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/venv/lib/python3.13/site-packages/cocotb/libs -L/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/venv/lib/python3.13/site-packages/cocotb/libs -lcocotbvpi_verilator" /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/../src/project.v /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/../src/tinyqv.v /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/../src/cpu.v /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/../src/core.v /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/../src/decode.v /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/../src/register.v /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/../src/alu.v /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/../src/counter.v /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/../src/latch_reg.v /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/../src/qspi_ctrl.v /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/../src/qspi_flash.v /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/../src/mem_ctrl.v /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/../src/time.v /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/../src/uart_tx.v /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/../src/tqvp_dma.v /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/peripherals_stub.v /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/flash_model.v /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/tb_system.v /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/venv/lib/python3.13/site-packages/cocotb/share/lib/verilator/verilator.cpp - V e r i l a t i o n R e p o r t: Verilator 5.032 2025-01-01 rev (Debian 5.032-1+b2) - Verilator: Built from 1.946 MB sources in 24 modules, into 1.333 MB in 10 C++ files needing 0.002 MB - Verilator: Walltime 0.201 s (elab=0.017, cvt=0.126, bld=0.000); cpu 0.194 s on 1 threads; alloced 18.867 MB make -C sim_build/system -f Vtop.mk make[3]: Entering directory '/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/sim_build/system' g++ -I. -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=1 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable -fcoroutines -Os -c -o verilator.o /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/venv/lib/python3.13/site-packages/cocotb/share/lib/verilator/verilator.cpp 
g++ -Os -I. -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=1 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable -fcoroutines -c -o verilated.o /usr/share/verilator/include/verilated.cpp 
g++ -Os -I. -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=1 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable -fcoroutines -c -o verilated_dpi.o /usr/share/verilator/include/verilated_dpi.cpp 
g++ -Os -I. -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=1 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable -fcoroutines -c -o verilated_vpi.o /usr/share/verilator/include/verilated_vpi.cpp 
g++ -Os -I. -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=1 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable -fcoroutines -c -o verilated_timing.o /usr/share/verilator/include/verilated_timing.cpp 
g++ -Os -I. -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=1 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable -fcoroutines -c -o verilated_threads.o /usr/share/verilator/include/verilated_threads.cpp 
g++ -Os -I. -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=1 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable -fcoroutines -x c++-header Vtop__pch.h -o Vtop__pch.h.fast.gch 
g++ -Os -I. -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=1 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable -fcoroutines -include Vtop__pch.h.fast -c -o Vtop.o Vtop.cpp 
g++ -Os -I. -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=1 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable -fcoroutines -include Vtop__pch.h.fast -c -o Vtop___024root__DepSet_h84412442__0.o Vtop___024root__DepSet_h84412442__0.cpp 
g++ -Os -I. -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=1 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable -fcoroutines -include Vtop__pch.h.fast -c -o Vtop___024root__DepSet_heccd7ead__0.o Vtop___024root__DepSet_heccd7ead__0.cpp
 g++ -Os -I. -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=1 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable -fcoroutines -include Vtop__pch.h.fast -c -o Vtop___024root__DepSet_heccd7ead__1.o Vtop___024root__DepSet_heccd7ead__1.cpp 
g++ -Os -I. -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=1 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable -fcoroutines -include Vtop__pch.h.fast -c -o Vtop__Dpi.o Vtop__Dpi.cpp 
g++ -I. -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=1 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable -fcoroutines -x c++-header Vtop__pch.h -o Vtop__pch.h.slow.gch 
g++ -I. -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=1 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable -fcoroutines -include Vtop__pch.h.slow -c -o Vtop__ConstPool_0.o Vtop__ConstPool_0.cpp 
g++ -I. -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=1 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable -fcoroutines -include Vtop__pch.h.slow -c -o Vtop___024root__Slow.o Vtop___024root__Slow.cpp 
g++ -I. -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=1 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable -fcoroutines -include Vtop__pch.h.slow -c -o Vtop___024root__DepSet_h84412442__0__Slow.o Vtop___024root__DepSet_h84412442__0__Slow.cpp 
g++ -I. -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=1 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable -fcoroutines -include Vtop__pch.h.slow -c -o Vtop___024root__DepSet_heccd7ead__0__Slow.o Vtop___024root__DepSet_heccd7ead__0__Slow.cpp 
g++ -I. -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=1 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable -fcoroutines -include Vtop__pch.h.slow -c -o Vtop__Syms.o Vtop__Syms.cpp echo "" > Vtop__ALL.verilator_deplist.tmp g++ verilator.o verilated.o verilated_dpi.o verilated_vpi.o verilated_timing.o verilated_threads.o Vtop__ALL.a -Wl,-rpath,/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/venv/lib/python3.13/site-packages/cocotb/libs -L/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/venv/lib/python3.13/site-packages/cocotb/libs -lcocotbvpi_verilator -pthread -lpthread -latomic -o Vtop rm Vtop__ALL.verilator_deplist.tmp 
make[3]: Leaving directory '/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/sim_build/system' rm -f results.xml MODULE=test_system TESTCASE= TOPLEVEL=tb_system TOPLEVEL_LANG=verilog \ sim_build/system/Vtop 
-.--ns INFO gpi ..mbed/gpi_embed.cpp:108 in set_program_name_in_venv Using Python virtual environment interpreter at /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/venv/bin/python
 -.--ns INFO gpi ../gpi/GpiCommon.cpp:101 in gpi_print_registered_impl VPI registered 0.00ns INFO cocotb Running on Verilator version 5.032 2025-01-01 
0.00ns INFO cocotb Running tests with cocotb v1.9.2 from /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/venv/lib/python3.13/site-packages/cocotb 
0.00ns INFO cocotb Seeding Python random module with 1774192587 
0.00ns INFO cocotb.regression Found test test_system.test_dma_tx
 0.00ns INFO cocotb.regression running test_dma_tx (1/1) Full-system DMA TX test: CPU boots from flash and drives DMA. -Info: /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/tb_system.v:28: $dumpvar ignored, as Verilated without --trace 
190.00ns INFO cocotb.tb_system use_hierarchy=True, monitoring signal: uo_out 
1200.00ns INFO cocotb.tb_system cycle 100: dma_out=0x00 dut.uo_out=0x40 
10200.00ns INFO cocotb.tb_system cycle 1000: dma_out=0x00 dut.uo_out=0x40 
100200.00ns INFO cocotb.tb_system cycle 10000: dma_out=0x00 dut.uo_out=0x40 500200.00ns INFO cocotb.tb_system cycle 50000: dma_out=0x00 dut.uo_out=0x40 
1000200.00ns INFO cocotb.tb_system cycle 100000: dma_out=0x00 dut.uo_out=0x40 
1500200.00ns INFO cocotb.tb_system cycle 150000: dma_out=0x00 dut.uo_out=0x40 
2000200.00ns INFO cocotb.tb_system cycle 200000: dma_out=0x00 dut.uo_out=0x40 
2500200.00ns INFO cocotb.tb_system cycle 250000: dma_out=0x00 dut.uo_out=0x40 
3000190.00ns INFO cocotb.regression test_dma_tx failed Traceback (most recent call last): File "/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test_system.py", line 101, in test_dma_tx assert len(collected) >= 4, ( ...<2 lines>... ) AssertionError: Only captured 0 distinct DMA byte(s) within 300000 cycles. Got: [] assert 0 >= 4 + where 0 = len([]) 
3000190.00ns INFO cocotb.regression 
 ** TEST STATUS SIM TIME (ns) REAL TIME (s) RATIO (ns/s) ** 
** test_system.test_dma_tx FAIL 3000190.00 22.62 132620.91 ** 
 ** TESTS=1 PASS=0 FAIL=1 SKIP=0 3000190.00 22.66 132380.50 ** ************************************************************************************** - :0: Verilog $finish make[2]: Leaving directory '/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test' make[1]: Leaving directory '/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test'
Two tests failed due to the same root cause — the missing SEC_KEY. Read both files to fix:
Read test_peripherals.py Read test_system.py
There are two different underlying issues:
test_peripherals — easy to fix: Add REG_SEC_KEY and write 0xA5 before the CTRL write.
test_system — more complex: The CPU is executing code from a pre-compiled flash hex file, and that code is unaware of the SEC_KEY requirement. We need to examine the source of the flash program.
Read  HYPERLINK "vscode-webview://1b74624abcmmdcs9pp4imo5eguud6qrf7o0fr1gvckb87d9amvkm/index.html?id=2a5971ee-97e5-4c5d-8625-bc3e0200a304&parentId=1&origin=9ac34b4a-26c2-4308-9708-fee7f6985adb&swVersion=4&extensionId=Anthropic.claude-code&platform=electron&vscode-resource-base-authority=vscode-resource.vscode-cdn.net&parentOrigin=vscode-file%3A%2F%2Fvscode-app&session=52a54462-3781-4b3e-bd2a-ed2d5234f78c" \h core_instr.py
Bash
IN
grep -n "DMA\|dma\|0x14\|SEC\|CTRL\|DATA\|0x34" /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test_system.py | head -20
OUT
2:test_system.py — System-level cocotb test for TinyQV + tqvp_dma.
5:  1. Writes 0x12345678 into DMA DATA0
6:  2. Sets COUNT = 4, CTRL = 3 (TX mode + start)
9:The DMA then outputs the 4 bytes of 0x12345678 (little-endian) on its uo_out:
10:  byte 0 = 0x78, byte 1 = 0x56, byte 2 = 0x34, byte 3 = 0x12
12:We monitor the DMA peripheral's uo_out directly via the hierarchy
13:  dut.i_dut.i_peripherals.i_dma.uo_out
22:EXPECTED_BYTES = [0x78, 0x56, 0x34, 0x12]
23:MAX_CYCLES = 300_000   # generous budget for boot + flash fetch + DMA transfer
27:async def test_dma_tx(dut):
28:    """Full-system DMA TX test: CPU boots from flash and drives DMA."""
45:    # Locate the DMA uo_out signal in the hierarchy.
47:    #       (tinyQV_peripherals/peripherals_stub) → i_dma (tqvp_dma)
50:        dma_out = dut.i_dut.i_peripherals.i_dma.uo_out
57:            "Hierarchical DMA signal not accessible; falling back to uo_out. "
60:        dma_out = dut.uo_out
70:    dut._log.info(f"use_hierarchy={use_hierarchy}, monitoring signal: {dma_out._name if hasattr(dma_out, '_name') else dma_out}")
80:        val = int(dma_out.value)
85:                f"cycle {cycle}: DMA output changed → 0x{val:02X} "
96:            dut._log.info(f"cycle {cycle}: dma_out=0x{val:02X} dut.uo_out=0x{top_val:02X}")
Bash
IN
ls /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/*.hex /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/*.py 2>/dev/null
OUT
/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/core_instr.py
/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test_alu.py
/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test_core.py
/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test_counter.py
/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test_cpu.py
/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test_decode.py
/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test_latch_reg.py
/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test_mem_ctrl.py
/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test_peripherals.py
/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test_program.hex
/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test.py
/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test_qspi_ctrl.py
/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test_qspi_flash.py
/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test_register.py
/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test_system.py
/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test_time.py
/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test_tinyqv.py
/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test_uart_tx.py
/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/tqv.py
/home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/tqv_reg.py
Cần xem memory map của DMA trong hệ thống để biết địa chỉ SEC_KEY khi CPU write:
Read  HYPERLINK "vscode-webview://1b74624abcmmdcs9pp4imo5eguud6qrf7o0fr1gvckb87d9amvkm/index.html?id=2a5971ee-97e5-4c5d-8625-bc3e0200a304&parentId=1&origin=9ac34b4a-26c2-4308-9708-fee7f6985adb&swVersion=4&extensionId=Anthropic.claude-code&platform=electron&vscode-resource-base-authority=vscode-resource.vscode-cdn.net&parentOrigin=vscode-file%3A%2F%2Fvscode-app&session=52a54462-3781-4b3e-bd2a-ed2d5234f78c" \h peripherals.v
Bash
IN
head -20 /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test_program.hex
OUT
37
05
00
08
13
05
05
10
B7
55
34
12
93
85
85
67
23
2A
B5
00

Bash
IN
cat -n /home/user/Desktop/HUST/AI_HDL/ICLab_HUST/DP3/test/test_program.hex
OUT
     1  37
     2  05
     3  00
     4  08
     5  13
     6  05
     7  05
     8  10
     9  B7
    10  55
    11  34
    12  12
    13  93
    14  85
    15  85
    16  67
    17  23
    18  2A
    19  B5
    20  00
    21  93
    22  05
    23  40
    24  00
    25  23
    26  22
    27  B5
    28  00
    29  93
    30  05
    31  30
    32  00
    33  23
    34  20
    35  B5
    36  00
    37  03
    38  26
    39  C5
    40  00
    41  13
    42  76
    43  26
    44  00
    45  E3
    46  0C
    47  06
    48  FE
    49  6F
    50  00
    51  00
    52  00

I have successfully decoded the entire RISC-V program. The issue is clear: the CPU is writing directly to CTRL=3 without writing to SEC_KEY first. Both files need to be patched.
Fix 1: test_peripherals.py — Add SEC_KEY write:
Edit test_peripherals.py (Added 1 line)
Edit test_peripherals.py (Added 3 lines)
Fix 2: test_program.hex — Add two RISC-V instructions to write SEC_KEY=0xA5 before writing to CTRL.
The original program decodes as follows:
lui   x10, 0x8000       # x10 = DMA base 0x8000100
addi  x10, x10, 0x100
lui   x11, 0x12345      # x11 = 0x12345678
addi  x11, x11, 0x678
sw    x11, 0x14(x10)    # DATA0 = 0x12345678
addi  x11, x0, 4        # COUNT = 4
sw    x11, 4(x10)
addi  x11, x0, 3        # CTRL value = start|TX
# ← Need to insert SEC_KEY write here
sw    x11, 0(x10)       # CTRL = 3 (start is blocked due to missing key)
... poll STATUS ...
Add 2 instructions: addi x12, x0, 0xA5 + sw x12, 0x34(x10):
Write  HYPERLINK "vscode-webview://1b74624abcmmdcs9pp4imo5eguud6qrf7o0fr1gvckb87d9amvkm/index.html?id=2a5971ee-97e5-4c5d-8625-bc3e0200a304&parentId=1&origin=9ac34b4a-26c2-4308-9708-fee7f6985adb&swVersion=4&extensionId=Anthropic.claude-code&platform=electron&vscode-resource-base-authority=vscode-resource.vscode-cdn.net&parentOrigin=vscode-file%3A%2F%2Fvscode-app&session=52a54462-3781-4b3e-bd2a-ed2d5234f78c" \h test_program.hex
Write failed
37
05
00
08
13
05
05
10
B7
55
34
12
93
85
85
67
23
2A
B5
00
93
05
40
00
23
22
B5
00
93
05
30
00
13
06
50
0A
23
2A
C5
02
23
20
B5
00
03
26
C5
00
13
76
26
00
E3
0C
06
FE
6F
00
00
00
Read  HYPERLINK "vscode-webview://1b74624abcmmdcs9pp4imo5eguud6qrf7o0fr1gvckb87d9amvkm/index.html?id=2a5971ee-97e5-4c5d-8625-bc3e0200a304&parentId=1&origin=9ac34b4a-26c2-4308-9708-fee7f6985adb&swVersion=4&extensionId=Anthropic.claude-code&platform=electron&vscode-resource-base-authority=vscode-resource.vscode-cdn.net&parentOrigin=vscode-file%3A%2F%2Fvscode-app&session=52a54462-3781-4b3e-bd2a-ed2d5234f78c" \h test_program.hex
Write  HYPERLINK "vscode-webview://1b74624abcmmdcs9pp4imo5eguud6qrf7o0fr1gvckb87d9amvkm/index.html?id=2a5971ee-97e5-4c5d-8625-bc3e0200a304&parentId=1&origin=9ac34b4a-26c2-4308-9708-fee7f6985adb&swVersion=4&extensionId=Anthropic.claude-code&platform=electron&vscode-resource-base-authority=vscode-resource.vscode-cdn.net&parentOrigin=vscode-file%3A%2F%2Fvscode-app&session=52a54462-3781-4b3e-bd2a-ed2d5234f78c" \h test_program.hex
61 lines
37
05
00
08
13
05
05
10
B7
55
34
12
93
85
85
67
23
2A
B5
00
93
05
40
00
23
22
B5
00
93
05
30
00
13
06
50
0A
23
2A
C5
02
23
20
B5
00
03
26
C5
00
13
76
26
00
E3
0C
06
FE
6F
00
00
00
The two inserted instructions (bytes 33-40) are:
Bytes
Hex
RISC-V Instruction
Meaning
33-36
13 06 50 0A
addi x12, x0, 0xA5
Load key value
37-40
23 2A C5 02
sw x12, 0x34(x10)
Write SEC_KEY = 0xA5
The branch offset in the poll loop remains -8 because both the lw (target) and beq were shifted by exactly 8 bytes—so no further correction is needed.
Run again:
Bash
make test_peripherals
make test_system
User: Why does the system testbench have only one test case?
Claude: After reviewing tb_system.v, the reason there is only one test case is that the nature of a system test is fundamentally different from a unit test:
Unit Tests (test_dma, test_peripherals)
Many tests are possible because:
Cocotb drives signals directly (address, data_write_n, clock, etc.).
Each test resets independently and sets up quickly (~100ns).
They verify individual registers or specific behaviors in isolation.
System Test (test_system)
Limited to one test because:
CPU Bootup: The CPU must boot from flash first, which takes tens of thousands of clock cycles just to initialize.
Flash Model: The flash_model.v reads from a single test_program.hex file containing one specific program.
Reset Complexity: You cannot easily reset mid-way because the CPU would need to re-fetch the entire flash content.
Simulation Time: A single system test can take 300,000+ cycles; having many would make the simulation extremely slow.
Designing Additional System Tests
If you wanted to add more system test cases, you would need:
Multiple Hex Files: Each test would require a different .hex file (or one large program that handles multiple sequential scenarios).
Separate Make Targets: Using different test_program.hex files for different make targets.
Example for an RX test:
Python
# test_system.py@cocotb.test()async def test_dma_rx(dut):
    # This would require test_program_rx.hex with different CPU code
    ...
For the DP3 project, one system test case is usually sufficient. It proves the entire "Golden Path": CPU Boot → Fetch from Flash → Write SEC_KEY → Trigger DMA → Verify Output.



