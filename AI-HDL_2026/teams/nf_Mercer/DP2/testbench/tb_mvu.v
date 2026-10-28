`default_nettype none
`timescale 1ns/1ps
// ---------------------------------------------------------------------------
// tb_mvu  —  Testbench for mvu.v (uses vpu.v + pe_macc.v internally)
//
// Tests covered:
//   1. Basic matrix-vector multiply correctness (known values)
//   2. Pipeline timing — done asserts exactly 3 cycles after start
//   3. Identity matrix × vector = vector
//   4. Zero weight matrix → all outputs zero
//   5. Zero input vector → all outputs zero
//   6. Reset behavior (clean reset)
//   7. Reset mid-operation
//   8. Back-to-back operations (no idle gap)
//   9. Weight and input register readback
//  10. All-ones matrix × all-ones vector
//
// Run with:
//   iverilog -o tb_mvu tb_mvu.v mvu.v vpu.v pe_macc.v && vvp tb_mvu
// ---------------------------------------------------------------------------
module tb_mvu;

    // DUT signals
    reg         clk, rst_n;
    reg         cs, we;
    reg  [6:0]  addr;
    reg  [31:0] wdata;
    wire [31:0] rdata;

    // DUT instantiation
    mvu dut (
        .clk  (clk),
        .rst_n(rst_n),
        .cs   (cs),
        .we   (we),
        .addr (addr),
        .wdata(wdata),
        .rdata(rdata)
    );

    // Clock: 10ns period
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

    // check — compare 32-bit values, show hex + decimal
    task check;
        input [255:0] name;
        input [31:0]  got;
        input [31:0]  expected;
        begin
            if (got === expected) begin
                $display("  [ PASS ]  %-28s  got 0x%08h (%0d)",
                         name, got, got);
                pass_count = pass_count + 1;
                test_pass  = test_pass  + 1;
            end else begin
                $display("  [ FAIL ]  %-28s  expected 0x%08h (%0d)  |  got 0x%08h (%0d)",
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
                $display("  [ PASS ]  %-28s  got %0b", name, got);
                pass_count = pass_count + 1;
                test_pass  = test_pass  + 1;
            end else begin
                $display("  [ FAIL ]  %-28s  expected %0b  |  got %0b",
                         name, expected, got);
                fail_count = fail_count + 1;
                test_fail  = test_fail  + 1;
            end
        end
    endtask

    // MMIO helpers
    task mmio_write;
        input [6:0]  a;
        input [31:0] d;
        begin
            @(negedge clk);
            cs = 1; we = 1; addr = a; wdata = d;
            @(posedge clk); #1;
            cs = 0; we = 0;
        end
    endtask

    task mmio_read;
        input  [6:0]  a;
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
            repeat(3) @(posedge clk);
            rst_n = 1;
            @(posedge clk);
        end
    endtask

    // Load full 4×4 weight matrix
    // w_flat[0..15] = {w00,w01,w02,w03, w10,w11,...,w33}
    // Base address 0x34
    reg [31:0] w_flat [0:15];

    task load_weights;
        integer k;
        begin
            for (k = 0; k < 16; k = k+1)
                mmio_write(7'h34 + k, w_flat[k]);
        end
    endtask

    task load_vector;
        input [31:0] v0, v1, v2, v3;
        begin
            mmio_write(7'h30, v0);
            mmio_write(7'h31, v1);
            mmio_write(7'h32, v2);
            mmio_write(7'h33, v3);
        end
    endtask

    task fire_and_wait;
        begin
            mmio_write(7'h44, 32'd1);       // assert start
            repeat(4) @(posedge clk); #1;   // 3-cycle pipeline + margin
        end
    endtask

    reg [31:0] y0, y1, y2, y3, rd;

    task read_outputs;
        begin
            mmio_read(7'h46, y0);
            mmio_read(7'h47, y1);
            mmio_read(7'h48, y2);
            mmio_read(7'h49, y3);
        end
    endtask

    // MAIN TEST SEQUENCE
    integer i;

    initial begin
        pass_count = 0;
        fail_count = 0;
        test_num   = 0;

        $dumpfile("tb_mvu.vcd");
        $dumpvars(0, tb_mvu);

        // ===================================================================
        // TEST 1: Basic matrix-vector multiply
        //
        // W = [1 2 3 4]    x = [1]    y[0] = 1·1+2·2+3·3+4·4 = 30
        //     [5 6 7 8]        [2]    y[1] = 5·1+6·2+7·3+8·4 = 70
        //     [1 0 1 0]        [3]    y[2] = 1·1+0·2+1·3+0·4 = 4
        //     [0 1 0 1]        [4]    y[3] = 0·1+1·2+0·3+1·4 = 6
        // ===================================================================
        begin_test("Basic matrix-vector multiply");
        reset_dut;

        $display("  Matrix W:");
        $display("    [ 1  2  3  4 ]");
        $display("    [ 5  6  7  8 ]");
        $display("    [ 1  0  1  0 ]");
        $display("    [ 0  1  0  1 ]");
        $display("  Vector x: [1, 2, 3, 4]");
        $display("  Expected y: [30, 70, 4, 6]");
        $display("");

        w_flat[0]=1;  w_flat[1]=2;  w_flat[2]=3;  w_flat[3]=4;
        w_flat[4]=5;  w_flat[5]=6;  w_flat[6]=7;  w_flat[7]=8;
        w_flat[8]=1;  w_flat[9]=0;  w_flat[10]=1; w_flat[11]=0;
        w_flat[12]=0; w_flat[13]=1; w_flat[14]=0; w_flat[15]=1;
        load_weights;
        load_vector(32'd1, 32'd2, 32'd3, 32'd4);
        fire_and_wait;
        read_outputs;

        check("y0 (row0·x = 1+4+9+16)",  y0, 32'd30);
        check("y1 (row1·x = 5+12+21+32)", y1, 32'd70);
        check("y2 (row2·x = 1+0+3+0)",   y2, 32'd4);
        check("y3 (row3·x = 0+2+0+4)",   y3, 32'd6);
        end_test;

        // ===================================================================
        // TEST 2: Pipeline timing — done HIGH at cycle+3, LOW at cycle+4
        // ===================================================================
        begin_test("Pipeline timing (done pulse width)");
        reset_dut;

        $display("  Identity W, x=[1,1,1,1].  start pulsed at cycle 0.");
        $display("  Expect: done=0 at cyc+1, done=0 at cyc+2,");
        $display("          done=1 at cyc+3, done=0 at cyc+4 (single-cycle pulse)");
        $display("");

        load_vector(32'd1, 32'd1, 32'd1, 32'd1);
        w_flat[0]=1; w_flat[1]=0; w_flat[2]=0; w_flat[3]=0;
        w_flat[4]=0; w_flat[5]=1; w_flat[6]=0; w_flat[7]=0;
        w_flat[8]=0; w_flat[9]=0; w_flat[10]=1;w_flat[11]=0;
        w_flat[12]=0;w_flat[13]=0;w_flat[14]=0;w_flat[15]=1;
        load_weights;

        // Sample done before start
        #1;
        check_bit("done before start  (exp 0)", dut.done, 1'b0);

        // Pulse start — registers on the next posedge (cycle 0)
        @(negedge clk);
        cs = 1; we = 1; addr = 7'h44; wdata = 32'd1;
        @(posedge clk); #1;
        cs = 0; we = 0;

        @(posedge clk); #1;
        check_bit("done at cycle+1    (exp 0)", dut.done, 1'b0);

        @(posedge clk); #1;
        check_bit("done at cycle+2    (exp 0)", dut.done, 1'b0);

        @(posedge clk); #1;
        check_bit("done at cycle+3    (exp 1)", dut.done, 1'b1);

        @(posedge clk); #1;
        check_bit("done at cycle+4    (exp 0)", dut.done, 1'b0);
        end_test;

        // ===================================================================
        // TEST 3: Identity matrix × vector = vector
        // W = I4,  x = [5,6,7,8]  →  y = [5,6,7,8]
        // ===================================================================
        begin_test("Identity matrix x vector = vector");
        reset_dut;

        $display("  W = I4,  x = [5, 6, 7, 8]");
        $display("  Expected y: [5, 6, 7, 8]");
        $display("");

        w_flat[0]=1; w_flat[1]=0; w_flat[2]=0; w_flat[3]=0;
        w_flat[4]=0; w_flat[5]=1; w_flat[6]=0; w_flat[7]=0;
        w_flat[8]=0; w_flat[9]=0; w_flat[10]=1;w_flat[11]=0;
        w_flat[12]=0;w_flat[13]=0;w_flat[14]=0;w_flat[15]=1;
        load_weights;
        load_vector(32'd5, 32'd6, 32'd7, 32'd8);
        fire_and_wait;
        read_outputs;

        check("y0 = x0 = 5", y0, 32'd5);
        check("y1 = x1 = 6", y1, 32'd6);
        check("y2 = x2 = 7", y2, 32'd7);
        check("y3 = x3 = 8", y3, 32'd8);
        end_test;

        // ===================================================================
        // TEST 4: Zero weight matrix → all outputs zero
        // ===================================================================
        begin_test("Zero weight matrix -> all outputs zero");
        reset_dut;

        $display("  W = 0,  x = [9, 9, 9, 9]");
        $display("  Expected y: [0, 0, 0, 0]");
        $display("");

        for (i = 0; i < 16; i = i+1) w_flat[i] = 0;
        load_weights;
        load_vector(32'd9, 32'd9, 32'd9, 32'd9);
        fire_and_wait;
        read_outputs;

        check("y0 (zero W)", y0, 32'd0);
        check("y1 (zero W)", y1, 32'd0);
        check("y2 (zero W)", y2, 32'd0);
        check("y3 (zero W)", y3, 32'd0);
        end_test;

        // ===================================================================
        // TEST 5: Zero input vector → all outputs zero
        // ===================================================================
        begin_test("Zero input vector -> all outputs zero");
        reset_dut;

        $display("  W = all 5s,  x = [0, 0, 0, 0]");
        $display("  Expected y: [0, 0, 0, 0]");
        $display("");

        w_flat[0]=5; w_flat[1]=5; w_flat[2]=5; w_flat[3]=5;
        w_flat[4]=5; w_flat[5]=5; w_flat[6]=5; w_flat[7]=5;
        w_flat[8]=5; w_flat[9]=5; w_flat[10]=5;w_flat[11]=5;
        w_flat[12]=5;w_flat[13]=5;w_flat[14]=5;w_flat[15]=5;
        load_weights;
        load_vector(32'd0, 32'd0, 32'd0, 32'd0);
        fire_and_wait;
        read_outputs;

        check("y0 (zero x)", y0, 32'd0);
        check("y1 (zero x)", y1, 32'd0);
        check("y2 (zero x)", y2, 32'd0);
        check("y3 (zero x)", y3, 32'd0);
        end_test;

        // ===================================================================
        // TEST 6: Clean reset — done and outputs cleared
        // ===================================================================
        begin_test("Clean reset clears done and outputs");

        $display("  Run W=2s, x=[3,3,3,3] to put non-zero state in pipe,");
        $display("  then assert rst_n=0.  After release: done=0, y=0.");
        $display("");

        w_flat[0]=2; w_flat[1]=2; w_flat[2]=2; w_flat[3]=2;
        w_flat[4]=2; w_flat[5]=2; w_flat[6]=2; w_flat[7]=2;
        w_flat[8]=2; w_flat[9]=2; w_flat[10]=2;w_flat[11]=2;
        w_flat[12]=2;w_flat[13]=2;w_flat[14]=2;w_flat[15]=2;
        load_weights;
        load_vector(32'd3, 32'd3, 32'd3, 32'd3);
        fire_and_wait;

        rst_n = 0;
        repeat(2) @(posedge clk);
        rst_n = 1;
        @(posedge clk); #1;

        mmio_read(7'h45, rd);
        check_bit("done after reset   (exp 0)", rd[0], 1'b0);
        read_outputs;
        check("y0 after reset     (exp 0)", y0, 32'd0);
        check("y1 after reset     (exp 0)", y1, 32'd0);
        check("y2 after reset     (exp 0)", y2, 32'd0);
        check("y3 after reset     (exp 0)", y3, 32'd0);
        end_test;

        // ===================================================================
        // TEST 7: Reset mid-operation
        // ===================================================================
        begin_test("Reset asserted mid-operation");
        reset_dut;

        $display("  W=10s, x=[10,10,10,10].  rst_n=0 one cycle after start.");
        $display("  After release: done=0, y0=0.");
        $display("");

        load_vector(32'd10, 32'd10, 32'd10, 32'd10);
        w_flat[0]=10; w_flat[1]=10; w_flat[2]=10; w_flat[3]=10;
        w_flat[4]=10; w_flat[5]=10; w_flat[6]=10; w_flat[7]=10;
        w_flat[8]=10; w_flat[9]=10; w_flat[10]=10;w_flat[11]=10;
        w_flat[12]=10;w_flat[13]=10;w_flat[14]=10;w_flat[15]=10;
        load_weights;
        mmio_write(7'h44, 32'd1);   // start

        // Assert reset one cycle into pipeline
        @(posedge clk); #1;
        rst_n = 0;
        @(posedge clk); #1;
        rst_n = 1;
        @(posedge clk); #1;

        mmio_read(7'h45, rd);
        check_bit("done after mid-op reset (exp 0)", rd[0], 1'b0);
        read_outputs;
        check("y0 after mid-op reset  (exp 0)", y0, 32'd0);
        end_test;

        // ===================================================================
        // TEST 8: Back-to-back operations (no idle gap)
        // Op1: I × [1,1,1,1] = [1,1,1,1]
        // Op2: I × [2,2,2,2] = [2,2,2,2]
        // ===================================================================
        begin_test("Back-to-back operations (no idle gap)");
        reset_dut;

        $display("  W = I4.");
        $display("  Op1: x=[1,1,1,1]  ->  expected y=[1,1,1,1]");
        $display("  Op2: x=[2,2,2,2]  ->  expected y=[2,2,2,2]  (immediate)");
        $display("");

        w_flat[0]=1; w_flat[1]=0; w_flat[2]=0; w_flat[3]=0;
        w_flat[4]=0; w_flat[5]=1; w_flat[6]=0; w_flat[7]=0;
        w_flat[8]=0; w_flat[9]=0; w_flat[10]=1;w_flat[11]=0;
        w_flat[12]=0;w_flat[13]=0;w_flat[14]=0;w_flat[15]=1;
        load_weights;

        // Op1
        load_vector(32'd1, 32'd1, 32'd1, 32'd1);
        mmio_write(7'h44, 32'd1);
        repeat(3) @(posedge clk); #1;
        read_outputs;
        check("op1 y0 (exp 1)", y0, 32'd1);
        check("op1 y1 (exp 1)", y1, 32'd1);
        check("op1 y2 (exp 1)", y2, 32'd1);
        check("op1 y3 (exp 1)", y3, 32'd1);

        // Op2 immediately after — no idle cycles
        load_vector(32'd2, 32'd2, 32'd2, 32'd2);
        mmio_write(7'h44, 32'd1);
        repeat(3) @(posedge clk); #1;
        read_outputs;
        check("op2 y0 (exp 2)", y0, 32'd2);
        check("op2 y1 (exp 2)", y1, 32'd2);
        check("op2 y2 (exp 2)", y2, 32'd2);
        check("op2 y3 (exp 2)", y3, 32'd2);
        end_test;

        // ===================================================================
        // TEST 9: Weight and input register readback
        // ===================================================================
        begin_test("Register readback (x and w)");
        reset_dut;

        $display("  Write known patterns to x[0], w[0][0], w[3][3] then read back.");
        $display("  x[0]    <- 0xAABBCCDD");
        $display("  w[0][0] <- 0x12345678  (addr 0x34)");
        $display("  w[3][3] <- 0xDEADBEEF  (addr 0x43)");
        $display("");

        mmio_write(7'h30, 32'hAABBCCDD);
        mmio_write(7'h34, 32'h12345678);
        mmio_write(7'h43, 32'hDEADBEEF);

        mmio_read(7'h30, rd); check("x[0]    readback", rd, 32'hAABBCCDD);
        mmio_read(7'h34, rd); check("w[0][0] readback", rd, 32'h12345678);
        mmio_read(7'h43, rd); check("w[3][3] readback", rd, 32'hDEADBEEF);
        end_test;

        // ===================================================================
        // TEST 10: All-ones matrix × all-ones vector
        // Each y[i] = 1·1+1·1+1·1+1·1 = 4
        // ===================================================================
        begin_test("All-ones matrix x all-ones vector");
        reset_dut;

        $display("  W = all 1s,  x = [1, 1, 1, 1]");
        $display("  Expected y: [4, 4, 4, 4]");
        $display("");

        for (i = 0; i < 16; i = i+1) w_flat[i] = 32'd1;
        load_weights;
        load_vector(32'd1, 32'd1, 32'd1, 32'd1);
        fire_and_wait;
        read_outputs;

        check("y0 (all-ones, exp 4)", y0, 32'd4);
        check("y1 (all-ones, exp 4)", y1, 32'd4);
        check("y2 (all-ones, exp 4)", y2, 32'd4);
        check("y3 (all-ones, exp 4)", y3, 32'd4);
        end_test;

        // ===================================================================
        // FINAL SUMMARY
        // ===================================================================
        $display("");
        $display("###########################################################");
        $display("#                  MVU TESTBENCH SUMMARY                  #");
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
        #50000;
        $display("TIMEOUT — testbench hung");
        $finish;
    end

endmodule
