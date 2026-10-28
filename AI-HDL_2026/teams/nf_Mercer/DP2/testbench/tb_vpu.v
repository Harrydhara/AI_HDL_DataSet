`default_nettype none
`timescale 1ns/1ps
// ---------------------------------------------------------------------------
// tb_vpu  —  Testbench for vpu.v
//
// Tests covered:
//   1.  Basic dot product correctness (MMIO mode)
//   2.  Pipeline timing — done asserts exactly cycle+2 after start
//   3.  Zero input vector → result = 0
//   4.  Zero weights      → result = 0
//   5.  Clear bit resets result register
//   6.  Direct mode (use_direct=1)
//   7.  Reset mid-operation
//   8.  A/B register readback
//   9.  Large values (32-bit truncation)
//  10.  Back-to-back operations (no idle gap)
//
// Run with:
//   iverilog -o tb_vpu tb_vpu.v vpu.v pe_macc.v && vvp tb_vpu
// ---------------------------------------------------------------------------
module tb_vpu;

    // DUT signals
    reg         clk, rst_n;
    reg         cs, we;
    reg  [3:0]  addr;
    reg  [31:0] wdata;
    wire [31:0] rdata;

    reg         use_direct;
    reg  [31:0] a_direct_0, a_direct_1, a_direct_2, a_direct_3;
    reg  [31:0] b_direct_0, b_direct_1, b_direct_2, b_direct_3;
    reg         start_direct;
    wire [31:0] result_direct;
    wire        done_direct;

    // DUT instantiation
    vpu dut (
        .clk          (clk),
        .rst_n        (rst_n),
        .cs           (cs),
        .we           (we),
        .addr         (addr),
        .wdata        (wdata),
        .rdata        (rdata),
        .use_direct   (use_direct),
        .a_direct_0   (a_direct_0),
        .a_direct_1   (a_direct_1),
        .a_direct_2   (a_direct_2),
        .a_direct_3   (a_direct_3),
        .b_direct_0   (b_direct_0),
        .b_direct_1   (b_direct_1),
        .b_direct_2   (b_direct_2),
        .b_direct_3   (b_direct_3),
        .start_direct (start_direct),
        .result_direct(result_direct),
        .done_direct  (done_direct)
    );

    // Clock: 10 ns period
    initial clk = 0;
    always #5 clk = ~clk;

    // Test tracking — global and per-test counters
    integer pass_count, fail_count;
    integer test_pass,  test_fail;
    integer test_num;

    // Begin / end a named test group
    task begin_test;
        input [255:0] name;
        begin
            test_pass = 0;
            test_fail = 0;
            test_num  = test_num + 1;
            $display("");
            $display("===========================================================");
            $display("  TEST %0d: %s", test_num, name);
            $display("===========================================================");
        end
    endtask

    task end_test;
        begin
            $display("-----------------------------------------------------------");
            if (test_fail == 0)
                $display("  TEST %0d RESULT: PASS  (%0d checks)", test_num, test_pass);
            else
                $display("  TEST %0d RESULT: FAIL  (%0d passed, %0d failed)",
                         test_num, test_pass, test_fail);
            $display("-----------------------------------------------------------");
        end
    endtask

    // check — compare 32-bit values, display hex + decimal
    task check;
        input [255:0] name;
        input [31:0]  got;
        input [31:0]  expected;
        begin
            if (got === expected) begin
                $display("  [ PASS ]  %-32s  got 0x%08h (%0d)",
                         name, got, got);
                pass_count = pass_count + 1;
                test_pass  = test_pass  + 1;
            end else begin
                $display("  [ FAIL ]  %-32s  expected 0x%08h (%0d)  |  got 0x%08h (%0d)",
                         name, expected, expected, got, got);
                fail_count = fail_count + 1;
                test_fail  = test_fail  + 1;
            end
        end
    endtask

    // check_bit — compare single-bit values
    task check_bit;
        input [255:0] name;
        input         got;
        input         expected;
        begin
            if (got === expected) begin
                $display("  [ PASS ]  %-32s  got %0b", name, got);
                pass_count = pass_count + 1;
                test_pass  = test_pass  + 1;
            end else begin
                $display("  [ FAIL ]  %-32s  expected %0b  |  got %0b",
                         name, expected, got);
                fail_count = fail_count + 1;
                test_fail  = test_fail  + 1;
            end
        end
    endtask

    // MMIO helpers
    task mmio_write;
        input [3:0]  a;
        input [31:0] d;
        begin
            @(negedge clk);
            cs = 1; we = 1; addr = a; wdata = d;
            @(posedge clk); #1;
            cs = 0; we = 0;
        end
    endtask

    task mmio_read;
        input  [3:0]  a;
        output [31:0] d;
        begin
            @(negedge clk);
            cs = 1; we = 0; addr = a;
            @(posedge clk); #1;
            d = rdata;
            cs = 0;
        end
    endtask

    task reset_dut;
        begin
            rst_n        = 0;
            cs           = 0; we = 0; addr = 0; wdata = 0;
            use_direct   = 0;
            a_direct_0   = 0; a_direct_1   = 0;
            a_direct_2   = 0; a_direct_3   = 0;
            b_direct_0   = 0; b_direct_1   = 0;
            b_direct_2   = 0; b_direct_3   = 0;
            start_direct = 0;
            repeat(3) @(posedge clk);
            rst_n = 1;
            @(posedge clk);
        end
    endtask

    // Load all 8 operand registers in one call
    task load_ab;
        input [31:0] a0, a1, a2, a3;
        input [31:0] b0, b1, b2, b3;
        begin
            mmio_write(4'h0, a0);
            mmio_write(4'h1, a1);
            mmio_write(4'h2, a2);
            mmio_write(4'h3, a3);
            mmio_write(4'h4, b0);
            mmio_write(4'h5, b1);
            mmio_write(4'h6, b2);
            mmio_write(4'h7, b3);
        end
    endtask

    task fire_and_wait;
        begin
            mmio_write(4'h9, 32'd1);        // start
            repeat(3) @(posedge clk); #1;   // 2-cycle pipeline + 1 margin
        end
    endtask

    reg [31:0] rd;

    // MAIN TEST SEQUENCE
    initial begin
        pass_count = 0;
        fail_count = 0;
        test_num   = 0;

        $dumpfile("tb_vpu.vcd");
        $dumpvars(0, tb_vpu);

        // ===================================================================
        // TEST 1: Basic dot product — MMIO mode
        // A=[1,2,3,4]  B=[5,6,7,8]
        // result = 1·5 + 2·6 + 3·7 + 4·8 = 5+12+21+32 = 70
        // ===================================================================
        begin_test("Basic dot product (MMIO mode)");
        reset_dut;

        $display("  A = [1, 2, 3, 4]   B = [5, 6, 7, 8]");
        $display("  Expected: 1*5 + 2*6 + 3*7 + 4*8 = 5+12+21+32 = 70");
        $display("");

        load_ab(32'd1, 32'd2, 32'd3, 32'd4,
                32'd5, 32'd6, 32'd7, 32'd8);
        fire_and_wait;
        mmio_read(4'h8, rd);
        check("dot([1,2,3,4],[5,6,7,8])", rd, 32'd70);
        end_test;

        // ===================================================================
        // TEST 2: Pipeline timing
        // done must be 0 before start, 0 at cycle+1, 1 at cycle+2, 0 at +3
        // ===================================================================
        begin_test("Pipeline timing (done at cycle+2)");
        reset_dut;

        $display("  A=B=[1,1,1,1].  start pulsed at cycle 0.");
        $display("  Expect: done=0 before start, done=0 at cyc+1,");
        $display("          done=1 at cyc+2, done=0 at cyc+3 (self-cleared)");
        $display("");

        load_ab(32'd1, 32'd1, 32'd1, 32'd1,
                32'd1, 32'd1, 32'd1, 32'd1);

        #1;
        check_bit("done before start   (exp 0)", dut.done, 1'b0);

        // Pulse start — registers on next posedge (cycle 0)
        @(negedge clk);
        cs = 1; we = 1; addr = 4'h9; wdata = 32'd1;
        @(posedge clk); #1;
        cs = 0; we = 0;

        @(posedge clk); #1;
        check_bit("done at cycle+1     (exp 0)", dut.done, 1'b0);

        @(posedge clk); #1;
        check_bit("done at cycle+2     (exp 1)", dut.done, 1'b1);

        @(posedge clk); #1;
        check_bit("done at cycle+3     (exp 0)", dut.done, 1'b0);
        end_test;

        // ===================================================================
        // TEST 3: Zero input vector
        // A=[0,0,0,0]  B=[5,6,7,8]  → result = 0
        // ===================================================================
        begin_test("Zero input vector -> result = 0");
        reset_dut;

        $display("  A = [0, 0, 0, 0]   B = [5, 6, 7, 8]");
        $display("  Expected: 0");
        $display("");

        load_ab(32'd0, 32'd0, 32'd0, 32'd0,
                32'd5, 32'd6, 32'd7, 32'd8);
        fire_and_wait;
        mmio_read(4'h8, rd);
        check("dot([0,0,0,0],[5,6,7,8])", rd, 32'd0);
        end_test;

        // ===================================================================
        // TEST 4: Zero weights
        // A=[1,2,3,4]  B=[0,0,0,0]  → result = 0
        // ===================================================================
        begin_test("Zero weights -> result = 0");
        reset_dut;

        $display("  A = [1, 2, 3, 4]   B = [0, 0, 0, 0]");
        $display("  Expected: 0");
        $display("");

        load_ab(32'd1, 32'd2, 32'd3, 32'd4,
                32'd0, 32'd0, 32'd0, 32'd0);
        fire_and_wait;
        mmio_read(4'h8, rd);
        check("dot([1,2,3,4],[0,0,0,0])", rd, 32'd0);
        end_test;

        // ===================================================================
        // TEST 5: Clear bit resets result register
        // ===================================================================
        begin_test("Clear bit (ctrl bit 1) resets result");
        reset_dut;

        $display("  A=B=[10,10,10,10]  →  result = 400,  then write clear.");
        $display("  Expected result after clear: 0");
        $display("");

        load_ab(32'd10, 32'd10, 32'd10, 32'd10,
                32'd10, 32'd10, 32'd10, 32'd10);
        fire_and_wait;
        mmio_read(4'h8, rd);
        check("result before clear (exp 400)", rd, 32'd400);

        mmio_write(4'h9, 32'd2);   // bit1 = clear
        @(posedge clk); #1;
        mmio_read(4'h8, rd);
        check("result after clear  (exp   0)", rd, 32'd0);
        end_test;

        // ===================================================================
        // TEST 6: Direct mode (use_direct=1)
        // A=B=[3,3,3,3]  → result = 3·3·4 = 36
        // ===================================================================
        begin_test("Direct mode (use_direct=1)");
        reset_dut;

        $display("  A = B = [3, 3, 3, 3]  via direct ports.");
        $display("  Expected result_direct = 36,  done_direct at cycle+2");
        $display("");

        use_direct   = 1;
        a_direct_0   = 32'd3; a_direct_1 = 32'd3;
        a_direct_2   = 32'd3; a_direct_3 = 32'd3;
        b_direct_0   = 32'd3; b_direct_1 = 32'd3;
        b_direct_2   = 32'd3; b_direct_3 = 32'd3;
        start_direct = 1;
        @(posedge clk); #1;
        start_direct = 0;

        check_bit("done_direct at cycle+1 (exp 0)", done_direct, 1'b0);

        @(posedge clk); #1;
        check_bit("done_direct at cycle+2 (exp 1)", done_direct, 1'b1);
        check("result_direct [3,3,3,3]·[3,3,3,3]", result_direct, 32'd36);

        use_direct = 0;
        end_test;

        // ===================================================================
        // TEST 7: Reset mid-operation
        // Start a computation, assert rst_n=0 before done, verify clean state
        // ===================================================================
        begin_test("Reset mid-operation");
        reset_dut;

        $display("  A=B=[9,9,9,9].  Assert rst_n=0 one cycle after start.");
        $display("  After release: result=0, done=0.");
        $display("");

        load_ab(32'd9, 32'd9, 32'd9, 32'd9,
                32'd9, 32'd9, 32'd9, 32'd9);
        mmio_write(4'h9, 32'd1);   // start

        @(posedge clk); #1;
        rst_n = 0;
        @(posedge clk); #1;
        rst_n = 1;
        @(posedge clk); #1;

        mmio_read(4'h8, rd);
        check("result after mid-op reset (exp 0)", rd, 32'd0);
        mmio_read(4'hA, rd);
        check_bit("done   after mid-op reset (exp 0)", rd[0], 1'b0);
        end_test;

        // ===================================================================
        // TEST 8: A/B register readback
        // ===================================================================
        begin_test("A and B register readback");
        reset_dut;

        $display("  Write distinct patterns to each register then read back.");
        $display("");

        mmio_write(4'h0, 32'hDEAD0000);
        mmio_write(4'h1, 32'hBEEF0001);
        mmio_write(4'h2, 32'hCAFE0002);
        mmio_write(4'h3, 32'hFACE0003);
        mmio_write(4'h4, 32'h11110004);
        mmio_write(4'h5, 32'h22220005);
        mmio_write(4'h6, 32'h33330006);
        mmio_write(4'h7, 32'h44440007);

        mmio_read(4'h0, rd); check("A0 readback", rd, 32'hDEAD0000);
        mmio_read(4'h1, rd); check("A1 readback", rd, 32'hBEEF0001);
        mmio_read(4'h2, rd); check("A2 readback", rd, 32'hCAFE0002);
        mmio_read(4'h3, rd); check("A3 readback", rd, 32'hFACE0003);
        mmio_read(4'h4, rd); check("B0 readback", rd, 32'h11110004);
        mmio_read(4'h5, rd); check("B1 readback", rd, 32'h22220005);
        mmio_read(4'h6, rd); check("B2 readback", rd, 32'h33330006);
        mmio_read(4'h7, rd); check("B3 readback", rd, 32'h44440007);
        end_test;

        // ===================================================================
        // TEST 9: Large values — 32-bit truncation
        // A=[0xFFFF,0,0,0]  B=[0xFFFF,0,0,0]
        // 0xFFFF * 0xFFFF = 0xFFFE0001
        // ===================================================================
        begin_test("Large values (32-bit truncation)");
        reset_dut;

        $display("  A = [0x0000FFFF, 0, 0, 0]   B = [0x0000FFFF, 0, 0, 0]");
        $display("  0xFFFF * 0xFFFF = 0xFFFE0001 (65535^2, fits in 32 bits)");
        $display("");

        load_ab(32'h0000FFFF, 32'd0, 32'd0, 32'd0,
                32'h0000FFFF, 32'd0, 32'd0, 32'd0);
        fire_and_wait;
        mmio_read(4'h8, rd);
        check("0xFFFF * 0xFFFF", rd, 32'hFFFE0001);
        end_test;

        // ===================================================================
        // TEST 10: Back-to-back operations (no idle gap)
        // Op1: A=B=[1,1,1,1] → 4
        // Op2: A=B=[2,2,2,2] → 16
        // ===================================================================
        begin_test("Back-to-back operations (no idle gap)");
        reset_dut;

        $display("  Op1: A=B=[1,1,1,1]  ->  expected 4");
        $display("  Op2: A=B=[2,2,2,2]  ->  expected 16  (immediate)");
        $display("");

        // Op1
        load_ab(32'd1, 32'd1, 32'd1, 32'd1,
                32'd1, 32'd1, 32'd1, 32'd1);
        mmio_write(4'h9, 32'd1);
        repeat(2) @(posedge clk); #1;
        mmio_read(4'h8, rd);
        check("op1 result (exp  4)", rd, 32'd4);

        // Op2 — load and fire immediately with no extra idle
        load_ab(32'd2, 32'd2, 32'd2, 32'd2,
                32'd2, 32'd2, 32'd2, 32'd2);
        mmio_write(4'h9, 32'd1);
        repeat(2) @(posedge clk); #1;
        mmio_read(4'h8, rd);
        check("op2 result (exp 16)", rd, 32'd16);
        end_test;

        // ===================================================================
        // FINAL SUMMARY
        // ===================================================================
        $display("");
        $display("###########################################################");
        $display("#                 VPU TESTBENCH SUMMARY                   #");
        $display("###########################################################");
        $display("#  Total checks :  %3d                                    #", pass_count + fail_count);
        $display("#  PASSED       :  %3d                                    #", pass_count);
        $display("#  FAILED       :  %3d                                    #", fail_count);
        $display("###########################################################");
        if (fail_count == 0)
            $display("#              >>> ALL TESTS PASSED <<<                   #");
        else
            $display("#              *** SOME TESTS FAILED ***                  #");
        $display("###########################################################");
        $display("");

        $finish;
    end

    // Timeout watchdog
    initial begin
        #20000;
        $display("TIMEOUT — testbench hung");
        $finish;
    end

endmodule
