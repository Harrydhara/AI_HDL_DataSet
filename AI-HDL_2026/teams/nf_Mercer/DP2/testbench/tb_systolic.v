`default_nettype none
`timescale 1ns/1ps
// ---------------------------------------------------------------------------
// tb_systolic  —  Testbench for systolic_2x2.v
//
//
// MMIO Map:
//   0x50 W/R  a0   0x54 W/R  b0
//   0x51 W/R  a1   0x55 W/R  b1
//   0x52 W/R  a2   0x56 W/R  b2
//   0x53 W/R  a3   0x57 W/R  b3
//   0x58 W/R  start (bit 0)
//   0x59  R   done  (bit 0)
//   0x5A  R   c00   0x5C  R   c10
//   0x5B  R   c01   0x5D  R   c11
//
// Matrix layout:
//   A = [a0 a1]   B = [b0 b1]   C = ReLU(A×B) = [c00 c01]
//       [a2 a3]       [b2 b3]                    [c10 c11]
//
// Tests covered:
//   1. Basic 2×2 multiply  A=[[1,2],[3,4]]  B=[[5,6],[7,8]]
//   2. Identity × matrix  A=I,  B=[[5,6],[7,8]]  → C=B
//   3. Zero A matrix       A=0,  B=anything       → C=0
//   4. Zero B matrix       A=anything, B=0        → C=0
//   5. ReLU clamp          negative products clamped to 0
//   6. Pipeline timing     done asserts exactly 1 cycle after start
//   7. Clean reset         done and outputs cleared after rst_n
//   8. Reset mid-operation
//   9. Back-to-back operations (no idle gap)
//  10. Register readback   A/B registers return written values
//
// Run with:
//   iverilog -o tb_systolic tb_systolic.v systolic_2x2.v pe_macc.v pe_activation.v \
//            && vvp tb_systolic
// ---------------------------------------------------------------------------
module tb_systolic;

    // DUT signals
    reg         clk, rst_n;
    reg         cs, we;
    reg  [6:0]  addr;
    reg  [31:0] wdata;
    wire [31:0] rdata;

    // DUT
    systolic_2x2 dut (
        .clk  (clk),
        .rst_n(rst_n),
        .cs   (cs),
        .we   (we),
        .addr (addr),
        .wdata(wdata),
        .rdata(rdata)
    );

    // Clock: 10 ns period
    initial clk = 0;
    always #5 clk = ~clk;

    // Test tracking
    integer pass_count, fail_count;
    integer test_pass,  test_fail;
    integer test_num;

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
    // Load A and B matrices
    //   A = [a0 a1]   B = [b0 b1]
    //       [a2 a3]       [b2 b3]
    // -----------------------------------------------------------------------
    task load_AB;
        input [31:0] a0, a1, a2, a3;
        input [31:0] b0, b1, b2, b3;
        begin
            mmio_write(7'h50, a0);
            mmio_write(7'h51, a1);
            mmio_write(7'h52, a2);
            mmio_write(7'h53, a3);
            mmio_write(7'h54, b0);
            mmio_write(7'h55, b1);
            mmio_write(7'h56, b2);
            mmio_write(7'h57, b3);
        end
    endtask

    // Fire start and wait for done (2-cycle pipeline + margin)
    task fire_and_wait;
        begin
            mmio_write(7'h58, 32'd1);
            repeat(4) @(posedge clk); #1;
        end
    endtask

    reg [31:0] c00, c01, c10, c11, rd;

    task read_outputs;
        begin
            mmio_read(7'h5A, c00);
            mmio_read(7'h5B, c01);
            mmio_read(7'h5C, c10);
            mmio_read(7'h5D, c11);
        end
    endtask

    // MAIN TEST SEQUENCE
    initial begin
        pass_count = 0;
        fail_count = 0;
        test_num   = 0;

        $dumpfile("tb_systolic.vcd");
        $dumpvars(0, tb_systolic);

        // ===================================================================
        // TEST 1: Basic 2×2 multiply
        //
        // A = [1 2]   B = [5 6]   C = A×B = [1·5+2·7  1·6+2·8] = [19 22]
        //     [3 4]       [7 8]              [3·5+4·7  3·6+4·8]   [43 50]
        // All values ≥ 0 so ReLU has no effect.
        // ===================================================================
        begin_test("Basic 2x2 multiply");
        reset_dut;

        $display("  A = [[1,2],[3,4]]   B = [[5,6],[7,8]]");
        $display("  C = A x B = [[19,22],[43,50]]  (ReLU no-op, all positive)");
        $display("");

        load_AB(32'd1, 32'd2, 32'd3, 32'd4,
                32'd5, 32'd6, 32'd7, 32'd8);
        fire_and_wait;
        read_outputs;

        check("c00 = 1*5+2*7 = 19",  c00, 32'd19);
        check("c01 = 1*6+2*8 = 22",  c01, 32'd22);
        check("c10 = 3*5+4*7 = 43",  c10, 32'd43);
        check("c11 = 3*6+4*8 = 50",  c11, 32'd50);
        end_test;

        // ===================================================================
        // TEST 2: Identity A × B = B
        //
        // A = I2 = [1 0]   B = [5 6]   C = B = [5 6]
        //          [0 1]       [7 8]            [7 8]
        // ===================================================================
        begin_test("Identity A x B = B");
        reset_dut;

        $display("  A = I2 = [[1,0],[0,1]]   B = [[5,6],[7,8]]");
        $display("  Expected C = B = [[5,6],[7,8]]");
        $display("");

        load_AB(32'd1, 32'd0, 32'd0, 32'd1,
                32'd5, 32'd6, 32'd7, 32'd8);
        fire_and_wait;
        read_outputs;

        check("c00 = 5", c00, 32'd5);
        check("c01 = 6", c01, 32'd6);
        check("c10 = 7", c10, 32'd7);
        check("c11 = 8", c11, 32'd8);
        end_test;

        // ===================================================================
        // TEST 3: Zero A matrix → all outputs zero
        // ===================================================================
        begin_test("Zero A matrix -> all outputs zero");
        reset_dut;

        $display("  A = 0,  B = [[5,6],[7,8]]");
        $display("  Expected C = [[0,0],[0,0]]");
        $display("");

        load_AB(32'd0, 32'd0, 32'd0, 32'd0,
                32'd5, 32'd6, 32'd7, 32'd8);
        fire_and_wait;
        read_outputs;

        check("c00 (zero A)", c00, 32'd0);
        check("c01 (zero A)", c01, 32'd0);
        check("c10 (zero A)", c10, 32'd0);
        check("c11 (zero A)", c11, 32'd0);
        end_test;

        // ===================================================================
        // TEST 4: Zero B matrix → all outputs zero
        // ===================================================================
        begin_test("Zero B matrix -> all outputs zero");
        reset_dut;

        $display("  A = [[3,3],[3,3]],  B = 0");
        $display("  Expected C = [[0,0],[0,0]]");
        $display("");

        load_AB(32'd3, 32'd3, 32'd3, 32'd3,
                32'd0, 32'd0, 32'd0, 32'd0);
        fire_and_wait;
        read_outputs;

        check("c00 (zero B)", c00, 32'd0);
        check("c01 (zero B)", c01, 32'd0);
        check("c10 (zero B)", c10, 32'd0);
        check("c11 (zero B)", c11, 32'd0);
        end_test;

        // ===================================================================
        // TEST 5: ReLU clamp — negative products clamped to 0
        //
        // Using signed interpretation: a0= -1 (0xFFFFFFFF), b0= 1
        //   c00 = (-1)*1 + (-1)*1 = -2  → ReLU → 0
        //   c01 = (-1)*1 + (-1)*1 = -2  → ReLU → 0
        //   c10 = (-1)*1 + (-1)*1 = -2  → ReLU → 0
        //   c11 = (-1)*1 + (-1)*1 = -2  → ReLU → 0
        // ===================================================================
        begin_test("ReLU clamp: negative products -> 0");
        reset_dut;

        $display("  A = [[-1,-1],[-1,-1]]  (0xFFFFFFFF = -1 signed)");
        $display("  B = [[1,1],[1,1]]");
        $display("  Raw products all -2  ->  ReLU clamps to 0");
        $display("");

        load_AB(32'hFFFFFFFF, 32'hFFFFFFFF,
                32'hFFFFFFFF, 32'hFFFFFFFF,
                32'd1,        32'd1,
                32'd1,        32'd1);
        fire_and_wait;
        read_outputs;

        check("c00 ReLU(-2) = 0", c00, 32'd0);
        check("c01 ReLU(-2) = 0", c01, 32'd0);
        check("c10 ReLU(-2) = 0", c10, 32'd0);
        check("c11 ReLU(-2) = 0", c11, 32'd0);
        end_test;

        // ===================================================================
        // TEST 6: Pipeline timing — done HIGH exactly 1 cycle after start,
        //         and cleared on the next start write
        // ===================================================================
        begin_test("Pipeline timing (done pulse)");
        reset_dut;

        $display("  I2 x [[1,1],[1,1]].  Check done is 0 before start,");
        $display("  1 at cycle+1 (pe_macc registered output ready),");
        $display("  0 after next start write clears it.");
        $display("");

        load_AB(32'd1, 32'd0, 32'd0, 32'd1,
                32'd1, 32'd1, 32'd1, 32'd1);

        #1;
        check_bit("done before start      (exp 0)", dut.done, 1'b0);

        // Assert start at negedge, registers on next posedge (cycle 0)
        @(negedge clk);
        cs = 1; we = 1; addr = 7'h58; wdata = 32'd1;
        @(posedge clk); #1;
        cs = 0; we = 0;

        // Cycle +1: start was registered last posedge, so done is now 1
        @(posedge clk); #1;
        check_bit("done at cycle+1        (exp 1)", dut.done, 1'b1);

        // Cycle +2: start self-cleared, done stays 1 (sticky) until next write
        @(posedge clk); #1;
        check_bit("done at cycle+2 sticky (exp 1)", dut.done, 1'b1);

        // Writing start clears done — mmio_write already lands us 1ns
        // past the posedge where new_start_write fired and done<=0 was
        // scheduled.  Sample immediately; do NOT advance another cycle
        // (start would self-clear and done would be re-set to 1).
        mmio_write(7'h58, 32'd1);
        check_bit("done cleared by start  (exp 0)", dut.done, 1'b0);
        end_test;

        // ===================================================================
        // TEST 7: Clean reset — done and internal regs cleared
        // ===================================================================
        begin_test("Clean reset clears done and outputs");
        reset_dut;

        $display("  Run a valid multiply, then assert rst_n=0.");
        $display("  After release: done=0, all C=0.");
        $display("");

        load_AB(32'd2, 32'd2, 32'd2, 32'd2,
                32'd2, 32'd2, 32'd2, 32'd2);
        fire_and_wait;

        rst_n = 0;
        repeat(2) @(posedge clk);
        rst_n = 1;
        @(posedge clk); #1;

        mmio_read(7'h59, rd);
        check_bit("done after reset       (exp 0)", rd[0], 1'b0);
        read_outputs;
        check("c00 after reset        (exp 0)", c00, 32'd0);
        check("c01 after reset        (exp 0)", c01, 32'd0);
        check("c10 after reset        (exp 0)", c10, 32'd0);
        check("c11 after reset        (exp 0)", c11, 32'd0);
        end_test;

        // ===================================================================
        // TEST 8: Reset mid-operation
        // ===================================================================
        begin_test("Reset asserted mid-operation");
        reset_dut;

        $display("  Start a multiply, assert rst_n=0 one cycle in.");
        $display("  After release: done=0, c00=0.");
        $display("");

        load_AB(32'd5, 32'd5, 32'd5, 32'd5,
                32'd5, 32'd5, 32'd5, 32'd5);
        mmio_write(7'h58, 32'd1);

        @(posedge clk); #1;
        rst_n = 0;
        @(posedge clk); #1;
        rst_n = 1;
        @(posedge clk); #1;

        mmio_read(7'h59, rd);
        check_bit("done after mid-op reset (exp 0)", rd[0], 1'b0);
        read_outputs;
        check("c00 after mid-op reset (exp 0)", c00, 32'd0);
        end_test;

        // ===================================================================
        // TEST 9: Back-to-back operations (no idle gap)
        // Op1: I × [[1,1],[1,1]] = [[1,1],[1,1]]
        // Op2: I × [[3,4],[5,6]] = [[3,4],[5,6]]
        // ===================================================================
        begin_test("Back-to-back operations (no idle gap)");
        reset_dut;

        $display("  Op1: A=I2, B=[[1,1],[1,1]]  ->  C=[[1,1],[1,1]]");
        $display("  Op2: A=I2, B=[[3,4],[5,6]]  ->  C=[[3,4],[5,6]]  (immediate)");
        $display("");

        // Op1
        load_AB(32'd1, 32'd0, 32'd0, 32'd1,
                32'd1, 32'd1, 32'd1, 32'd1);
        mmio_write(7'h58, 32'd1);
        repeat(3) @(posedge clk); #1;
        read_outputs;
        check("op1 c00 (exp 1)", c00, 32'd1);
        check("op1 c01 (exp 1)", c01, 32'd1);
        check("op1 c10 (exp 1)", c10, 32'd1);
        check("op1 c11 (exp 1)", c11, 32'd1);

        // Op2 immediately
        load_AB(32'd1, 32'd0, 32'd0, 32'd1,
                32'd3, 32'd4, 32'd5, 32'd6);
        mmio_write(7'h58, 32'd1);
        repeat(3) @(posedge clk); #1;
        read_outputs;
        check("op2 c00 (exp 3)", c00, 32'd3);
        check("op2 c01 (exp 4)", c01, 32'd4);
        check("op2 c10 (exp 5)", c10, 32'd5);
        check("op2 c11 (exp 6)", c11, 32'd6);
        end_test;

        // ===================================================================
        // TEST 10: A and B register readback
        // ===================================================================
        begin_test("A and B register readback");
        reset_dut;

        $display("  Write distinct patterns to each A and B register,");
        $display("  then read back and verify.");
        $display("");

        mmio_write(7'h50, 32'h11111111);  // a0
        mmio_write(7'h51, 32'h22222222);  // a1
        mmio_write(7'h52, 32'h33333333);  // a2
        mmio_write(7'h53, 32'h44444444);  // a3
        mmio_write(7'h54, 32'hAAAAAAAA);  // b0
        mmio_write(7'h55, 32'hBBBBBBBB);  // b1
        mmio_write(7'h56, 32'hCCCCCCCC);  // b2
        mmio_write(7'h57, 32'hDDDDDDDD);  // b3

        mmio_read(7'h50, rd); check("a0 readback", rd, 32'h11111111);
        mmio_read(7'h51, rd); check("a1 readback", rd, 32'h22222222);
        mmio_read(7'h52, rd); check("a2 readback", rd, 32'h33333333);
        mmio_read(7'h53, rd); check("a3 readback", rd, 32'h44444444);
        mmio_read(7'h54, rd); check("b0 readback", rd, 32'hAAAAAAAA);
        mmio_read(7'h55, rd); check("b1 readback", rd, 32'hBBBBBBBB);
        mmio_read(7'h56, rd); check("b2 readback", rd, 32'hCCCCCCCC);
        mmio_read(7'h57, rd); check("b3 readback", rd, 32'hDDDDDDDD);
        end_test;

        // ===================================================================
        // FINAL SUMMARY
        // ===================================================================
        $display("");
        $display("###########################################################");
        $display("#             SYSTOLIC 2x2 TESTBENCH SUMMARY              #");
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

    // Watchdog
    initial begin
        #50000;
        $display("TIMEOUT — testbench hung");
        $finish;
    end

endmodule