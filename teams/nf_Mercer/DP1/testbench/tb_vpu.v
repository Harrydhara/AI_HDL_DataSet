`default_nettype none
`timescale 1ns/1ps
// ---------------------------------------------------------------------------
// tb_vpu  —  Testbench for vpu.v
//
// Tests covered:
//   1. Basic dot product correctness (known values, MMIO mode)
//   2. Pipeline timing — done asserts exactly cycle 2 after start
//   3. Zero input edge case
//   4. Zero weights edge case
//   5. MMIO standalone mode (use_direct=0)
//   6. Direct mode (use_direct=1)
//   7. Reset behavior (mid-operation reset)
//   8. Clear bit behavior (ctrl bit 1)
//
// Run with: iverilog -o tb_vpu tb_vpu.v vpu.v pe_macc.v && vvp tb_vpu
// ---------------------------------------------------------------------------
module tb_vpu;

    // -----------------------------------------------------------------------
    // DUT signals
    // -----------------------------------------------------------------------
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

    // -----------------------------------------------------------------------
    // DUT instantiation
    // -----------------------------------------------------------------------
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

    // -----------------------------------------------------------------------
    // Clock: 10ns period
    // -----------------------------------------------------------------------
    initial clk = 0;
    always #5 clk = ~clk;

    // -----------------------------------------------------------------------
    // Test tracking
    // -----------------------------------------------------------------------
    integer pass_count, fail_count;

    task check;
        input [255:0] test_name;
        input [31:0]  got;
        input [31:0]  expected;
        begin
            if (got === expected) begin
                $display("  PASS: %s = %0d", test_name, got);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL: %s — got %0d, expected %0d",
                         test_name, got, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    task check_bit;
        input [255:0] test_name;
        input         got;
        input         expected;
        begin
            if (got === expected) begin
                $display("  PASS: %s = %0b", test_name, got);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL: %s — got %0b, expected %0b",
                         test_name, got, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // -----------------------------------------------------------------------
    // MMIO helpers
    // -----------------------------------------------------------------------
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
            rst_n = 0;
            cs = 0; we = 0; addr = 0; wdata = 0;
            use_direct = 0;
            a_direct_0 = 0; a_direct_1 = 0;
            a_direct_2 = 0; a_direct_3 = 0;
            b_direct_0 = 0; b_direct_1 = 0;
            b_direct_2 = 0; b_direct_3 = 0;
            start_direct = 0;
            repeat(3) @(posedge clk);
            rst_n = 1;
            @(posedge clk);
        end
    endtask

    // -----------------------------------------------------------------------
    // Cycle counter for pipeline timing tests
    // -----------------------------------------------------------------------
    integer done_cycle, start_cycle;

    // -----------------------------------------------------------------------
    // MAIN TEST SEQUENCE
    // -----------------------------------------------------------------------
    integer i;
    reg [31:0] rd;

    initial begin
        pass_count = 0;
        fail_count = 0;

        $dumpfile("tb_vpu.vcd");
        $dumpvars(0, tb_vpu);

        // ===================================================================
        // TEST 1: Basic dot product — MMIO mode
        // A = [1, 2, 3, 4], B = [5, 6, 7, 8]
        // result = 1*5 + 2*6 + 3*7 + 4*8 = 5+12+21+32 = 70
        // ===================================================================
        $display("\n=== TEST 1: Basic dot product (MMIO mode) ===");
        reset_dut;

        mmio_write(4'h0, 32'd1);   // A0
        mmio_write(4'h1, 32'd2);   // A1
        mmio_write(4'h2, 32'd3);   // A2
        mmio_write(4'h3, 32'd4);   // A3
        mmio_write(4'h4, 32'd5);   // B0
        mmio_write(4'h5, 32'd6);   // B1
        mmio_write(4'h6, 32'd7);   // B2
        mmio_write(4'h7, 32'd8);   // B3

        // Assert start
        mmio_write(4'h9, 32'd1);   // ctrl bit0 = start

        // Wait 3 cycles for pipeline (2 cycle latency + 1 margin)
        repeat(3) @(posedge clk); #1;

        mmio_read(4'h8, rd);
        check("dot([1,2,3,4],[5,6,7,8])", rd, 32'd70);

        // ===================================================================
        // TEST 2: Pipeline timing — done asserts exactly 2 cycles after start
        // ===================================================================
        $display("\n=== TEST 2: Pipeline timing (done at cycle+2) ===");
        reset_dut;

        mmio_write(4'h0, 32'd1); mmio_write(4'h1, 32'd1);
        mmio_write(4'h2, 32'd1); mmio_write(4'h3, 32'd1);
        mmio_write(4'h4, 32'd1); mmio_write(4'h5, 32'd1);
        mmio_write(4'h6, 32'd1); mmio_write(4'h7, 32'd1);

        // Check done is LOW before start — sample wire directly (no clock advance)
        #1;
        check_bit("done before start", dut.done, 1'b0);

        // Pulse start at negedge so it's registered on next posedge
        @(negedge clk);
        cs = 1; we = 1; addr = 4'h9; wdata = 32'd1;
        @(posedge clk); #1;   // start registered here (cycle 0)
        cs = 0; we = 0;

        // Cycle +1: pe_macc products not yet valid — done must be LOW
        @(posedge clk); #1;
        check_bit("done at cycle+1 (should be 0)", dut.done, 1'b0);

        // Cycle +2: sum registered, done asserted HIGH
        @(posedge clk); #1;
        check_bit("done at cycle+2 (should be 1)", dut.done, 1'b1);

        // Cycle +3: start has self-cleared, done returns LOW
        @(posedge clk); #1;
        check_bit("done at cycle+3 (should be 0)", dut.done, 1'b0);

        // ===================================================================
        // TEST 3: Zero input vector
        // A = [0,0,0,0], B = [5,6,7,8] → result = 0
        // ===================================================================
        $display("\n=== TEST 3: Zero input vector ===");
        reset_dut;

        mmio_write(4'h0, 32'd0); mmio_write(4'h1, 32'd0);
        mmio_write(4'h2, 32'd0); mmio_write(4'h3, 32'd0);
        mmio_write(4'h4, 32'd5); mmio_write(4'h5, 32'd6);
        mmio_write(4'h6, 32'd7); mmio_write(4'h7, 32'd8);
        mmio_write(4'h9, 32'd1);
        repeat(3) @(posedge clk); #1;
        mmio_read(4'h8, rd);
        check("dot([0,0,0,0],[5,6,7,8])", rd, 32'd0);

        // ===================================================================
        // TEST 4: Zero weights
        // A = [1,2,3,4], B = [0,0,0,0] → result = 0
        // ===================================================================
        $display("\n=== TEST 4: Zero weights ===");
        reset_dut;

        mmio_write(4'h0, 32'd1); mmio_write(4'h1, 32'd2);
        mmio_write(4'h2, 32'd3); mmio_write(4'h3, 32'd4);
        mmio_write(4'h4, 32'd0); mmio_write(4'h5, 32'd0);
        mmio_write(4'h6, 32'd0); mmio_write(4'h7, 32'd0);
        mmio_write(4'h9, 32'd1);
        repeat(3) @(posedge clk); #1;
        mmio_read(4'h8, rd);
        check("dot([1,2,3,4],[0,0,0,0])", rd, 32'd0);

        // ===================================================================
        // TEST 5: Clear bit resets result
        // ===================================================================
        $display("\n=== TEST 5: Clear bit ===");
        // result still holds 0 from last test, write known value first
        reset_dut;
        mmio_write(4'h0, 32'd10); mmio_write(4'h1, 32'd10);
        mmio_write(4'h2, 32'd10); mmio_write(4'h3, 32'd10);
        mmio_write(4'h4, 32'd10); mmio_write(4'h5, 32'd10);
        mmio_write(4'h6, 32'd10); mmio_write(4'h7, 32'd10);
        mmio_write(4'h9, 32'd1); // start
        repeat(3) @(posedge clk); #1;
        mmio_read(4'h8, rd);
        check("result before clear", rd, 32'd400); // 4*100

        mmio_write(4'h9, 32'd2); // ctrl bit1 = clear
        @(posedge clk); #1;
        mmio_read(4'h8, rd);
        check("result after clear", rd, 32'd0);

        // ===================================================================
        // TEST 6: Direct mode (use_direct=1)
        // A = [3,3,3,3], B = [3,3,3,3] → result = 36
        // ===================================================================
        $display("\n=== TEST 6: Direct mode (use_direct=1) ===");
        reset_dut;
        use_direct  = 1;
        a_direct_0  = 32'd3; a_direct_1 = 32'd3;
        a_direct_2  = 32'd3; a_direct_3 = 32'd3;
        b_direct_0  = 32'd3; b_direct_1 = 32'd3;
        b_direct_2  = 32'd3; b_direct_3 = 32'd3;
        start_direct = 1;
        @(posedge clk); #1;
        start_direct = 0;

        // done_direct should be low at cycle+1
        check_bit("done_direct cycle+1", done_direct, 1'b0);
        @(posedge clk); #1;
        // done_direct should be high at cycle+2
        check_bit("done_direct cycle+2", done_direct, 1'b1);
        check("result_direct [3,3,3,3]·[3,3,3,3]", result_direct, 32'd36);

        use_direct = 0;

        // ===================================================================
        // TEST 7: Reset mid-operation
        // Start a computation, assert rst_n=0 before it completes,
        // verify result is 0 and done is 0 after reset
        // ===================================================================
        $display("\n=== TEST 7: Reset mid-operation ===");
        reset_dut;
        mmio_write(4'h0, 32'd9); mmio_write(4'h1, 32'd9);
        mmio_write(4'h2, 32'd9); mmio_write(4'h3, 32'd9);
        mmio_write(4'h4, 32'd9); mmio_write(4'h5, 32'd9);
        mmio_write(4'h6, 32'd9); mmio_write(4'h7, 32'd9);
        mmio_write(4'h9, 32'd1); // start

        // Assert reset after 1 cycle (before done)
        @(posedge clk); #1;
        rst_n = 0;
        @(posedge clk); #1;
        rst_n = 1;
        @(posedge clk); #1;

        mmio_read(4'h8, rd);
        check("result after mid-op reset", rd, 32'd0);
        mmio_read(4'hA, rd);
        check_bit("done after mid-op reset", rd[0], 1'b0);

        // ===================================================================
        // TEST 8: Readback of A/B registers
        // ===================================================================
        $display("\n=== TEST 8: Register readback ===");
        reset_dut;
        mmio_write(4'h0, 32'hDEAD);
        mmio_write(4'h4, 32'hBEEF);
        mmio_read(4'h0, rd); check("A0 readback", rd, 32'hDEAD);
        mmio_read(4'h4, rd); check("B0 readback", rd, 32'hBEEF);

        // ===================================================================
        // TEST 9: Large values (check 32-bit truncation)
        // A = [0xFFFF, 0, 0, 0], B = [0xFFFF, 0, 0, 0]
        // result = 0xFFFF * 0xFFFF = 0xFFFE0001
        // ===================================================================
        $display("\n=== TEST 9: Large values (32-bit truncation) ===");
        reset_dut;
        mmio_write(4'h0, 32'h0000FFFF); mmio_write(4'h1, 32'd0);
        mmio_write(4'h2, 32'd0);        mmio_write(4'h3, 32'd0);
        mmio_write(4'h4, 32'h0000FFFF); mmio_write(4'h5, 32'd0);
        mmio_write(4'h6, 32'd0);        mmio_write(4'h7, 32'd0);
        mmio_write(4'h9, 32'd1);
        repeat(3) @(posedge clk); #1;
        mmio_read(4'h8, rd);
        check("0xFFFF * 0xFFFF", rd, 32'hFFFE0001);

        // ===================================================================
        // SUMMARY
        // ===================================================================
        $display("\n==========================================");
        $display("  VPU Testbench Results:");
        $display("  PASSED: %0d", pass_count);
        $display("  FAILED: %0d", fail_count);
        $display("==========================================\n");

        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED — review above");

        $finish;
    end

    // Timeout watchdog
    initial begin
        #10000;
        $display("TIMEOUT — testbench hung");
        $finish;
    end

endmodule