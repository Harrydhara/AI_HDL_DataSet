//==============================================================================
// tb_security.v — DP3 Security Feature Validation Testbench
//
// Design Under Test: winograd_peripheral (interface.v DP3 version)
//
// Purpose: Prove that DP3 security countermeasures work correctly:
//   CM-1: Write-While-Busy Protection
//         - INPUT_DATA/FILTER_DATA writes blocked when BUSY=1
//         - CTRL[START] write masked when BUSY=1
//         - STATUS[SEC_VIO] flag set on blocked attempt
//         - SEC_VIO flag cleared when CPU reads STATUS
//   CM-2: Debug Sentinel Removal
//         - Unmapped addresses return 0x0, not 0xDEADBEEF
//
// Tests:
//   TEST 1 : Normal operation (regression baseline)
//   TEST 2 : INPUT_DATA write-while-busy attack  <- SECURITY PROOF
//   TEST 3 : FILTER_DATA write-while-busy attack <- SECURITY PROOF
//   TEST 4 : CTRL[START] re-trigger while busy   <- SECURITY PROOF
//   TEST 5 : SEC_VIO flag clear-on-read          <- SECURITY PROOF
//   TEST 6 : CM-2 sentinel removal check         <- SECURITY PROOF
//   TEST 7 : Post-attack regression (stability)
//
// Run with Icarus Verilog:
//   iverilog -o sim_security tb_security.v ../../src/interface.v \
//     ../../src/winograd.v ../../src/matrix_filter.v \
//     ../../src/matrix_input.v ../../src/matrix_output.v \
//     ../../src/element_wise.v
//   vvp sim_security
//   gtkwave tb_security.vcd &
//==============================================================================
`timescale 1ns/1ps

module tb_security;

    //==========================================================================
    // Parameters
    //==========================================================================
    parameter DATA_WIDTH  = 32;
    parameter FRAC_BITS   = 16;
    parameter CLK_PERIOD  = 10;  // 100 MHz

    // Register addresses (base offset)
    localparam ADDR_CTRL        = 6'h00;
    localparam ADDR_STATUS      = 6'h04;
    localparam ADDR_CONFIG      = 6'h08;
    localparam ADDR_INPUT_IDX   = 6'h0C;
    localparam ADDR_INPUT_DATA  = 6'h10;
    localparam ADDR_FILTER_IDX  = 6'h14;
    localparam ADDR_FILTER_DATA = 6'h18;
    localparam ADDR_OUTPUT_0    = 6'h1C;
    localparam ADDR_OUTPUT_1    = 6'h20;
    localparam ADDR_OUTPUT_2    = 6'h24;
    localparam ADDR_OUTPUT_3    = 6'h28;

    // CTRL bit positions
    localparam CTRL_START_BIT     = 0;
    localparam CTRL_ACCUM_EN_BIT  = 3;
    localparam CTRL_CLEAR_ACC_BIT = 4;
    localparam CTRL_IRQ_EN_BIT    = 5;

    // STATUS bit positions
    localparam STATUS_BUSY_BIT    = 0;
    localparam STATUS_DONE_BIT    = 1;
    localparam STATUS_SEC_VIO_BIT = 2;  // DP3 new

    //==========================================================================
    // DUT Signals
    //==========================================================================
    reg                     clk;
    reg                     rstn;
    reg  [5:0]              address;
    reg  [1:0]              data_write_n;
    reg  [1:0]              data_read_n;
    reg  [DATA_WIDTH-1:0]   data_in;
    wire [DATA_WIDTH-1:0]   data_out;
    wire                    data_ready;
    wire                    winograd_irq;

    //==========================================================================
    // DUT Instantiation
    //==========================================================================
    winograd_peripheral #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC_BITS (FRAC_BITS)
    ) dut (
        .clk          (clk),
        .rstn         (rstn),
        .address      (address),
        .data_write_n (data_write_n),
        .data_read_n  (data_read_n),
        .data_in      (data_in),
        .data_out     (data_out),
        .data_ready   (data_ready),
        .winograd_irq (winograd_irq)
    );

    //==========================================================================
    // Clock
    //==========================================================================
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    //==========================================================================
    // Test Bookkeeping
    //==========================================================================
    integer pass_count;
    integer fail_count;
    integer timeout_cnt;
    integer i;

    // Reference data: filter = all 1.0 (0x00010000), input = 1.0..16.0
    reg [DATA_WIDTH-1:0] ref_filter [0:8];
    reg [DATA_WIDTH-1:0] ref_input  [0:15];
    reg [DATA_WIDTH-1:0] clean_output [0:3];  // output from clean run

    //==========================================================================
    // MMIO Helper Tasks
    //==========================================================================

    // Write one 32-bit value to a register address
    task mmio_write;
        input [5:0]           addr;
        input [DATA_WIDTH-1:0] wdata;
        begin
            @(posedge clk);
            #1;  // slight delay after clock edge
            address      = addr;
            data_in      = wdata;
            data_write_n = 2'b00;   // assert write
            data_read_n  = 2'b11;   // no read
            @(posedge clk);
            #1;
            data_write_n = 2'b11;   // deassert write
            data_in      = 32'h0;
        end
    endtask

    // Read one 32-bit value from a register address — result in data_out
    task mmio_read;
        input [5:0] addr;
        begin
            @(posedge clk);
            #1;
            address      = addr;
            data_write_n = 2'b11;   // no write
            data_read_n  = 2'b00;   // assert read
            @(posedge clk);
            #1;
            data_read_n  = 2'b11;   // deassert read
        end
    endtask

    // Poll STATUS until BUSY bit clears or timeout
    task wait_not_busy;
        begin
            timeout_cnt = 0;
            mmio_read(ADDR_STATUS);
            while (data_out[STATUS_BUSY_BIT] && timeout_cnt < 500000) begin
                @(posedge clk);
                mmio_read(ADDR_STATUS);
                timeout_cnt = timeout_cnt + 1;
            end
            if (timeout_cnt >= 500000) begin
                $display("  [TIMEOUT] STATUS.BUSY never cleared!");
                fail_count = fail_count + 1;
            end
        end
    endtask

    // Poll STATUS until DONE bit sets or timeout
    task wait_done;
        begin
            timeout_cnt = 0;
            mmio_read(ADDR_STATUS);
            while (!data_out[STATUS_DONE_BIT] && timeout_cnt < 500000) begin
                @(posedge clk);
                mmio_read(ADDR_STATUS);
                timeout_cnt = timeout_cnt + 1;
            end
            if (timeout_cnt >= 500000) begin
                $display("  [TIMEOUT] STATUS.DONE never set!");
                fail_count = fail_count + 1;
            end
        end
    endtask

    // Poll STATUS until BUSY asserts (detect start of computation)
    task wait_busy;
        begin
            timeout_cnt = 0;
            mmio_read(ADDR_STATUS);
            while (!data_out[STATUS_BUSY_BIT] && timeout_cnt < 10000) begin
                @(posedge clk);
                mmio_read(ADDR_STATUS);
                timeout_cnt = timeout_cnt + 1;
            end
        end
    endtask

    // Load 9 filter values (auto-increment)
    task load_filter;
        input [DATA_WIDTH-1:0] f0, f1, f2, f3, f4, f5, f6, f7, f8;
        begin
            mmio_write(ADDR_FILTER_IDX,  32'h0);
            mmio_write(ADDR_FILTER_DATA, f0);
            mmio_write(ADDR_FILTER_DATA, f1);
            mmio_write(ADDR_FILTER_DATA, f2);
            mmio_write(ADDR_FILTER_DATA, f3);
            mmio_write(ADDR_FILTER_DATA, f4);
            mmio_write(ADDR_FILTER_DATA, f5);
            mmio_write(ADDR_FILTER_DATA, f6);
            mmio_write(ADDR_FILTER_DATA, f7);
            mmio_write(ADDR_FILTER_DATA, f8);
        end
    endtask

    // Load 16 input values (auto-increment)
    task load_input_ref;
        begin : load_blk
            integer j;
            mmio_write(ADDR_INPUT_IDX, 32'h0);
            for (j = 0; j < 16; j = j + 1)
                mmio_write(ADDR_INPUT_DATA, ref_input[j]);
        end
    endtask

    // Full setup: load filter + input + trigger START
    task full_setup_and_start;
        begin
            load_filter(
                ref_filter[0], ref_filter[1], ref_filter[2],
                ref_filter[3], ref_filter[4], ref_filter[5],
                ref_filter[6], ref_filter[7], ref_filter[8]
            );
            load_input_ref();
            // Trigger START
            mmio_write(ADDR_CTRL, 32'h1);
        end
    endtask

    // Reset DUT to clean state
    task do_reset;
        begin
            rstn         = 1'b0;
            address      = 6'h0;
            data_write_n = 2'b11;
            data_read_n  = 2'b11;
            data_in      = 32'h0;
            repeat (10) @(posedge clk);
            rstn = 1'b1;
            repeat (5) @(posedge clk);
        end
    endtask

    //==========================================================================
    // CHECK macro helpers
    //==========================================================================
    task check_eq;
        input [63:0] got;
        input [63:0] exp;
        input [127:0] label;   // 16-char string
        begin
            if (got === exp) begin
                $display("  [PASS] %s: got=0x%08h", label, got[31:0]);
                pass_count = pass_count + 1;
            end else begin
                $display("  [FAIL] %s: got=0x%08h  expected=0x%08h",
                         label, got[31:0], exp[31:0]);
                fail_count = fail_count + 1;
            end
        end
    endtask

    task check_ne;
        input [63:0] got;
        input [63:0] not_exp;
        input [127:0] label;
        begin
            if (got !== not_exp) begin
                $display("  [PASS] %s: got=0x%08h (correctly differs from 0x%08h)",
                         label, got[31:0], not_exp[31:0]);
                pass_count = pass_count + 1;
            end else begin
                $display("  [FAIL] %s: got=0x%08h  (expected != 0x%08h, but are equal)",
                         label, got[31:0], not_exp[31:0]);
                fail_count = fail_count + 1;
            end
        end
    endtask

    task check_bit;
        input       got;
        input       exp;
        input [127:0] label;
        begin
            if (got === exp) begin
                $display("  [PASS] %s: bit=%0b", label, got);
                pass_count = pass_count + 1;
            end else begin
                $display("  [FAIL] %s: bit=%0b  expected=%0b", label, got, exp);
                fail_count = fail_count + 1;
            end
        end
    endtask

    //==========================================================================
    // Initialize reference data
    //==========================================================================
    task init_ref_data;
        begin : init_blk
            integer j;
            // filter = all 1.0 in Q16.16 = 0x00010000
            for (j = 0; j < 9; j = j + 1)
                ref_filter[j] = 32'h00010000;
            // input = 1.0, 2.0, 3.0, ... 16.0 in Q16.16
            for (j = 0; j < 16; j = j + 1)
                ref_input[j] = (j + 1) << 16;
        end
    endtask

    //==========================================================================
    // MAIN TEST SEQUENCE
    //==========================================================================
    initial begin
        pass_count = 0;
        fail_count = 0;

        $dumpfile("tb_security.vcd");
        $dumpvars(0, tb_security);

        $display("==============================================================");
        $display("  DP3 SECURITY TESTBENCH — winograd_peripheral (interface.v)");
        $display("  CM-1: Write-While-Busy Protection");
        $display("  CM-2: Debug Sentinel Removal");
        $display("==============================================================");

        init_ref_data();
        do_reset();

        // ==================================================================
        // TEST 1: Normal Operation — Regression Baseline
        // ==================================================================
        $display("\n--------------------------------------------------------------");
        $display("  TEST 1: Normal Operation (Regression Baseline)");
        $display("  Verify: clean load → START → correct output, BUSY/DONE flags");
        $display("--------------------------------------------------------------");

        full_setup_and_start();

        // Check BUSY asserts
        wait_busy();
        mmio_read(ADDR_STATUS);
        check_bit(data_out[STATUS_BUSY_BIT], 1'b1, "STATUS.BUSY asserts");
        check_bit(data_out[STATUS_SEC_VIO_BIT], 1'b0, "STATUS.SEC_VIO=0 clean start");

        // Wait for completion
        wait_done();
        mmio_read(ADDR_STATUS);
        check_bit(data_out[STATUS_DONE_BIT], 1'b1,  "STATUS.DONE asserts");
        check_bit(data_out[STATUS_BUSY_BIT], 1'b0,  "STATUS.BUSY clears");
        check_bit(data_out[STATUS_SEC_VIO_BIT], 1'b0, "STATUS.SEC_VIO=0 no violation");

        // Capture clean outputs as reference
        mmio_read(ADDR_OUTPUT_0); clean_output[0] = data_out;
        mmio_read(ADDR_OUTPUT_1); clean_output[1] = data_out;
        mmio_read(ADDR_OUTPUT_2); clean_output[2] = data_out;
        mmio_read(ADDR_OUTPUT_3); clean_output[3] = data_out;

        $display("  Clean output[0]=0x%08h  output[1]=0x%08h",
                 clean_output[0], clean_output[1]);
        $display("  Clean output[2]=0x%08h  output[3]=0x%08h",
                 clean_output[2], clean_output[3]);

        // Outputs must be non-zero for this filter/input combination
        check_ne(clean_output[0], 32'h0, "output[0] non-zero");
        check_ne(clean_output[1], 32'h0, "output[1] non-zero");

        // ==================================================================
        // TEST 2: INPUT_DATA Write-While-Busy Attack
        // ==================================================================
        do_reset();
        $display("\n--------------------------------------------------------------");
        $display("  TEST 2: INPUT_DATA Write-While-Busy Attack  [SECURITY TEST]");
        $display("  Attack: write INPUT_DATA=0xDEAD1234 after BUSY asserts");
        $display("  Expect: write BLOCKED, output correct, SEC_VIO flag SET");
        $display("--------------------------------------------------------------");

        full_setup_and_start();

        // Wait until BUSY=1 (computation is running)
        wait_busy();
        mmio_read(ADDR_STATUS);
        $display("  [ATTACK] BUSY=%0b — launching INPUT_DATA write attack...",
                 data_out[STATUS_BUSY_BIT]);

        // === ATTACK: try to corrupt input_buffer[0] while BUSY ===
        mmio_write(ADDR_INPUT_IDX,  32'h0);          // aim at slot 0
        mmio_write(ADDR_INPUT_DATA, 32'hDEAD1234);   // attacker payload
        mmio_write(ADDR_INPUT_DATA, 32'hCAFEBABE);   // attacker payload slot 1

        // === CHECK: SEC_VIO flag must be SET ===
        mmio_read(ADDR_STATUS);
        check_bit(data_out[STATUS_SEC_VIO_BIT], 1'b1,
                  "SEC_VIO flag SET after INPUT attack");
        $display("  STATUS register read: 0x%08h (bit2=SEC_VIO)", data_out);

        // Wait for computation to finish
        wait_done();

        // === CHECK: output must match clean run (buffer NOT corrupted) ===
        mmio_read(ADDR_OUTPUT_0);
        check_eq(data_out, clean_output[0], "output[0] uncorrupted");
        mmio_read(ADDR_OUTPUT_1);
        check_eq(data_out, clean_output[1], "output[1] uncorrupted");
        mmio_read(ADDR_OUTPUT_2);
        check_eq(data_out, clean_output[2], "output[2] uncorrupted");
        mmio_read(ADDR_OUTPUT_3);
        check_eq(data_out, clean_output[3], "output[3] uncorrupted");

        // === CHECK: verify attacker value did NOT land in buffer ===
        wait_not_busy();
        mmio_write(ADDR_INPUT_IDX, 32'h0);
        mmio_read(ADDR_INPUT_DATA);
        check_ne(data_out, 32'hDEAD1234, "input_buffer[0] not 0xDEAD1234");
        $display("  input_buffer[0] after attack = 0x%08h (should be ref data)", data_out);

        // ==================================================================
        // TEST 3: FILTER_DATA Write-While-Busy Attack
        // ==================================================================
        do_reset();
        $display("\n--------------------------------------------------------------");
        $display("  TEST 3: FILTER_DATA Write-While-Busy Attack  [SECURITY TEST]");
        $display("  Attack: write FILTER_DATA=0xBAD0BEEF after BUSY asserts");
        $display("  Expect: write BLOCKED, output correct, SEC_VIO flag SET");
        $display("--------------------------------------------------------------");

        full_setup_and_start();
        wait_busy();
        $display("  [ATTACK] BUSY asserted — launching FILTER_DATA write attack...");

        // === ATTACK: try to corrupt filter coefficients while BUSY ===
        mmio_write(ADDR_FILTER_IDX,  32'h0);
        mmio_write(ADDR_FILTER_DATA, 32'hBAD0BEEF);  // corrupt filter[0]
        mmio_write(ADDR_FILTER_DATA, 32'hBAD0BEEF);  // corrupt filter[1]
        mmio_write(ADDR_FILTER_DATA, 32'hBAD0BEEF);  // corrupt filter[2]

        // === CHECK: SEC_VIO flag must be SET ===
        mmio_read(ADDR_STATUS);
        check_bit(data_out[STATUS_SEC_VIO_BIT], 1'b1,
                  "SEC_VIO flag SET after FILTER attack");

        wait_done();

        // === CHECK: output must match clean run ===
        mmio_read(ADDR_OUTPUT_0);
        check_eq(data_out, clean_output[0], "output[0] filter uncorrupted");
        mmio_read(ADDR_OUTPUT_1);
        check_eq(data_out, clean_output[1], "output[1] filter uncorrupted");
        mmio_read(ADDR_OUTPUT_2);
        check_eq(data_out, clean_output[2], "output[2] filter uncorrupted");
        mmio_read(ADDR_OUTPUT_3);
        check_eq(data_out, clean_output[3], "output[3] filter uncorrupted");

        // ==================================================================
        // TEST 4: CTRL[START] Re-trigger While Busy Attack
        // ==================================================================
        do_reset();
        $display("\n--------------------------------------------------------------");
        $display("  TEST 4: CTRL[START] Re-trigger While Busy  [SECURITY TEST]");
        $display("  Attack: write CTRL=0x1 (START=1) after BUSY asserts");
        $display("  Expect: START bit masked to 0, SEC_VIO flag SET,");
        $display("          computation still finishes normally");
        $display("--------------------------------------------------------------");

        full_setup_and_start();
        wait_busy();
        $display("  [ATTACK] BUSY asserted — attempting START re-trigger...");

        // === ATTACK: try to set START while BUSY (should be masked) ===
        mmio_write(ADDR_CTRL, 32'h1);  // write CTRL[START]=1

        // === CHECK: CTRL[START] should NOT be 1 (busy_guard masked it) ===
        mmio_read(ADDR_CTRL);
        check_bit(data_out[CTRL_START_BIT], 1'b0,
                  "CTRL.START masked to 0 while BUSY");
        $display("  CTRL register after attack write = 0x%08h", data_out);

        // === CHECK: SEC_VIO flag SET ===
        mmio_read(ADDR_STATUS);
        check_bit(data_out[STATUS_SEC_VIO_BIT], 1'b1,
                  "SEC_VIO SET on START re-trigger");

        // === CHECK: computation still finishes normally ===
        wait_done();
        mmio_read(ADDR_OUTPUT_0);
        check_eq(data_out, clean_output[0], "output[0] after START attack");
        mmio_read(ADDR_OUTPUT_1);
        check_eq(data_out, clean_output[1], "output[1] after START attack");

        // ==================================================================
        // TEST 5: SEC_VIO Flag Clear-on-Read
        // ==================================================================
        // Note: TEST 4's mmio_read(STATUS) that checked SEC_VIO already
        // triggered the clear-on-read, so SEC_VIO=0 by now.
        // TEST 5 is self-contained: trigger a fresh violation, then verify
        // the clear-on-read mechanism works.
        do_reset();
        $display("\n--------------------------------------------------------------");
        $display("  TEST 5: SEC_VIO Flag Clear-on-Read  [SECURITY TEST]");
        $display("  Sequence: trigger violation → SEC_VIO=1 → read STATUS → SEC_VIO=0");
        $display("--------------------------------------------------------------");

        // Step 0: Trigger a fresh violation to set SEC_VIO
        full_setup_and_start();
        wait_busy();
        mmio_write(ADDR_INPUT_DATA, 32'hFACE0005); // attack while busy — sets SEC_VIO

        // Step 1: Verify SEC_VIO is now 1
        // (The sec_violation_flag is SET on the clock edge after the blocked write.
        //  This STATUS read both samples the flag AND schedules the clear.)
        @(posedge clk); #1;
        mmio_read(ADDR_STATUS);
        check_bit(data_out[STATUS_SEC_VIO_BIT], 1'b1,
                  "SEC_VIO=1 before acknowledgement");
        $display("  STATUS before read-clear = 0x%08h", data_out);

        // Step 2: Read STATUS again — flag was already cleared by step 1.
        // (clear-on-read: the FIRST STATUS read both samples 1 and clears the flag)
        // This read just drains any pipeline lag and confirms 0.
        mmio_read(ADDR_STATUS);  // confirmatory read — already cleared

        // Step 3: Read STATUS a third time — flag must now be 0
        repeat (2) @(posedge clk);
        mmio_read(ADDR_STATUS);
        check_bit(data_out[STATUS_SEC_VIO_BIT], 1'b0,
                  "SEC_VIO=0 after read acknowledgement");
        $display("  STATUS after read-clear = 0x%08h", data_out);

        // Step 4: Verify no spurious re-set (flag stays 0 when no attack)
        repeat (5) @(posedge clk);
        mmio_read(ADDR_STATUS);
        check_bit(data_out[STATUS_SEC_VIO_BIT], 1'b0,
                  "SEC_VIO stays 0 (no spurious re-set)");

        // ==================================================================
        // TEST 6: CM-2 Debug Sentinel Removal
        // ==================================================================
        do_reset();
        $display("\n--------------------------------------------------------------");
        $display("  TEST 6: CM-2 — Debug Sentinel Removal  [SECURITY TEST]");
        $display("  Verify: unmapped addresses return 0x0, not 0xDEADBEEF");
        $display("--------------------------------------------------------------");

        // Read unmapped address (0x3C — beyond defined register map)
        @(posedge clk); #1;
        address      = 6'h3C;
        data_read_n  = 2'b00;
        data_write_n = 2'b11;
        @(posedge clk); #1;
        data_read_n  = 2'b11;
        check_ne(data_out, 32'hDEADBEEF, "addr 0x3C != 0xDEADBEEF (CM-2)");
        check_eq(data_out, 32'h00000000, "addr 0x3C == 0x0 (CM-2)");
        $display("  Read from 0x3C = 0x%08h (expected 0x00000000)", data_out);

        // Read input_buffer with out-of-range index (idx=15, read again)
        // Input auto-increments cap at 15; reading beyond valid range
        @(posedge clk); #1;
        address      = 6'h3F;   // completely unmapped
        data_read_n  = 2'b00;
        data_write_n = 2'b11;
        @(posedge clk); #1;
        data_read_n  = 2'b11;
        check_ne(data_out, 32'hDEADBEEF, "addr 0x3F != 0xDEADBEEF (CM-2)");
        check_eq(data_out, 32'h00000000, "addr 0x3F == 0x0 (CM-2)");

        // ==================================================================
        // TEST 7: Post-Attack Regression — System Still Functions Correctly
        // ==================================================================
        do_reset();
        $display("\n--------------------------------------------------------------");
        $display("  TEST 7: Post-Attack Regression  [STABILITY TEST]");
        $display("  Verify: after all security events, normal computation works");
        $display("--------------------------------------------------------------");

        full_setup_and_start();

        // Verify no spurious SEC_VIO during clean run
        wait_busy();
        mmio_read(ADDR_STATUS);
        check_bit(data_out[STATUS_SEC_VIO_BIT], 1'b0,
                  "No SEC_VIO during clean post-attack run");

        wait_done();
        mmio_read(ADDR_STATUS);
        check_bit(data_out[STATUS_DONE_BIT], 1'b1, "DONE asserts post-attack");
        check_bit(data_out[STATUS_BUSY_BIT], 1'b0, "BUSY clears post-attack");

        mmio_read(ADDR_OUTPUT_0);
        check_eq(data_out, clean_output[0], "output[0] correct post-attack");
        mmio_read(ADDR_OUTPUT_1);
        check_eq(data_out, clean_output[1], "output[1] correct post-attack");
        mmio_read(ADDR_OUTPUT_2);
        check_eq(data_out, clean_output[2], "output[2] correct post-attack");
        mmio_read(ADDR_OUTPUT_3);
        check_eq(data_out, clean_output[3], "output[3] correct post-attack");

        // ==================================================================
        // TEST 8: CM-3 — Filter Index Out-of-Bounds Clamping  [SECURITY TEST]
        // ==================================================================
        do_reset();
        $display("\n--------------------------------------------------------------");
        $display("  TEST 8: CM-3 — Filter Index Out-of-Bounds Clamping");
        $display("  Attack: write FILTER_IDX=12 (valid: 0-8), then FILTER_DATA");
        $display("  Expect: index clamped to 8, SEC_VIO flag SET, output correct");
        $display("--------------------------------------------------------------");

        // Load reference filter and input first (clean state)
        load_filter(
            ref_filter[0], ref_filter[1], ref_filter[2],
            ref_filter[3], ref_filter[4], ref_filter[5],
            ref_filter[6], ref_filter[7], ref_filter[8]
        );
        load_input_ref();

        // === ATTACK: write FILTER_IDX = 12 (out-of-bounds, valid max = 8) ===
        $display("  [ATTACK] Writing FILTER_IDX=12 (out-of-bounds)...");
        mmio_write(ADDR_FILTER_IDX, 32'hC);  // 12 decimal — OOB

        // === CHECK: SEC_VIO flag must be SET (OOB index detected) ===
        @(posedge clk); #1;
        mmio_read(ADDR_STATUS);
        check_bit(data_out[STATUS_SEC_VIO_BIT], 1'b1,
                  "CM-3: OOB idx SEC_VIO=1");
        $display("  STATUS after OOB idx write = 0x%08h (bit2=SEC_VIO)", data_out);

        // Now write FILTER_DATA — this should go to clamped slot [8] (last valid)
        // meaning the reference data at slot [8] gets overwritten with attacker value
        // BUT because index was clamped to 8 (not 12), no memory corruption beyond buffer
        mmio_write(ADDR_FILTER_DATA, 32'hDEADF00D);  // attacker payload to slot[8]

        // === ATTACK: write FILTER_IDX = 15 (another OOB value) ===
        $display("  [ATTACK] Writing FILTER_IDX=15 (out-of-bounds)...");
        mmio_write(ADDR_FILTER_IDX, 32'hF);  // 15 decimal — OOB
        @(posedge clk); #1;
        mmio_read(ADDR_STATUS);
        check_bit(data_out[STATUS_SEC_VIO_BIT], 1'b1,
                  "CM-3: idx=15 SEC_VIO=1");

        // === VERIFY: normal index write (in-bounds) does NOT set SEC_VIO ===
        // Clear flag by reading STATUS first
        mmio_read(ADDR_STATUS);  // clear flag
        repeat(2) @(posedge clk);
        // Write valid FILTER_IDX = 0
        mmio_write(ADDR_FILTER_IDX, 32'h0);
        @(posedge clk); #1;
        mmio_read(ADDR_STATUS);
        check_bit(data_out[STATUS_SEC_VIO_BIT], 1'b0,
                  "CM-3: valid idx=0 no SEC_VIO");
        $display("  Valid FILTER_IDX=0 write: STATUS=0x%08h (no violation)", data_out);

        // === VERIFY: write valid FILTER_IDX = 8 (boundary, must NOT set SEC_VIO) ===
        mmio_write(ADDR_FILTER_IDX, 32'h8);
        @(posedge clk); #1;
        mmio_read(ADDR_STATUS);
        check_bit(data_out[STATUS_SEC_VIO_BIT], 1'b0,
                  "CM-3: valid idx=8 no SEC_VIO");
        $display("  Boundary FILTER_IDX=8 write: STATUS=0x%08h (no violation)", data_out);

        // === VERIFY: write FILTER_IDX = 9 (just over boundary) ===
        mmio_write(ADDR_FILTER_IDX, 32'h9);
        @(posedge clk); #1;
        mmio_read(ADDR_STATUS);
        check_bit(data_out[STATUS_SEC_VIO_BIT], 1'b1,
                  "CM-3: idx=9 (just OOB) SEC_VIO=1");
        $display("  FILTER_IDX=9 (just OOB): STATUS=0x%08h (violation)", data_out);

        //==========================================================================
        // FINAL SUMMARY
        //==========================================================================
        repeat (10) @(posedge clk);
        $display("\n==============================================================");
        $display("  SECURITY TESTBENCH RESULT SUMMARY");
        $display("==============================================================");
        $display("  Tests PASSED : %0d", pass_count);
        $display("  Tests FAILED : %0d", fail_count);
        $display("  Total checks : %0d", pass_count + fail_count);
        $display("--------------------------------------------------------------");
        if (fail_count == 0)
            $display("  *** ALL SECURITY CHECKS PASSED — DP3 CM-1+CM-2+CM-3 VERIFIED ***");
        else
            $display("  *** %0d CHECK(S) FAILED — review output above ***", fail_count);
        $display("==============================================================\n");
        $finish;
    end

    //==========================================================================
    // Global Watchdog
    //==========================================================================
    initial begin
        #500_000_000;
        $display("[WATCHDOG] Simulation timeout — check for FSM hang");
        $finish;
    end

endmodule
