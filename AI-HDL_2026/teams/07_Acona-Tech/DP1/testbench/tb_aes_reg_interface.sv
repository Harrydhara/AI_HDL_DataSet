//============================================================================
// Module: tb_aes_reg_interface
// Description: Testbench for AES Register Interface
//              Verifies memory-mapped register read/write operations
//
// NOTE (FIX): Test 7 (Start Pulse Generation) was failing because the TB was
// checking `start` one cycle after the CTRL write. Many register interfaces
// assert `start` in the SAME cycle the write is accepted, so the TB could miss
// a valid single-cycle pulse.
//
// This version adds a small pulse counter (enabled only around Test 7) so the
// TB detects the pulse regardless of whether it occurs during the write cycle
// or the following cycle, and still enforces "single-cycle" behavior.
//
// Author: AIHDL 2026 Competition Team
// Date: January 2026
//============================================================================

`timescale 1ns / 1ps

module tb_aes_reg_interface;

    //------------------------------------------------------------------------
    // Parameters
    //------------------------------------------------------------------------
    parameter CLK_PERIOD = 15.625;  // 64MHz

    //------------------------------------------------------------------------
    // DUT Signals
    //------------------------------------------------------------------------
    reg          clk;
    reg          rst_n;

    // TinyQV Bus
    reg  [5:0]   address;
    reg  [31:0]  data_in;
    reg  [1:0]   data_write_n;
    reg  [1:0]   data_read_n;
    wire [31:0]  data_out;
    wire         data_ready;

    // AES Core Interface
    wire [127:0] key_reg;
    wire [127:0] din_reg;
    reg  [127:0] dout_reg;
    wire         start;
    wire         decrypt;
    reg          busy;
    reg          done;
    wire         key_load;
    reg          key_valid;
    reg          key_busy;

    // Interrupt
    wire         user_interrupt;

    //------------------------------------------------------------------------
    // Test Variables
    //------------------------------------------------------------------------
    integer test_num;
    integer errors;
    reg [31:0] read_data;

    //------------------------------------------------------------------------
    // Start pulse monitor (FIX for Test 7)
    //------------------------------------------------------------------------
    reg     start_mon_en;
    integer start_pulse_count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            start_pulse_count <= 0;
        end else if (start_mon_en) begin
            if (start) start_pulse_count <= start_pulse_count + 1;
        end
    end

    //------------------------------------------------------------------------
    // Register Addresses
    //------------------------------------------------------------------------
    localparam [5:0] ADDR_CTRL     = 6'h00;
    localparam [5:0] ADDR_STATUS   = 6'h04;
    localparam [5:0] ADDR_INT_EN   = 6'h08;
    localparam [5:0] ADDR_INT_STAT = 6'h0C;
    localparam [5:0] ADDR_KEY0     = 6'h10;
    localparam [5:0] ADDR_KEY1     = 6'h14;
    localparam [5:0] ADDR_KEY2     = 6'h18;
    localparam [5:0] ADDR_KEY3     = 6'h1C;
    localparam [5:0] ADDR_DIN0     = 6'h20;
    localparam [5:0] ADDR_DIN1     = 6'h24;
    localparam [5:0] ADDR_DIN2     = 6'h28;
    localparam [5:0] ADDR_DIN3     = 6'h2C;
    localparam [5:0] ADDR_DOUT0    = 6'h30;
    localparam [5:0] ADDR_DOUT1    = 6'h34;
    localparam [5:0] ADDR_DOUT2    = 6'h38;
    localparam [5:0] ADDR_DOUT3    = 6'h3C;

    //------------------------------------------------------------------------
    // DUT Instantiation
    //------------------------------------------------------------------------
    aes_reg_interface u_dut (
        .clk            (clk),
        .rst_n          (rst_n),
        .address        (address),
        .data_in        (data_in),
        .data_write_n   (data_write_n),
        .data_read_n    (data_read_n),
        .data_out       (data_out),
        .data_ready     (data_ready),
        .key_reg        (key_reg),
        .din_reg        (din_reg),
        .dout_reg       (dout_reg),
        .start          (start),
        .decrypt        (decrypt),
        .busy           (busy),
        .done           (done),
        .key_load       (key_load),
        .key_valid      (key_valid),
        .key_busy       (key_busy),
        .user_interrupt (user_interrupt)
    );

    //------------------------------------------------------------------------
    // Clock Generation
    //------------------------------------------------------------------------
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    //------------------------------------------------------------------------
    // Task: Write Register
    //------------------------------------------------------------------------
    task write_reg;
        input [5:0]  addr;
        input [31:0] wdata;
        begin
            @(posedge clk);
            address <= addr;
            data_in <= wdata;
            data_write_n <= 2'b10;  // 32-bit write
            data_read_n <= 2'b11;   // No read
            @(posedge clk);
            data_write_n <= 2'b11;
            @(posedge clk);
        end
    endtask

    //------------------------------------------------------------------------
    // Task: Read Register
    //------------------------------------------------------------------------
    task read_reg;
        input  [5:0]  addr;
        output [31:0] rdata;
        begin
            @(posedge clk);
            address <= addr;
            data_write_n <= 2'b11;  // No write
            data_read_n <= 2'b10;   // 32-bit read
            @(posedge clk);
            while (!data_ready) @(posedge clk);
            rdata = data_out;
            data_read_n <= 2'b11;
            @(posedge clk);
        end
    endtask

    //------------------------------------------------------------------------
    // Main Test Sequence
    //------------------------------------------------------------------------
    initial begin
        // Initialize
        rst_n = 0;
        address = 6'h00;
        data_in = 32'd0;
        data_write_n = 2'b11;
        data_read_n = 2'b11;
        dout_reg = 128'hDEADBEEFCAFEBABE0123456789ABCDEF;
        busy = 0;
        done = 0;
        key_valid = 0;
        key_busy = 0;
        test_num = 0;
        errors = 0;

        start_mon_en = 0;
        start_pulse_count = 0;

        $display("");
        $display("============================================");
        $display("  AES Register Interface Testbench");
        $display("============================================");

        // Reset
        repeat(5) @(posedge clk);
        rst_n = 1;
        repeat(2) @(posedge clk);

        //====================================================================
        // Test 1: Reset Behavior
        //====================================================================
        test_num = 1;
        $display("");
        $display("Test %0d: Reset Behavior", test_num);

        read_reg(ADDR_CTRL, read_data);
        if (read_data[1:0] === 2'b00) begin
            $display("  PASSED: CTRL register reset to 0");
        end else begin
            $display("  FAILED: CTRL register not reset");
            errors = errors + 1;
        end

        //====================================================================
        // Test 2: Control Register Write/Read
        //====================================================================
        test_num = 2;
        $display("");
        $display("Test %0d: Control Register Write/Read", test_num);

        // Write MODE bit (bit 1)
        write_reg(ADDR_CTRL, 32'h02);  // MODE=1 (decrypt)
        read_reg(ADDR_CTRL, read_data);

        if (read_data[1] === 1'b1) begin
            $display("  PASSED: MODE bit writable and readable");
        end else begin
            $display("  FAILED: MODE bit not set correctly");
            errors = errors + 1;
        end

        if (decrypt === 1'b1) begin
            $display("  PASSED: decrypt output reflects MODE bit");
        end else begin
            $display("  FAILED: decrypt output incorrect");
            errors = errors + 1;
        end

        // Clear MODE
        write_reg(ADDR_CTRL, 32'h00);

        //====================================================================
        // Test 3: Status Register Read
        //====================================================================
        test_num = 3;
        $display("");
        $display("Test %0d: Status Register Read", test_num);

        busy = 1;
        key_valid = 1;
        @(posedge clk);

        read_reg(ADDR_STATUS, read_data);
        $display("  STATUS: BUSY=%b, DONE=%b, KEY_VALID=%b",
                 read_data[0], read_data[1], read_data[3]);

        if (read_data[0] === 1'b1 && read_data[3] === 1'b1) begin
            $display("  PASSED: Status register reflects inputs");
        end else begin
            $display("  FAILED: Status register incorrect");
            errors = errors + 1;
        end

        busy = 0;
        key_valid = 0;

        //====================================================================
        // Test 4: Key Register Write-Only Security
        //====================================================================
        test_num = 4;
        $display("");
        $display("Test %0d: Key Register Write-Only Security", test_num);

        // Write key
        write_reg(ADDR_KEY0, 32'h2b7e1516);
        write_reg(ADDR_KEY1, 32'h28aed2a6);
        write_reg(ADDR_KEY2, 32'habf71588);
        write_reg(ADDR_KEY3, 32'h09cf4f3c);

        // Verify key_reg output
        if (key_reg === 128'h2b7e151628aed2a6abf7158809cf4f3c) begin
            $display("  PASSED: Key written correctly to output");
        end else begin
            $display("  FAILED: Key not written correctly");
            $display("    Expected: 2b7e151628aed2a6abf7158809cf4f3c");
            $display("    Got:      %h", key_reg);
            errors = errors + 1;
        end

        // Try to read key back - should return 0
        read_reg(ADDR_KEY0, read_data);
        if (read_data === 32'h00000000) begin
            $display("  PASSED: Key register is write-only (reads as 0)");
        end else begin
            $display("  FAILED: Key register readable (security issue!)");
            errors = errors + 1;
        end

        //====================================================================
        // Test 5: Data Input Register Write
        //====================================================================
        test_num = 5;
        $display("");
        $display("Test %0d: Data Input Register Write", test_num);

        write_reg(ADDR_DIN0, 32'h3243f6a8);
        write_reg(ADDR_DIN1, 32'h885a308d);
        write_reg(ADDR_DIN2, 32'h313198a2);
        write_reg(ADDR_DIN3, 32'he0370734);

        if (din_reg === 128'h3243f6a8885a308d313198a2e0370734) begin
            $display("  PASSED: Data input written correctly");
        end else begin
            $display("  FAILED: Data input incorrect");
            $display("    Expected: 3243f6a8885a308d313198a2e0370734");
            $display("    Got:      %h", din_reg);
            errors = errors + 1;
        end

        //====================================================================
        // Test 6: Data Output Register Read
        //====================================================================
        test_num = 6;
        $display("");
        $display("Test %0d: Data Output Register Read", test_num);

        dout_reg = 128'h3925841d02dc09fbdc118597196a0b32;
        busy = 0;  // Not busy, so read should work

        read_reg(ADDR_DOUT0, read_data);
        if (read_data === 32'h3925841d) begin
            $display("  PASSED: DOUT0 read correctly");
        end else begin
            $display("  FAILED: DOUT0 incorrect: %h", read_data);
            errors = errors + 1;
        end

        read_reg(ADDR_DOUT3, read_data);
        if (read_data === 32'h196a0b32) begin
            $display("  PASSED: DOUT3 read correctly");
        end else begin
            $display("  FAILED: DOUT3 incorrect: %h", read_data);
            errors = errors + 1;
        end

        //====================================================================
        // Test 7: Start Pulse Generation (FIXED)
        //====================================================================
        test_num = 7;
        $display("");
        $display("Test %0d: Start Pulse Generation", test_num);

        // Preconditions
        key_valid = 1;

        // Write data input registers first (required for start)
        write_reg(ADDR_DIN0, 32'h11111111);
        write_reg(ADDR_DIN1, 32'h22222222);
        write_reg(ADDR_DIN2, 32'h33333333);
        write_reg(ADDR_DIN3, 32'h44444444);

        // Clear CTRL first to ensure rising edge
        write_reg(ADDR_CTRL, 32'h00);
        @(posedge clk);

        // Arm start pulse monitor BEFORE issuing START write
        start_pulse_count = 0;
        start_mon_en = 1;

        // Write START bit
        write_reg(ADDR_CTRL, 32'h01);

        // Keep monitoring a couple cycles to catch either "same-cycle" or "next-cycle" pulses
        repeat(2) @(posedge clk);
        start_mon_en = 0;

        if (start_pulse_count == 1) begin
            $display("  PASSED: Start is a single-cycle pulse (count=%0d)", start_pulse_count);
        end else if (start_pulse_count == 0) begin
            $display("  FAILED: Start pulse not generated (count=%0d)", start_pulse_count);
            errors = errors + 1;
        end else begin
            $display("  FAILED: Start pulse width too long (count=%0d cycles)", start_pulse_count);
            errors = errors + 1;
        end

        // Extra sanity: must not be stuck high right now
        if (start === 1'b0) begin
            $display("  PASSED: Start deasserted after pulse");
        end else begin
            $display("  FAILED: Start still asserted (not self-clearing)");
            errors = errors + 1;
        end

        key_valid = 0;

        //====================================================================
        // Test 8: Interrupt Enable Register
        //====================================================================
        test_num = 8;
        $display("");
        $display("Test %0d: Interrupt Enable Register", test_num);

        write_reg(ADDR_INT_EN, 32'h03);  // Enable DONE and ERROR interrupts
        read_reg(ADDR_INT_EN, read_data);

        if (read_data[1:0] === 2'b11) begin
            $display("  PASSED: Interrupt enable bits set");
        end else begin
            $display("  FAILED: Interrupt enable incorrect");
            errors = errors + 1;
        end

        //====================================================================
        // Test 9: Interrupt Generation
        //====================================================================
        test_num = 9;
        $display("");
        $display("Test %0d: Interrupt Generation", test_num);

        // Simulate done pulse
        done = 1;
        @(posedge clk);
        done = 0;
        @(posedge clk);

        // Check interrupt
        if (user_interrupt === 1'b1) begin
            $display("  PASSED: Interrupt generated on done");
        end else begin
            $display("  FAILED: Interrupt not generated");
            errors = errors + 1;
        end

        // Read interrupt status
        read_reg(ADDR_INT_STAT, read_data);
        if (read_data[0] === 1'b1) begin
            $display("  PASSED: DONE interrupt flag set");
        end else begin
            $display("  FAILED: DONE interrupt flag not set");
            errors = errors + 1;
        end

        //====================================================================
        // Test 10: Interrupt Clear (W1C)
        //====================================================================
        test_num = 10;
        $display("");
        $display("Test %0d: Interrupt Clear (W1C)", test_num);

        // Write 1 to clear
        write_reg(ADDR_INT_STAT, 32'h01);

        read_reg(ADDR_INT_STAT, read_data);
        if (read_data[0] === 1'b0) begin
            $display("  PASSED: Interrupt cleared by W1C");
        end else begin
            $display("  FAILED: Interrupt not cleared");
            errors = errors + 1;
        end

        if (user_interrupt === 1'b0) begin
            $display("  PASSED: Interrupt output deasserted");
        end else begin
            $display("  FAILED: Interrupt still asserted");
            errors = errors + 1;
        end

        //====================================================================
        // Test Summary
        //====================================================================
        $display("");
        $display("============================================");
        $display("  AES Register Interface Test Summary");
        $display("============================================");
        $display("  Total Tests: %0d", test_num);
        $display("  Errors: %0d", errors);

        if (errors == 0) begin
            $display("  *** ALL TESTS PASSED ***");
        end else begin
            $display("  *** TESTS FAILED ***");
        end
        $display("============================================");

        repeat(5) @(posedge clk);
        $finish;
    end

    //------------------------------------------------------------------------
    // Timeout Watchdog
    //------------------------------------------------------------------------
    initial begin
        #500000;
        $display("ERROR: Simulation timeout!");
        $finish;
    end

    //------------------------------------------------------------------------
    // Waveform Dump
    //------------------------------------------------------------------------
    initial begin
        $dumpfile("tb_aes_reg_interface.vcd");
        $dumpvars(0, tb_aes_reg_interface);
    end

endmodule
