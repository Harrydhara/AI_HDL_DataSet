`default_nettype none
`timescale 1ns/1ps
// ---------------------------------------------------------------------------
// tb_mvu  —  Testbench for mvu.v (uses vpu.v + pe_macc.v internally)
//
// Tests covered:
//   1. Basic matrix-vector multiply correctness (known values)
//   2. Pipeline timing — done asserts exactly 2 cycles after start
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

    // -----------------------------------------------------------------------
    // DUT signals
    // -----------------------------------------------------------------------
    reg         clk, rst_n;
    reg         cs, we;
    reg  [6:0]  addr;
    reg  [31:0] wdata;
    wire [31:0] rdata;

    // -----------------------------------------------------------------------
    // DUT instantiation
    // -----------------------------------------------------------------------
    mvu dut (
        .clk  (clk),
        .rst_n(rst_n),
        .cs   (cs),
        .we   (we),
        .addr (addr),
        .wdata(wdata),
        .rdata(rdata)
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
        input [255:0] name;
        input [31:0]  got;
        input [31:0]  expected;
        begin
            if (got === expected) begin
                $display("  PASS: %s = %0d", name, got);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL: %s — got %0d, expected %0d",
                         name, got, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    task check_bit;
        input [255:0] name;
        input         got;
        input         expected;
        begin
            if (got === expected) begin
                $display("  PASS: %s = %0b", name, got);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL: %s — got %0b, expected %0b",
                         name, got, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // -----------------------------------------------------------------------
    // MMIO helpers
    // -----------------------------------------------------------------------
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

    // -----------------------------------------------------------------------
    // Load full 4x4 weight matrix
    // w_flat[0..15] = {w00,w01,w02,w03, w10,w11,...,w33}
    // Base address 0x34
    // -----------------------------------------------------------------------
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
            mmio_write(7'h44, 32'd1); // start
            repeat(4) @(posedge clk); #1; // 2-cycle latency + margin
        end
    endtask

    reg [31:0] y0, y1, y2, y3, rd, done_rd;

    task read_outputs;
        begin
            mmio_read(7'h46, y0);
            mmio_read(7'h47, y1);
            mmio_read(7'h48, y2);
            mmio_read(7'h49, y3);
        end
    endtask

    // -----------------------------------------------------------------------
    // MAIN TEST SEQUENCE
    // -----------------------------------------------------------------------
    integer i;

    initial begin
        pass_count = 0;
        fail_count = 0;

        $dumpfile("tb_mvu.vcd");
        $dumpvars(0, tb_mvu);

        // ===================================================================
        // TEST 1: Basic matrix-vector multiply
        //
        // W = [1 2 3 4]    x = [1]    y[0] = 1+4+9+16  = 30
        //     [5 6 7 8]        [2]    y[1] = 5+12+21+32 = 70
        //     [1 0 1 0]        [3]    y[2] = 1+0+3+0    = 4
        //     [0 1 0 1]        [4]    y[3] = 0+2+0+4    = 6
        // ===================================================================
        $display("\n=== TEST 1: Basic matrix-vector multiply ===");
        reset_dut;

        w_flat[0]=1;  w_flat[1]=2;  w_flat[2]=3;  w_flat[3]=4;
        w_flat[4]=5;  w_flat[5]=6;  w_flat[6]=7;  w_flat[7]=8;
        w_flat[8]=1;  w_flat[9]=0;  w_flat[10]=1; w_flat[11]=0;
        w_flat[12]=0; w_flat[13]=1; w_flat[14]=0; w_flat[15]=1;
        load_weights;
        load_vector(32'd1, 32'd2, 32'd3, 32'd4);
        fire_and_wait;
        read_outputs;

        check("y0 (row0·x)", y0, 32'd30);
        check("y1 (row1·x)", y1, 32'd70);
        check("y2 (row2·x)", y2, 32'd4);
        check("y3 (row3·x)", y3, 32'd6);

        // ===================================================================
        // TEST 2: Pipeline timing — done asserts at cycle+3 (3-stage pipeline)
        // ===================================================================
        $display("\n=== TEST 2: Pipeline timing ===");
        reset_dut;

        // Load any non-zero values
        load_vector(32'd1, 32'd1, 32'd1, 32'd1);
        w_flat[0]=1; w_flat[1]=0; w_flat[2]=0; w_flat[3]=0;
        w_flat[4]=0; w_flat[5]=1; w_flat[6]=0; w_flat[7]=0;
        w_flat[8]=0; w_flat[9]=0; w_flat[10]=1;w_flat[11]=0;
        w_flat[12]=0;w_flat[13]=0;w_flat[14]=0;w_flat[15]=1;
        load_weights;

        // Check done=0 before start -- sample wire directly, no clock advance
        #1;
        check_bit("done before start", dut.done, 1'b0);

        // Pulse start at negedge so it registers on next posedge (cycle 0)
        @(negedge clk);
        cs = 1; we = 1; addr = 7'h44; wdata = 32'd1;
        @(posedge clk); #1;
        cs = 0; we = 0;

        // Cycle +1: pe_macc products not ready -- done LOW
        @(posedge clk); #1;
        check_bit("done at cycle+1 (should be 0)", dut.done, 1'b0);

        // Cycle +2: pe_macc output valid, vpu start_d1 high, sum not yet latched
        @(posedge clk); #1;
        check_bit("done at cycle+2 (should be 0)", dut.done, 1'b0);

        // Cycle +3: vpu result registered, vpu_done0 high -> mvu done HIGH
        @(posedge clk); #1;
        check_bit("done at cycle+3 (should be 1)", dut.done, 1'b1);

        // Cycle +4: start self-cleared, done LOW
        @(posedge clk); #1;
        check_bit("done at cycle+4 (cleared)", dut.done, 1'b0);

        // ===================================================================
        // TEST 3: Identity matrix × vector = vector
        // W = I4, x = [5,6,7,8] → y = [5,6,7,8]
        // ===================================================================
        $display("\n=== TEST 3: Identity matrix ===");
        reset_dut;

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

        // ===================================================================
        // TEST 4: Zero weight matrix → all outputs zero
        // ===================================================================
        $display("\n=== TEST 4: Zero weight matrix ===");
        reset_dut;

        for (i = 0; i < 16; i = i+1) w_flat[i] = 0;
        load_weights;
        load_vector(32'd9, 32'd9, 32'd9, 32'd9);
        fire_and_wait;
        read_outputs;

        check("y0 (zero W)", y0, 32'd0);
        check("y1 (zero W)", y1, 32'd0);
        check("y2 (zero W)", y2, 32'd0);
        check("y3 (zero W)", y3, 32'd0);

        // ===================================================================
        // TEST 5: Zero input vector → all outputs zero
        // ===================================================================
        $display("\n=== TEST 5: Zero input vector ===");
        reset_dut;

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

        // ===================================================================
        // TEST 6: Clean reset — outputs and done cleared
        // ===================================================================
        $display("\n=== TEST 6: Clean reset ===");
        // First do a valid computation to have non-zero state
        w_flat[0]=2; w_flat[1]=2; w_flat[2]=2; w_flat[3]=2;
        w_flat[4]=2; w_flat[5]=2; w_flat[6]=2; w_flat[7]=2;
        w_flat[8]=2; w_flat[9]=2; w_flat[10]=2;w_flat[11]=2;
        w_flat[12]=2;w_flat[13]=2;w_flat[14]=2;w_flat[15]=2;
        load_weights;
        load_vector(32'd3, 32'd3, 32'd3, 32'd3);
        fire_and_wait;

        // Now reset
        rst_n = 0;
        repeat(2) @(posedge clk);
        rst_n = 1;
        @(posedge clk); #1;

        mmio_read(7'h45, rd);
        check_bit("done after reset", rd[0], 1'b0);
        read_outputs;
        check("y0 after reset", y0, 32'd0);
        check("y1 after reset", y1, 32'd0);
        check("y2 after reset", y2, 32'd0);
        check("y3 after reset", y3, 32'd0);

        // ===================================================================
        // TEST 7: Reset mid-operation
        // ===================================================================
        $display("\n=== TEST 7: Reset mid-operation ===");
        reset_dut;

        load_vector(32'd10, 32'd10, 32'd10, 32'd10);
        w_flat[0]=10; w_flat[1]=10; w_flat[2]=10; w_flat[3]=10;
        w_flat[4]=10; w_flat[5]=10; w_flat[6]=10; w_flat[7]=10;
        w_flat[8]=10; w_flat[9]=10; w_flat[10]=10;w_flat[11]=10;
        w_flat[12]=10;w_flat[13]=10;w_flat[14]=10;w_flat[15]=10;
        load_weights;
        mmio_write(7'h44, 32'd1); // start

        // Reset after 1 cycle (pipeline not yet done)
        @(posedge clk); #1;
        rst_n = 0;
        @(posedge clk); #1;
        rst_n = 1;
        @(posedge clk); #1;

        mmio_read(7'h45, rd);
        check_bit("done after mid-op reset", rd[0], 1'b0);
        read_outputs;
        check("y0 after mid-op reset", y0, 32'd0);

        // ===================================================================
        // TEST 8: Back-to-back operations (no idle gap)
        // Op1: I * [1,1,1,1] = [1,1,1,1]
        // Op2: I * [2,2,2,2] = [2,2,2,2]
        // ===================================================================
        $display("\n=== TEST 8: Back-to-back operations ===");
        reset_dut;

        // Identity matrix
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
        check("back-to-back op1 y0", y0, 32'd1);
        check("back-to-back op1 y1", y1, 32'd1);

        // Op2 immediately after (no extra idle cycles)
        load_vector(32'd2, 32'd2, 32'd2, 32'd2);
        mmio_write(7'h44, 32'd1);
        repeat(3) @(posedge clk); #1;
        read_outputs;
        check("back-to-back op2 y0", y0, 32'd2);
        check("back-to-back op2 y1", y1, 32'd2);
        check("back-to-back op2 y2", y2, 32'd2);
        check("back-to-back op2 y3", y3, 32'd2);

        // ===================================================================
        // TEST 9: Weight and input register readback
        // ===================================================================
        $display("\n=== TEST 9: Register readback ===");
        reset_dut;

        mmio_write(7'h30, 32'hAABBCCDD); // x0
        mmio_write(7'h34, 32'h12345678); // w00
        mmio_write(7'h43, 32'hDEADBEEF); // w33

        mmio_read(7'h30, rd); check("x0 readback",  rd, 32'hAABBCCDD);
        mmio_read(7'h34, rd); check("w00 readback", rd, 32'h12345678);
        mmio_read(7'h43, rd); check("w33 readback", rd, 32'hDEADBEEF);

        // ===================================================================
        // TEST 10: All-ones matrix × all-ones vector
        // W = all 1s, x = [1,1,1,1]
        // Each y[i] = 1*1+1*1+1*1+1*1 = 4
        // ===================================================================
        $display("\n=== TEST 10: All-ones matrix × all-ones vector ===");
        reset_dut;

        for (i = 0; i < 16; i = i+1) w_flat[i] = 32'd1;
        load_weights;
        load_vector(32'd1, 32'd1, 32'd1, 32'd1);
        fire_and_wait;
        read_outputs;

        check("y0 (all-ones)", y0, 32'd4);
        check("y1 (all-ones)", y1, 32'd4);
        check("y2 (all-ones)", y2, 32'd4);
        check("y3 (all-ones)", y3, 32'd4);

        // ===================================================================
        // SUMMARY
        // ===================================================================
        $display("\n==========================================");
        $display("  MVU Testbench Results:");
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
        #50000;
        $display("TIMEOUT — testbench hung");
        $finish;
    end

endmodule