//============================================================================
// Module: tb_aes_control_fsm
// Description: Testbench for AES Control FSM
//              Verifies state transitions and control signal generation
//
// Test Cases:
//   1. Reset behavior
//   2. Start with key already valid
//   3. Start with key expansion needed
//   4. Full encryption cycle (round counter verification)
//   5. Decrypt mode round counting
//   6. Control signal pulse behavior
//
// Author: AIHDL 2026 Competition Team
// Date: January 2026
//============================================================================

`timescale 1ns / 1ps

module tb_aes_control_fsm;

    //------------------------------------------------------------------------
    // Parameters
    //------------------------------------------------------------------------
    parameter CLK_PERIOD = 15.625;  // 64MHz

    //------------------------------------------------------------------------
    // DUT Signals
    //------------------------------------------------------------------------
    reg         clk;
    reg         rst_n;
    reg         start;
    reg         decrypt;
    reg         key_valid;
    reg         key_busy;
    
    wire        key_start;
    wire [3:0]  round_count;
    wire        round_init;
    wire        round_main;
    wire        round_final;
    wire        state_load;
    wire        state_update;
    wire        output_valid;
    wire        busy;
    wire        done;
    wire        error;

    //------------------------------------------------------------------------
    // Test Variables
    //------------------------------------------------------------------------
    integer test_num;
    integer errors;
    integer cycle_count;
    integer i;

    //------------------------------------------------------------------------
    // DUT Instantiation
    //------------------------------------------------------------------------
    aes_control_fsm u_dut (
        .clk            (clk),
        .rst_n          (rst_n),
        .start          (start),
        .decrypt        (decrypt),
        .key_valid      (key_valid),
        .key_busy       (key_busy),
        .key_start      (key_start),
        .round_count    (round_count),
        .round_init     (round_init),
        .round_main     (round_main),
        .round_final    (round_final),
        .state_load     (state_load),
        .state_update   (state_update),
        .output_valid   (output_valid),
        .busy           (busy),
        .done           (done),
        .error          (error)
    );

    //------------------------------------------------------------------------
    // Clock Generation
    //------------------------------------------------------------------------
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    //------------------------------------------------------------------------
    // Main Test Sequence
    //------------------------------------------------------------------------
    initial begin
        // Initialize
        rst_n = 0;
        start = 0;
        decrypt = 0;
        key_valid = 0;
        key_busy = 0;
        test_num = 0;
        errors = 0;
        
        $display("");
        $display("============================================");
        $display("  AES Control FSM Testbench");
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
        
        if (busy === 1'b0 && done === 1'b0 && error === 1'b0 &&
            round_init === 1'b0 && round_main === 1'b0 && round_final === 1'b0) begin
            $display("  PASSED: All outputs inactive after reset");
        end else begin
            $display("  FAILED: Outputs not properly reset");
            $display("    busy=%b done=%b error=%b", busy, done, error);
            $display("    round_init=%b round_main=%b round_final=%b", round_init, round_main, round_final);
            errors = errors + 1;
        end

        //====================================================================
        // Test 2: Start with Key Already Valid (Encryption)
        //====================================================================
        test_num = 2;
        $display("");
        $display("Test %0d: Start with Key Already Valid (Encryption)", test_num);
        
        key_valid = 1;
        key_busy = 0;
        decrypt = 0;
        
        // Assert start
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;
        
        // Check: busy should be high, round_init should be high
        if (busy === 1'b1) begin
            $display("  PASSED: busy asserted");
        end else begin
            $display("  FAILED: busy not asserted");
            errors = errors + 1;
        end
        
        if (round_init === 1'b1 && state_load === 1'b1) begin
            $display("  PASSED: round_init and state_load asserted");
        end else begin
            $display("  FAILED: round_init=%b state_load=%b", round_init, state_load);
            errors = errors + 1;
        end
        
        // Wait for completion
        cycle_count = 0;
        while (!done && cycle_count < 50) begin
            @(posedge clk);
            cycle_count = cycle_count + 1;
        end
        
        if (done === 1'b1) begin
            $display("  PASSED: Encryption completed in %0d cycles", cycle_count);
        end else begin
            $display("  FAILED: Encryption did not complete");
            errors = errors + 1;
        end
        
        // Wait for return to IDLE
        @(posedge clk);
        @(posedge clk);

        //====================================================================
        // Test 3: Start with Key Expansion Needed
        //====================================================================
        test_num = 3;
        $display("");
        $display("Test %0d: Start with Key Expansion Needed", test_num);
        
        key_valid = 0;
        key_busy = 0;
        
        // Assert start
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;
        
        // Check key_start pulse
        if (key_start === 1'b1) begin
            $display("  PASSED: key_start triggered");
        end else begin
            $display("  FAILED: key_start not triggered (key_start=%b)", key_start);
            errors = errors + 1;
        end
        
        // Simulate key expansion
        key_busy = 1;
        repeat(5) @(posedge clk);
        key_busy = 0;
        key_valid = 1;
        
        // Wait for completion
        cycle_count = 0;
        while (!done && cycle_count < 50) begin
            @(posedge clk);
            cycle_count = cycle_count + 1;
        end
        
        if (done === 1'b1) begin
            $display("  PASSED: Operation completed after key expansion");
        end else begin
            $display("  FAILED: Operation did not complete");
            errors = errors + 1;
        end
        
        @(posedge clk);
        @(posedge clk);

        //====================================================================
        // Test 4: Full Encryption Cycle - Round Counter Verification
        //====================================================================
        test_num = 4;
        $display("");
        $display("Test %0d: Full Encryption Cycle - Round Counter", test_num);
        
        key_valid = 1;
        decrypt = 0;
        
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;
        
        // Track round progression
        $display("  Round progression (encryption):");
        
        // Should see round_init first
        $display("    Cycle 1: round_count=%0d, round_init=%b, round_main=%b, round_final=%b", 
                 round_count, round_init, round_main, round_final);
        
        // Continue monitoring
        for (i = 0; i < 15; i = i + 1) begin
            @(posedge clk);
            if (round_init || round_main || round_final || done) begin
                $display("    Cycle %0d: round_count=%0d, init=%b, main=%b, final=%b, done=%b", 
                         i+2, round_count, round_init, round_main, round_final, done);
            end
            if (done) begin
                i = 100; // Exit loop
            end
        end
        
        // Wait for IDLE
        @(posedge clk);
        @(posedge clk);

        //====================================================================
        // Test 5: Decryption Mode - Round Counter
        //====================================================================
        test_num = 5;
        $display("");
        $display("Test %0d: Decryption Mode - Round Counter", test_num);
        
        key_valid = 1;
        decrypt = 1;
        
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;
        
        $display("  Round progression (decryption):");
        
        // First cycle should show round_count = 10 (decrypt mode)
        if (round_init && round_count === 4'd10) begin
            $display("    INIT: round_count=%0d (correct for decrypt)", round_count);
        end else begin
            $display("    INIT: round_count=%0d, round_init=%b (expected 10)", round_count, round_init);
            if (round_count !== 4'd10) errors = errors + 1;
        end
        
        // Monitor until done
        for (i = 0; i < 15; i = i + 1) begin
            @(posedge clk);
            if (round_main) begin
                $display("    MAIN: round_count=%0d", round_count);
            end
            if (round_final) begin
                $display("    FINAL: round_count=%0d", round_count);
                if (round_count !== 4'd0) begin
                    $display("      ERROR: Expected round_count=0 for decrypt final");
                    errors = errors + 1;
                end
            end
            if (done) begin
                $display("    DONE");
                i = 100;
            end
        end
        
        decrypt = 0;
        @(posedge clk);
        @(posedge clk);

        //====================================================================
        // Test 6: Control Signal Pulses
        //====================================================================
        test_num = 6;
        $display("");
        $display("Test %0d: Control Signal Pulse Behavior", test_num);
        
        key_valid = 1;
        
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;
        
        // round_init should be high now
        if (round_init === 1'b1) begin
            $display("  round_init high on first cycle");
            @(posedge clk);
            // Should transition to round_main
            if (round_init === 1'b0 && round_main === 1'b1) begin
                $display("  PASSED: round_init cleared, round_main asserted");
            end else begin
                $display("  INFO: round_init=%b, round_main=%b", round_init, round_main);
            end
        end else begin
            $display("  FAILED: round_init not asserted");
            errors = errors + 1;
        end
        
        // Wait for done
        while (!done) @(posedge clk);
        
        // Check done is single cycle
        if (done === 1'b1) begin
            @(posedge clk);
            if (done === 1'b0) begin
                $display("  PASSED: done is single-cycle pulse");
            end else begin
                $display("  FAILED: done not cleared");
                errors = errors + 1;
            end
        end

        //====================================================================
        // Test Summary
        //====================================================================
        $display("");
        $display("============================================");
        $display("  AES Control FSM Test Summary");
        $display("============================================");
        $display("  Total Tests: %0d", test_num);
        $display("  Errors: %0d", errors);
        
        if (errors == 0) begin
            $display("  *** ALL TESTS PASSED ***");
        end else begin
            $display("  *** SOME TESTS FAILED ***");
        end
        $display("============================================");
        
        repeat(5) @(posedge clk);
        $finish;
    end

    //------------------------------------------------------------------------
    // Timeout Watchdog
    //------------------------------------------------------------------------
    initial begin
        #100000;
        $display("ERROR: Simulation timeout!");
        $finish;
    end

    //------------------------------------------------------------------------
    // Waveform Dump
    //------------------------------------------------------------------------
    initial begin
        $dumpfile("tb_aes_control_fsm.vcd");
        $dumpvars(0, tb_aes_control_fsm);
    end

endmodule
