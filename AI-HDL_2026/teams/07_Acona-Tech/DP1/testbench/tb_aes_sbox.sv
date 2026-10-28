//============================================================================
// Module: tb_aes_sbox
// Description: Unit Testbench for AES S-Box Module
//              Verifies forward and inverse S-Box lookup tables
//
// Author: AIHDL 2026 Competition Team
// Date: January 2026
//============================================================================

`timescale 1ns / 1ps

module tb_aes_sbox;

    //------------------------------------------------------------------------
    // DUT Signals
    //------------------------------------------------------------------------
    reg  [7:0] data_in;
    reg        decrypt;
    wire [7:0] data_out;
    
    //------------------------------------------------------------------------
    // Test Variables
    //------------------------------------------------------------------------
    integer i;
    integer errors;
    reg [7:0] sbox_result;
    reg [7:0] inv_sbox_result;

    //------------------------------------------------------------------------
    // DUT Instantiation
    //------------------------------------------------------------------------
    aes_sbox u_dut (
        .data_in  (data_in),
        .decrypt  (decrypt),
        .data_out (data_out)
    );

    //------------------------------------------------------------------------
    // Known S-Box Test Values (from NIST FIPS-197)
    //------------------------------------------------------------------------
    // Forward S-Box: S[0x00] = 0x63, S[0x53] = 0xED, S[0xFF] = 0x16
    // Inverse S-Box: S^-1[0x63] = 0x00, S^-1[0xED] = 0x53, S^-1[0x16] = 0xFF

    //------------------------------------------------------------------------
    // Main Test Sequence
    //------------------------------------------------------------------------
    initial begin
        errors = 0;
        
        $display("");
        $display("============================================");
        $display("  AES S-Box Unit Test");
        $display("============================================");
        
        //--------------------------------------------------------------------
        // Test 1: Forward S-Box Known Values
        //--------------------------------------------------------------------
        $display("");
        $display("Test 1: Forward S-Box Known Values");
        decrypt = 0;
        
        // Test S[0x00] = 0x63
        data_in = 8'h00;
        #10;
        if (data_out === 8'h63) begin
            $display("  PASSED: S[0x00] = 0x%02h", data_out);
        end else begin
            $display("  FAILED: S[0x00] expected 0x63, got 0x%02h", data_out);
            errors = errors + 1;
        end
        
        // Test S[0x53] = 0xED
        data_in = 8'h53;
        #10;
        if (data_out === 8'hed) begin
            $display("  PASSED: S[0x53] = 0x%02h", data_out);
        end else begin
            $display("  FAILED: S[0x53] expected 0xED, got 0x%02h", data_out);
            errors = errors + 1;
        end
        
        // Test S[0xFF] = 0x16
        data_in = 8'hff;
        #10;
        if (data_out === 8'h16) begin
            $display("  PASSED: S[0xFF] = 0x%02h", data_out);
        end else begin
            $display("  FAILED: S[0xFF] expected 0x16, got 0x%02h", data_out);
            errors = errors + 1;
        end
        
        // Test S[0x2B] = 0xF1 (from NIST test vector key byte)
        data_in = 8'h2b;
        #10;
        if (data_out === 8'hf1) begin
            $display("  PASSED: S[0x2B] = 0x%02h", data_out);
        end else begin
            $display("  FAILED: S[0x2B] expected 0xF1, got 0x%02h", data_out);
            errors = errors + 1;
        end

        //--------------------------------------------------------------------
        // Test 2: Inverse S-Box Known Values
        //--------------------------------------------------------------------
        $display("");
        $display("Test 2: Inverse S-Box Known Values");
        decrypt = 1;
        
        // Test S^-1[0x63] = 0x00
        data_in = 8'h63;
        #10;
        if (data_out === 8'h00) begin
            $display("  PASSED: S^-1[0x63] = 0x%02h", data_out);
        end else begin
            $display("  FAILED: S^-1[0x63] expected 0x00, got 0x%02h", data_out);
            errors = errors + 1;
        end
        
        // Test S^-1[0xED] = 0x53
        data_in = 8'hed;
        #10;
        if (data_out === 8'h53) begin
            $display("  PASSED: S^-1[0xED] = 0x%02h", data_out);
        end else begin
            $display("  FAILED: S^-1[0xED] expected 0x53, got 0x%02h", data_out);
            errors = errors + 1;
        end
        
        // Test S^-1[0x16] = 0xFF
        data_in = 8'h16;
        #10;
        if (data_out === 8'hff) begin
            $display("  PASSED: S^-1[0x16] = 0x%02h", data_out);
        end else begin
            $display("  FAILED: S^-1[0x16] expected 0xFF, got 0x%02h", data_out);
            errors = errors + 1;
        end

        //--------------------------------------------------------------------
        // Test 3: S-Box Inverse Property (S^-1[S[x]] = x)
        //--------------------------------------------------------------------
        $display("");
        $display("Test 3: S-Box Inverse Property (S^-1[S[x]] = x)");
        
        for (i = 0; i < 256; i = i + 1) begin
            // Forward S-Box
            decrypt = 0;
            data_in = i[7:0];
            #5;
            sbox_result = data_out;
            
            // Inverse S-Box
            decrypt = 1;
            data_in = sbox_result;
            #5;
            inv_sbox_result = data_out;
            
            if (inv_sbox_result !== i[7:0]) begin
                $display("  FAILED: S^-1[S[0x%02h]] = 0x%02h (expected 0x%02h)", 
                         i[7:0], inv_sbox_result, i[7:0]);
                errors = errors + 1;
            end
        end
        
        if (errors == 0) begin
            $display("  PASSED: All 256 values satisfy S^-1[S[x]] = x");
        end

        //--------------------------------------------------------------------
        // Test Summary
        //--------------------------------------------------------------------
        $display("");
        $display("============================================");
        $display("  S-Box Unit Test Summary");
        $display("============================================");
        $display("  Errors: %0d", errors);
        
        if (errors == 0) begin
            $display("  *** ALL S-BOX TESTS PASSED ***");
        end else begin
            $display("  *** S-BOX TESTS FAILED ***");
        end
        $display("============================================");
        
        $finish;
    end

endmodule
