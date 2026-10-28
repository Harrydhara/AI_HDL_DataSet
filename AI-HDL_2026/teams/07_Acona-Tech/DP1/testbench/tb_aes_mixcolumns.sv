//============================================================================
// Testbench: tb_aes_mixcolumns
// Description: Comprehensive testbench for AES MixColumns/InvMixColumns module
//
// IMPORTANT: NIST FIPS-197 state representation
//   The AES state is a 4x4 matrix of bytes, stored in COLUMN-MAJOR order:
//   
//   State matrix:        Byte numbering:
//   | s0,0  s0,1  s0,2  s0,3 |    | 0  4  8  12 |
//   | s1,0  s1,1  s1,2  s1,3 | => | 1  5  9  13 |
//   | s2,0  s2,1  s2,2  s2,3 |    | 2  6  10 14 |
//   | s3,0  s3,1  s3,2  s3,3 |    | 3  7  11 15 |
//
//   128-bit vector: {byte0, byte1, ..., byte15} = state[127:0]
//   where byte0 = state[127:120], byte15 = state[7:0]
//
// Author: AIHDL 2026 Competition Team (Team Acona)
// Date: January 2026
//============================================================================

`timescale 1ns / 1ps

module tb_aes_mixcolumns;

    //------------------------------------------------------------------------
    // Test Signals
    //------------------------------------------------------------------------
    reg  [127:0] state_in;
    reg          inverse;
    wire [127:0] state_out;
    
    // Test counters
    integer test_count;
    integer pass_count;
    integer fail_count;
    
    //------------------------------------------------------------------------
    // Device Under Test (DUT) Instantiation
    //------------------------------------------------------------------------
    aes_mixcolumns dut (
        .state_in  (state_in),
        .inverse   (inverse),
        .state_out (state_out)
    );

    //------------------------------------------------------------------------
    // Test Helper Tasks
    //------------------------------------------------------------------------
    
    task verify_mixcolumns;
        input [127:0] input_state;
        input [127:0] expected;
        input [256*8-1:0] test_name;
        begin
            state_in = input_state;
            inverse = 1'b0;
            #10;
            
            test_count = test_count + 1;
            
            if (state_out === expected) begin
                pass_count = pass_count + 1;
                $display("[PASS] %0s", test_name);
                $display("       Input:    %032h", input_state);
                $display("       Output:   %032h", state_out);
            end else begin
                fail_count = fail_count + 1;
                $display("[FAIL] %0s", test_name);
                $display("       Input:    %032h", input_state);
                $display("       Expected: %032h", expected);
                $display("       Got:      %032h", state_out);
            end
        end
    endtask
    
    task verify_inv_mixcolumns;
        input [127:0] input_state;
        input [127:0] expected;
        input [256*8-1:0] test_name;
        begin
            state_in = input_state;
            inverse = 1'b1;
            #10;
            
            test_count = test_count + 1;
            
            if (state_out === expected) begin
                pass_count = pass_count + 1;
                $display("[PASS] %0s", test_name);
                $display("       Input:    %032h", input_state);
                $display("       Output:   %032h", state_out);
            end else begin
                fail_count = fail_count + 1;
                $display("[FAIL] %0s", test_name);
                $display("       Input:    %032h", input_state);
                $display("       Expected: %032h", expected);
                $display("       Got:      %032h", state_out);
            end
        end
    endtask
    
    task verify_round_trip;
        input [127:0] original;
        input [256*8-1:0] test_name;
        reg [127:0] intermediate;
        begin
            state_in = original;
            inverse = 1'b0;
            #10;
            intermediate = state_out;
            
            state_in = intermediate;
            inverse = 1'b1;
            #10;
            
            test_count = test_count + 1;
            
            if (state_out === original) begin
                pass_count = pass_count + 1;
                $display("[PASS] Round-trip: %0s", test_name);
                $display("       Original:     %032h", original);
                $display("       After MC:     %032h", intermediate);
                $display("       After InvMC:  %032h", state_out);
            end else begin
                fail_count = fail_count + 1;
                $display("[FAIL] Round-trip: %0s", test_name);
                $display("       Original:     %032h", original);
                $display("       After MC:     %032h", intermediate);
                $display("       After InvMC:  %032h", state_out);
                $display("       MISMATCH!");
            end
        end
    endtask

    //------------------------------------------------------------------------
    // Main Test Sequence
    //------------------------------------------------------------------------
    initial begin
        $display("============================================================");
        $display("AES MixColumns/InvMixColumns Testbench");
        $display("AIHDL 2026 Competition - Team Acona");
        $display("============================================================");
        $display("");
        
        test_count = 0;
        pass_count = 0;
        fail_count = 0;
        state_in = 128'h0;
        inverse = 1'b0;
        
        #100;
        
        //====================================================================
        // TEST GROUP 1: Single Column Verification
        // These tests verify the basic MixColumns math is correct
        //====================================================================
        $display("");
        $display("------------------------------------------------------------");
        $display("TEST GROUP 1: Single Column MixColumns Verification");
        $display("------------------------------------------------------------");
        
        // Test vector from NIST FIPS-197 Section 5.1.3
        // Input column: {0xdb, 0x13, 0x53, 0x45}
        // Expected output: {0x8e, 0x4d, 0xa1, 0xbc}
        // As 128-bit with only column 0 populated:
        verify_mixcolumns(
            128'hdb135345_00000000_00000000_00000000,
            128'h8e4da1bc_00000000_00000000_00000000,
            "NIST 5.1.3 Column test {db,13,53,45}"
        );
        
        // Another NIST example column: {0xf2, 0x0a, 0x22, 0x5c}
        // Expected: {0x9f, 0xdc, 0x58, 0x9d}
        verify_mixcolumns(
            128'hf20a225c_00000000_00000000_00000000,
            128'h9fdc589d_00000000_00000000_00000000,
            "NIST 5.1.3 Column test {f2,0a,22,5c}"
        );
        
        // Column: {0x01, 0x01, 0x01, 0x01}
        // Expected: {0x01, 0x01, 0x01, 0x01} (identity-like for this input)
        verify_mixcolumns(
            128'h01010101_00000000_00000000_00000000,
            128'h01010101_00000000_00000000_00000000,
            "Uniform 0x01 column"
        );

        //====================================================================
        // TEST GROUP 2: NIST FIPS-197 Appendix B - Full State Test
        // This is the primary NIST test vector
        //====================================================================
        $display("");
        $display("------------------------------------------------------------");
        $display("TEST GROUP 2: NIST FIPS-197 Appendix B Full State");
        $display("------------------------------------------------------------");
        
        // From NIST FIPS-197 Appendix B, Round 1:
        // After ShiftRows: d4 bf 5d 30 e0 b4 52 ae b8 41 11 f1 1e 27 98 e5
        // After MixColumns: 04 66 81 e5 e0 cb 19 9a 48 f8 d3 7a 28 06 26 4c
        //
        // These are in the format: byte0 byte1 byte2 ... byte15
        // Which maps to our 128-bit vector as: {byte0, byte1, ..., byte15}
        verify_mixcolumns(
            128'hd4bf5d30_e0b452ae_b84111f1_1e2798e5,
            128'h046681e5_e0cb199a_48f8d37a_2806264c,
            "NIST FIPS-197 Appendix B Round 1"
        );
        
        //====================================================================
        // TEST GROUP 3: Corner Cases
        //====================================================================
        $display("");
        $display("------------------------------------------------------------");
        $display("TEST GROUP 3: Corner Cases");
        $display("------------------------------------------------------------");
        
        // All zeros - should remain zeros
        verify_mixcolumns(
            128'h00000000_00000000_00000000_00000000,
            128'h00000000_00000000_00000000_00000000,
            "All zeros"
        );
        
        // Single byte tests - verify matrix multiplication
        // Input: s0=0x01, rest=0x00
        // Output: col0 = [02*01, 01*01, 01*01, 03*01] = [02, 01, 01, 03]
        verify_mixcolumns(
            128'h01000000_00000000_00000000_00000000,
            128'h02010103_00000000_00000000_00000000,
            "Single byte s0=0x01"
        );
        
        // Input: s1=0x01
        // Output: col0 = [03*01, 02*01, 01*01, 01*01] = [03, 02, 01, 01]
        verify_mixcolumns(
            128'h00010000_00000000_00000000_00000000,
            128'h03020101_00000000_00000000_00000000,
            "Single byte s1=0x01"
        );
        
        // Input: s2=0x01
        // Output: col0 = [01*01, 03*01, 02*01, 01*01] = [01, 03, 02, 01]
        verify_mixcolumns(
            128'h00000100_00000000_00000000_00000000,
            128'h01030201_00000000_00000000_00000000,
            "Single byte s2=0x01"
        );
        
        // Input: s3=0x01
        // Output: col0 = [01*01, 01*01, 03*01, 02*01] = [01, 01, 03, 02]
        verify_mixcolumns(
            128'h00000001_00000000_00000000_00000000,
            128'h01010302_00000000_00000000_00000000,
            "Single byte s3=0x01"
        );
        
        //====================================================================
        // TEST GROUP 4: GF(2^8) xtime Verification
        //====================================================================
        $display("");
        $display("------------------------------------------------------------");
        $display("TEST GROUP 4: GF(2^8) Multiplication Verification");
        $display("------------------------------------------------------------");
        
        // Test xtime(0x57) = 0xAE (from NIST FIPS-197 Section 4.2.1)
        // Input: s0=0x57
        // r0 = 02*57 XOR 03*00 XOR 01*00 XOR 01*00 = AE
        // r1 = 01*57 XOR 02*00 XOR 03*00 XOR 01*00 = 57
        // r2 = 01*57 XOR 01*00 XOR 02*00 XOR 03*00 = 57
        // r3 = 03*57 XOR 01*00 XOR 01*00 XOR 02*00 = 57 XOR AE = F9
        verify_mixcolumns(
            128'h57000000_00000000_00000000_00000000,
            128'hae5757f9_00000000_00000000_00000000,
            "xtime(0x57)=0xAE verification"
        );
        
        // Test xtime(0x80) = 0x1B (MSB set case)
        // r0 = 02*80 = 1B
        // r1 = 01*80 = 80
        // r2 = 01*80 = 80
        // r3 = 03*80 = 80 XOR 1B = 9B
        verify_mixcolumns(
            128'h80000000_00000000_00000000_00000000,
            128'h1b80809b_00000000_00000000_00000000,
            "xtime(0x80)=0x1B verification"
        );
        
        // Test xtime(0xFF) = 0xE5
        // 02*FF = FE XOR 1B = E5
        // 03*FF = E5 XOR FF = 1A
        // r0 = E5, r1 = FF, r2 = FF, r3 = 1A
        verify_mixcolumns(
            128'hff000000_00000000_00000000_00000000,
            128'he5ffff1a_00000000_00000000_00000000,
            "xtime(0xFF)=0xE5 verification"
        );
        
        //====================================================================
        // TEST GROUP 5: Column Independence
        //====================================================================
        $display("");
        $display("------------------------------------------------------------");
        $display("TEST GROUP 5: Column Independence");
        $display("------------------------------------------------------------");
        
        // Test that column 1 processes independently
        // Using input {01,02,03,04} in column 1
        // MixColumns math for {01,02,03,04}:
        //   r0 = 02*01 ^ 03*02 ^ 01*03 ^ 01*04 = 02^06^03^04 = 03
        //   r1 = 01*01 ^ 02*02 ^ 03*03 ^ 01*04 = 01^04^05^04 = 04
        //   r2 = 01*01 ^ 01*02 ^ 02*03 ^ 03*04 = 01^02^06^0C = 09
        //   r3 = 03*01 ^ 01*02 ^ 01*03 ^ 02*04 = 03^02^03^08 = 0A
        verify_mixcolumns(
            128'h00000000_01020304_00000000_00000000,
            128'h00000000_0304090a_00000000_00000000,
            "Column 1 independence"
        );
        
        // Column 2
        verify_mixcolumns(
            128'h00000000_00000000_01020304_00000000,
            128'h00000000_00000000_0304090a_00000000,
            "Column 2 independence"
        );
        
        // Column 3
        verify_mixcolumns(
            128'h00000000_00000000_00000000_01020304,
            128'h00000000_00000000_00000000_0304090a,
            "Column 3 independence"
        );
        
        // Verify all columns give same result with same input
        verify_mixcolumns(
            128'h01020304_01020304_01020304_01020304,
            128'h0304090a_0304090a_0304090a_0304090a,
            "All columns identical input"
        );
        
        //====================================================================
        // TEST GROUP 6: Inverse MixColumns
        //====================================================================
        $display("");
        $display("------------------------------------------------------------");
        $display("TEST GROUP 6: Inverse MixColumns");
        $display("------------------------------------------------------------");
        
        // Inverse of NIST Appendix B Round 1 MixColumns output
        verify_inv_mixcolumns(
            128'h046681e5_e0cb199a_48f8d37a_2806264c,
            128'hd4bf5d30_e0b452ae_b84111f1_1e2798e5,
            "InvMixColumns NIST Appendix B"
        );
        
        // Single column inverse test
        verify_inv_mixcolumns(
            128'h8e4da1bc_00000000_00000000_00000000,
            128'hdb135345_00000000_00000000_00000000,
            "InvMixColumns single column"
        );
        
        //====================================================================
        // TEST GROUP 7: Round-Trip Verification
        //====================================================================
        $display("");
        $display("------------------------------------------------------------");
        $display("TEST GROUP 7: Round-Trip Verification");
        $display("------------------------------------------------------------");
        
        verify_round_trip(
            128'hd4bf5d30_e0b452ae_b84111f1_1e2798e5,
            "NIST Round 1 input"
        );
        
        verify_round_trip(
            128'h00000000_00000000_00000000_00000000,
            "All zeros"
        );
        
        verify_round_trip(
            128'hffffffff_ffffffff_ffffffff_ffffffff,
            "All ones"
        );
        
        verify_round_trip(
            128'h01234567_89abcdef_fedcba98_76543210,
            "Sequential pattern"
        );
        
        verify_round_trip(
            128'hdeadbeef_cafebabe_12345678_abcdef01,
            "Random pattern"
        );
        
        verify_round_trip(
            128'h55555555_aaaaaaaa_55555555_aaaaaaaa,
            "Alternating bits"
        );
        
        verify_round_trip(
            128'hdb135345_f20a225c_01234567_89abcdef,
            "Mixed columns"
        );
        
        //====================================================================
        // TEST GROUP 8: Additional NIST Test Vectors
        //====================================================================
        $display("");
        $display("------------------------------------------------------------");
        $display("TEST GROUP 8: Additional Verification");
        $display("------------------------------------------------------------");
        
        // All 0x63 (S-box of 0x00) - interesting property test
        verify_round_trip(
            128'h63636363_63636363_63636363_63636363,
            "Uniform 0x63"
        );
        
        // Verify MixColumns of uniform input stays uniform
        // For 0x63: each output byte = 02*63 XOR 03*63 XOR 01*63 XOR 01*63
        //         = C6 XOR (C6 XOR 63) XOR 63 XOR 63 = C6 XOR 25 XOR 63 XOR 63 = 63
        verify_mixcolumns(
            128'h63636363_63636363_63636363_63636363,
            128'h63636363_63636363_63636363_63636363,
            "Uniform 0x63 stays uniform"
        );
        
        //====================================================================
        // Final Summary
        //====================================================================
        $display("");
        $display("============================================================");
        $display("TEST SUMMARY");
        $display("============================================================");
        $display("Total Tests: %0d", test_count);
        $display("Passed:      %0d", pass_count);
        $display("Failed:      %0d", fail_count);
        $display("");
        
        if (fail_count == 0) begin
            $display("*** ALL TESTS PASSED ***");
            $display("AES MixColumns module is verified!");
        end else begin
            $display("*** SOME TESTS FAILED ***");
            $display("Please review failed test cases above.");
        end
        
        $display("============================================================");
        $display("");
        
        #100;
        $finish;
    end

    //------------------------------------------------------------------------
    // Waveform Dump
    //------------------------------------------------------------------------
    initial begin
        $dumpfile("tb_aes_mixcolumns.vcd");
        $dumpvars(0, tb_aes_mixcolumns);
    end

endmodule
