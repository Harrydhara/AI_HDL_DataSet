//============================================================================
// Module: tb_aes_key_expansion
// Description: Unit Testbench for AES Key Expansion Module
//              Verifies round key generation against NIST FIPS-197
//
// Author: AIHDL 2026 Competition Team
// Date: January 2026
//============================================================================

`timescale 1ns / 1ps

module tb_aes_key_expansion;

    //------------------------------------------------------------------------
    // Parameters
    //------------------------------------------------------------------------
    parameter CLK_PERIOD = 10;  // 100MHz for testing

    //------------------------------------------------------------------------
    // DUT Signals
    //------------------------------------------------------------------------
    reg          clk;
    reg          rst_n;
    reg  [127:0] cipher_key;
    reg          key_load;
    reg  [3:0]   round_num;
    reg          decrypt;
    wire [127:0] round_key;
    wire         key_valid;
    wire         key_busy;
    
    //------------------------------------------------------------------------
    // Test Variables
    //------------------------------------------------------------------------
    integer errors;
    reg [127:0] expected_keys [0:10];

    //------------------------------------------------------------------------
    // DUT Instantiation
    //------------------------------------------------------------------------
    aes_key_expansion u_dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .cipher_key (cipher_key),
        .key_load   (key_load),
        .round_num  (round_num),
        .decrypt    (decrypt),
        .round_key  (round_key),
        .key_valid  (key_valid),
        .key_busy   (key_busy)
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
        errors = 0;
        
        // Initialize expected round keys from NIST FIPS-197 Appendix A.1
        // Key = 2b7e1516 28aed2a6 abf71588 09cf4f3c
        expected_keys[0]  = 128'h2b7e151628aed2a6abf7158809cf4f3c;  // Round 0
        expected_keys[1]  = 128'ha0fafe1788542cb123a339392a6c7605;  // Round 1
        expected_keys[2]  = 128'hf2c295f27a96b9435935807a7359f67f;  // Round 2
        expected_keys[3]  = 128'h3d80477d4716fe3e1e237e446d7a883b;  // Round 3
        expected_keys[4]  = 128'hef44a541a8525b7fb671253bdb0bad00;  // Round 4
        expected_keys[5]  = 128'hd4d1c6f87c839d87caf2b8bc11f915bc;  // Round 5
        expected_keys[6]  = 128'h6d88a37a110b3efddbf98641ca0093fd;  // Round 6
        expected_keys[7]  = 128'h4e54f70e5f5fc9f384a64fb24ea6dc4f;  // Round 7
        expected_keys[8]  = 128'head27321b58dbad2312bf5607f8d292f;  // Round 8
        expected_keys[9]  = 128'hac7766f319fadc2128d12941575c006e;  // Round 9
        expected_keys[10] = 128'hd014f9a8c9ee2589e13f0cc8b6630ca6;  // Round 10

        // Initialize
        rst_n = 0;
        cipher_key = 128'h0;
        key_load = 0;
        round_num = 0;
        decrypt = 0;
        
        $display("");
        $display("============================================");
        $display("  AES Key Expansion Unit Test");
        $display("============================================");
        
        // Reset
        repeat(5) @(posedge clk);
        rst_n = 1;
        repeat(2) @(posedge clk);

        //--------------------------------------------------------------------
        // Test 1: Key Expansion with NIST FIPS-197 Appendix A.1 Key
        //--------------------------------------------------------------------
        $display("");
        $display("Test 1: Key Expansion (NIST FIPS-197 Appendix A.1)");
        $display("  Key: 2b7e151628aed2a6abf7158809cf4f3c");
        
        cipher_key = 128'h2b7e151628aed2a6abf7158809cf4f3c;
        
        // Trigger key load
        @(posedge clk);
        key_load = 1;
        @(posedge clk);
        key_load = 0;
        
        // Wait for key expansion to complete
        while (!key_valid) begin
            @(posedge clk);
        end
        
        $display("  Key expansion complete in %0d cycles", $time / CLK_PERIOD);
        
        // Verify all round keys
        $display("");
        $display("  Verifying Round Keys:");
        
        begin : verify_keys
            integer i;
            for (i = 0; i <= 10; i = i + 1) begin
                round_num = i[3:0];
                decrypt = 0;
                @(posedge clk);
                #1;  // Small delay for combinational logic
                
                if (round_key === expected_keys[i]) begin
                    $display("    Round %2d: PASSED - %h", i, round_key);
                end else begin
                    $display("    Round %2d: FAILED", i);
                    $display("      Expected: %h", expected_keys[i]);
                    $display("      Got:      %h", round_key);
                    errors = errors + 1;
                end
            end
        end

        //--------------------------------------------------------------------
        // Test 2: Decrypt Mode Key Order
        //--------------------------------------------------------------------
        $display("");
        $display("Test 2: Decrypt Mode Key Order (Reversed)");
        
        decrypt = 1;
        
        begin : verify_decrypt_keys
            integer i;
            for (i = 0; i <= 10; i = i + 1) begin
                round_num = i[3:0];
                @(posedge clk);
                #1;
                
                // In decrypt mode, round_num=0 should give key[10], round_num=10 should give key[0]
                if (round_key === expected_keys[10-i]) begin
                    $display("    Decrypt Round %2d: PASSED - maps to Enc Round %2d", i, 10-i);
                end else begin
                    $display("    Decrypt Round %2d: FAILED", i);
                    $display("      Expected: %h (Enc Round %2d)", expected_keys[10-i], 10-i);
                    $display("      Got:      %h", round_key);
                    errors = errors + 1;
                end
            end
        end

        //--------------------------------------------------------------------
        // Test 3: All-Zeros Key Expansion
        //--------------------------------------------------------------------
        $display("");
        $display("Test 3: All-Zeros Key Expansion");
        
        cipher_key = 128'h00000000000000000000000000000000;
        decrypt = 0;
        
        @(posedge clk);
        key_load = 1;
        @(posedge clk);
        key_load = 0;
        
        while (!key_valid) begin
            @(posedge clk);
        end
        
        // Verify round 0 key is all zeros
        round_num = 0;
        @(posedge clk);
        #1;
        
        if (round_key === 128'h00000000000000000000000000000000) begin
            $display("  PASSED: Round 0 key is all zeros");
        end else begin
            $display("  FAILED: Round 0 key should be all zeros");
            $display("    Got: %h", round_key);
            errors = errors + 1;
        end
        
        // Round 1 key for all-zeros input should be:
        // SubWord(RotWord(00000000)) XOR Rcon[1] = 63636363 XOR 01000000 = 62636363
        // W4 = 00000000 XOR 62636363 = 62636363
        // W5 = 00000000 XOR 62636363 = 62636363
        // W6 = 00000000 XOR 62636363 = 62636363
        // W7 = 00000000 XOR 62636363 = 62636363
        round_num = 1;
        @(posedge clk);
        #1;
        
        if (round_key === 128'h62636363626363636263636362636363) begin
            $display("  PASSED: Round 1 key correct for all-zeros input");
        end else begin
            $display("  FAILED: Round 1 key incorrect");
            $display("    Expected: 62636363626363636263636362636363");
            $display("    Got:      %h", round_key);
            errors = errors + 1;
        end

        //--------------------------------------------------------------------
        // Test 4: Key Busy Signal
        //--------------------------------------------------------------------
        $display("");
        $display("Test 4: Key Busy Signal During Expansion");
        
        cipher_key = 128'hffffffffffffffffffffffffffffffff;
        
        @(posedge clk);
        key_load = 1;
        @(posedge clk);
        key_load = 0;
        
        // Check that key_busy is asserted
        @(posedge clk);
        if (key_busy === 1'b1) begin
            $display("  PASSED: key_busy asserted during expansion");
        end else begin
            $display("  FAILED: key_busy not asserted");
            errors = errors + 1;
        end
        
        // Wait for completion
        while (!key_valid) begin
            @(posedge clk);
        end
        
        // Check that key_busy is deasserted
        if (key_busy === 1'b0) begin
            $display("  PASSED: key_busy deasserted after completion");
        end else begin
            $display("  FAILED: key_busy still asserted");
            errors = errors + 1;
        end

        //--------------------------------------------------------------------
        // Test Summary
        //--------------------------------------------------------------------
        $display("");
        $display("============================================");
        $display("  Key Expansion Unit Test Summary");
        $display("============================================");
        $display("  Errors: %0d", errors);
        
        if (errors == 0) begin
            $display("  *** ALL KEY EXPANSION TESTS PASSED ***");
        end else begin
            $display("  *** KEY EXPANSION TESTS FAILED ***");
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

endmodule
