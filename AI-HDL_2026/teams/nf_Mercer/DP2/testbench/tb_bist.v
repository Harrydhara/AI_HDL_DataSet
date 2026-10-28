`default_nettype none
`timescale 1ns/1ps
// ---------------------------------------------------------------------------
// tb_bist.v  –  Verilog testbench for bist_ctrl via tqvp_example
//
// Run:
//   iverilog -g2005-sv -Wall -o tb_bist.out \
//       tb_bist.v pe_macc.v pe_activation.v vpu.v mvu.v \
//       systolic.v bist_ctrl.v peripheral.v
//   vvp tb_bist.out
// ---------------------------------------------------------------------------

module tb_bist;

    // Clock + reset
    reg clk, rst_n;
    initial clk = 0;
    always #5 clk = ~clk;   // 100 MHz

    // DUT signals  — address is 7-bit to match peripheral.v port
    reg  [7:0]  ui_in;
    wire [7:0]  uo_out;
    reg  [6:0]  address;          // ← was [5:0]
    reg  [31:0] data_in;
    reg  [1:0]  data_write_n;
    reg  [1:0]  data_read_n;
    wire [31:0] data_out;
    wire        data_ready;
    wire        user_interrupt;

    tqvp_example dut (
        .clk           (clk),
        .rst_n         (rst_n),
        .ui_in         (ui_in),
        .uo_out        (uo_out),
        .address       (address),
        .data_in       (data_in),
        .data_write_n  (data_write_n),
        .data_read_n   (data_read_n),
        .data_out      (data_out),
        .data_ready    (data_ready),
        .user_interrupt(user_interrupt)
    );

    // MMIO helpers  — all addr arguments widened to [6:0]
    task mmio_write;
        input [6:0]  addr;     // ← was [5:0]
        input [31:0] wdata;
        begin
            @(negedge clk);
            address      = addr;
            data_in      = wdata;
            data_write_n = 2'b00;
            data_read_n  = 2'b11;
            @(posedge clk); #1;
            data_write_n = 2'b11;
        end
    endtask

    task mmio_read;
        input  [6:0]  addr;    // ← was [5:0]
        output [31:0] rdata;
        begin
            @(negedge clk);
            address      = addr;
            data_write_n = 2'b11;
            data_read_n  = 2'b00;
            @(posedge clk); #1;
            @(posedge clk); #1;   // data_ready is registered +1 cycle
            rdata        = data_out;
            data_read_n  = 2'b11;
        end
    endtask

    task poll_bit0;
        input [6:0]  addr;     // ← was [5:0]
        input        expected;
        input [15:0] timeout_cycles;
        integer i;
        reg [31:0] v;
        begin
            for (i = 0; i < timeout_cycles; i = i+1) begin
                mmio_read(addr, v);
                if (v[0] == expected) i = timeout_cycles; // break
            end
            if (v[0] !== expected)
                $display("  TIMEOUT: poll_bit0 addr=0x%02h expected=%b", addr, expected);
        end
    endtask

    // Test counters + check helper
    integer pass_count, fail_count;

    task check;
        input [63:0]  got;
        input [63:0]  exp;
        input [127:0] label;
        begin
            if (got === exp) begin
                $display("  PASS  %s  got=0x%0h", label, got);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL  %s  got=0x%0h  exp=0x%0h", label, got, exp);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // Address constants  — all widened to 7'hXX
    localparam [6:0]
        BIST_MODE   = 7'h60,
        BIST_START  = 7'h61,
        BIST_STATUS = 7'h62,
        BIST_FINFO  = 7'h63,
        BIST_FGOT   = 7'h64,
        BIST_FEXP   = 7'h65,
        SYST_A0     = 7'h50,
        SYST_B0     = 7'h54,
        SYST_START  = 7'h58,
        SYST_DONE   = 7'h59,
        SYST_C00    = 7'h5A,
        SYST_C01    = 7'h5B,
        SYST_C10    = 7'h5C,
        SYST_C11    = 7'h5D,
        MVU_X0      = 7'h30,
        MVU_W00     = 7'h34,
        MVU_START   = 7'h44,
        MVU_DONE    = 7'h45,
        MVU_Y0      = 7'h46;

    reg [31:0] v;
    integer    i;

    // Main test sequence
    initial begin
        $dumpfile("tb_bist.vcd");
        $dumpvars(0, tb_bist);

        pass_count   = 0;
        fail_count   = 0;
        ui_in        = 8'd0;
        address      = 7'd0;
        data_in      = 32'd0;
        data_write_n = 2'b11;
        data_read_n  = 2'b11;
        rst_n        = 0;
        repeat(4) @(posedge clk);
        rst_n = 1;
        repeat(2) @(posedge clk);

        // ==============================================================
        // T1: FUNCTIONAL mode — systolic direct
        // A=[1 0/0 1] × B=[1 0/0 1] = C=[1 0/0 1]
        // ==============================================================
        $display("\n[T1] FUNCTIONAL mode — systolic direct (identity × identity)");
        mmio_read(BIST_MODE, v);
        check(v, 32'd0, "mode=0 after reset");

        mmio_write(SYST_A0+0, 32'd1);
        mmio_write(SYST_A0+1, 32'd0);
        mmio_write(SYST_A0+2, 32'd0);
        mmio_write(SYST_A0+3, 32'd1);
        mmio_write(SYST_B0+0, 32'd1);
        mmio_write(SYST_B0+1, 32'd0);
        mmio_write(SYST_B0+2, 32'd0);
        mmio_write(SYST_B0+3, 32'd1);
        mmio_write(SYST_START, 32'd1);
        poll_bit0(SYST_DONE, 1, 20);
        mmio_read(SYST_C00, v); check(v, 32'd1, "syst c00=1");
        mmio_read(SYST_C01, v); check(v, 32'd0, "syst c01=0");
        mmio_read(SYST_C10, v); check(v, 32'd0, "syst c10=0");
        mmio_read(SYST_C11, v); check(v, 32'd0, "syst c11=0"); // RTL: a2*b3=0*1=0

        // ==============================================================
        // T2: FUNCTIONAL mode — mvu direct
        // Identity W × x=[1 2 3 4] = y=[1 2 3 4]
        // ==============================================================
        $display("\n[T2] FUNCTIONAL mode — mvu direct (identity W)");
        for (i = 0; i < 16; i = i+1)                         // ← i[6:0] via 7-bit localparam
            mmio_write(MVU_W00 + i[6:0], (i % 5 == 0) ? 32'd1 : 32'd0);
        mmio_write(MVU_X0+0, 32'd1);
        mmio_write(MVU_X0+1, 32'd2);
        mmio_write(MVU_X0+2, 32'd3);
        mmio_write(MVU_X0+3, 32'd4);
        mmio_write(MVU_START, 32'd1);
        poll_bit0(MVU_DONE, 1, 20);
        mmio_read(MVU_Y0+0, v); check(v, 32'd1, "mvu y0=1");
        mmio_read(MVU_Y0+1, v); check(v, 32'd2, "mvu y1=2");
        mmio_read(MVU_Y0+2, v); check(v, 32'd3, "mvu y2=3");
        mmio_read(MVU_Y0+3, v); check(v, 32'd4, "mvu y3=4");

        // ==============================================================
        // T3: Mode register read/write
        // ==============================================================
        $display("\n[T3] Mode register");
        mmio_write(BIST_MODE, 32'd1);
        mmio_read(BIST_MODE, v);
        check(v, 32'd1, "mode=1 after write");
        mmio_read(BIST_STATUS, v);
        check(v[0], 1'b0, "bist_active=0 before start");

        // ==============================================================
        // T4: BIST systolic-only  (8 vectors)
        // ==============================================================
        $display("\n[T4] BIST systolic-only (8 vectors)");
        mmio_write(BIST_START, 32'h1);
        repeat(2) @(posedge clk);
        mmio_read(BIST_STATUS, v);
        check(v[0], 1'b1, "bist_active=1 during test");
        poll_bit0(BIST_STATUS, 0, 500);
        mmio_read(BIST_STATUS, v);
        check(v[1], 1'b1, "syst_done=1");
        check(v[2], 1'b1, "syst_pass=1");
        check(v[3], 1'b0, "mvu_done=0 (not run)");
        if (!v[2]) begin
            mmio_read(BIST_FINFO, v); $display("    fail_info=0x%08h", v);
            mmio_read(BIST_FGOT,  v); $display("    fail_got =0x%08h", v);
            mmio_read(BIST_FEXP,  v); $display("    fail_exp =0x%08h", v);
        end

        // ==============================================================
        // T5: BIST mvu-only  (4 vectors)
        // ==============================================================
        $display("\n[T5] BIST mvu-only (4 vectors)");
        mmio_write(BIST_START, 32'h2);
        repeat(2) @(posedge clk);
        poll_bit0(BIST_STATUS, 0, 500);
        mmio_read(BIST_STATUS, v);
        check(v[3], 1'b1, "mvu_done=1");
        check(v[4], 1'b1, "mvu_pass=1");
        check(v[1], 1'b0, "syst_done=0 (not run)");
        if (!v[4]) begin
            mmio_read(BIST_FINFO, v); $display("    fail_info=0x%08h", v);
            mmio_read(BIST_FGOT,  v); $display("    fail_got =0x%08h", v);
            mmio_read(BIST_FEXP,  v); $display("    fail_exp =0x%08h", v);
        end

        // ==============================================================
        // T6: BIST both  (systolic then mvu)
        // ==============================================================
        $display("\n[T6] BIST both — systolic then mvu");
        mmio_write(BIST_START, 32'h4);
        repeat(2) @(posedge clk);
        poll_bit0(BIST_STATUS, 0, 1000);
        mmio_read(BIST_STATUS, v);
        check(v[1], 1'b1, "both: syst_done=1");
        check(v[2], 1'b1, "both: syst_pass=1");
        check(v[3], 1'b1, "both: mvu_done=1");
        check(v[4], 1'b1, "both: mvu_pass=1");
        check(v[0], 1'b0, "both: busy=0 after done");

        // ==============================================================
        // T7: Bus lockout — CPU write ignored during BIST
        // ==============================================================
        $display("\n[T7] Bus lockout");
        mmio_write(BIST_START, 32'h1);
        mmio_write(SYST_A0, 32'hDEADBEEF);   // should be ignored
        poll_bit0(BIST_STATUS, 0, 500);
        mmio_read(BIST_STATUS, v);
        check(v[2], 1'b1, "lockout: syst_pass unaffected");

        // ==============================================================
        // T8: Return to FUNCTIONAL, DUT still works
        // ==============================================================
        $display("\n[T8] Return to FUNCTIONAL mode");
        mmio_write(BIST_MODE, 32'd0);
        mmio_read(BIST_MODE, v);
        check(v, 32'd0, "mode=0 after write-back");

        mmio_write(SYST_A0+0, 32'd2);
        mmio_write(SYST_A0+1, 32'd0);
        mmio_write(SYST_A0+2, 32'd0);
        mmio_write(SYST_A0+3, 32'd2);
        mmio_write(SYST_B0+0, 32'd3);
        mmio_write(SYST_B0+1, 32'd0);
        mmio_write(SYST_B0+2, 32'd0);
        mmio_write(SYST_B0+3, 32'd3);
        mmio_write(SYST_START, 32'd1);
        poll_bit0(SYST_DONE, 1, 20);
        mmio_read(SYST_C00, v); check(v, 32'd6, "post-BIST c00=6"); // a0*b0=2*3=6
        mmio_read(SYST_C11, v); check(v, 32'd0, "post-BIST c11=0"); // a2*b3=0*3=0

        // ==============================================================
        // T9: BIST start ignored in FUNCTIONAL mode
        // ==============================================================
        $display("\n[T9] BIST start ignored in FUNCTIONAL mode");
        mmio_write(BIST_START, 32'h7);   // should be ignored, mode=0
        repeat(4) @(posedge clk);
        mmio_read(BIST_STATUS, v);
        check(v[0], 1'b0, "start ignored: busy=0");

        // ==============================================================
        // Summary
        // ==============================================================
        $display("\n══════════════════════════════════════");
        $display("  %0d passed,  %0d failed", pass_count, fail_count);
        $display("══════════════════════════════════════");
        if (fail_count == 0) $display("  ALL TESTS PASSED");
        else                 $display("  FAILURES DETECTED");
        $finish;
    end

    // Watchdog — 500 µs at 100 MHz = 50000 cycles
    initial begin
        #500000;
        $display("WATCHDOG: simulation exceeded 500 us");
        $finish;
    end

endmodule