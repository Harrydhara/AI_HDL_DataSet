//============================================================================
// Debug Testbench: Trace AES Round 1 Step by Step
//============================================================================

`timescale 1ns / 1ps

module tb_aes_debug;

    // Test the aes_round module directly
    reg  [127:0] state_in;
    reg  [127:0] round_key;
    reg          final_round;
    wire [127:0] state_out;
    
    // Instantiate aes_round
    aes_round u_round (
        .state_in    (state_in),
        .round_key   (round_key),
        .final_round (final_round),
        .state_out   (state_out)
    );
    
    // Access internal signals for debug
    wire [127:0] after_sub = u_round.after_sub_bytes;
    wire [127:0] after_sr  = u_round.after_shift_rows;
    wire [127:0] after_mc  = u_round.after_mix_columns;

    initial begin
        $display("============================================");
        $display("  AES Round Debug Test");
        $display("============================================");
        
        //------------------------------------------------------------------
        // Test Round 1 with NIST values
        // Input state (after AddRoundKey round 0):
        //   19 3d e3 be
        //   a0 f4 e2 2b  
        //   9a c6 8d 2a
        //   e9 f8 48 08
        // This is: 193de3bea0f4e22b9ac68d2ae9f84808 in column-major
        //------------------------------------------------------------------
        
        state_in = 128'h193de3bea0f4e22b9ac68d2ae9f84808;
        round_key = 128'ha0fafe1788542cb123a339392a6c7605;  // Key[1]
        final_round = 0;
        
        #10;
        
        $display("");
        $display("Input State: %h", state_in);
        $display("Round Key:   %h", round_key);
        $display("");
        
        // Expected from NIST FIPS-197 Appendix B:
        // After SubBytes:   d42711aee0bf98f1b8b45de51e415230
        // After ShiftRows:  d4bf5d30e0b452aeb84111f11e2798e5
        // After MixColumns: 046681e5e0cb199a48f8d37a2806264c
        // After AddRoundKey (with key1): a49c7ff26689bf4b14142e52cfba8d3c
        //
        // But wait - NIST shows these in ROW-MAJOR format!
        // Let me convert to column-major (our format):
        //
        // NIST SubBytes result (row-major display):
        //   d4 27 11 ae
        //   e0 bf 98 f1
        //   b8 b4 5d e5
        //   1e 41 52 30
        // Column-major: d4e0b81e 27bfb441 119852 aef1e530
        // Wait, let me be more careful...
        // Col0: d4,e0,b8,1e -> d4e0b81e
        // Col1: 27,bf,b4,41 -> 27bfb441
        // Col2: 11,98,5d,52 -> 11985d52
        // Col3: ae,f1,e5,30 -> aef1e530
        // Full: d4e0b81e27bfb44111985d52aef1e530
        
        $display("After SubBytes:   %h", after_sub);
        $display("  Expected:       d4e0b81e27bfb44111985d52aef1e530");
        
        // NIST ShiftRows result (row-major display):
        //   d4 27 11 ae  (row 0, no shift)
        //   bf 98 f1 e0  (row 1, shift left 1)
        //   5d e5 b8 b4  (row 2, shift left 2)  
        //   30 1e 41 52  (row 3, shift left 3)
        // Column-major:
        // Col0: d4,bf,5d,30 -> d4bf5d30
        // Col1: 27,98,e5,1e -> 2798e51e
        // Col2: 11,f1,b8,41 -> 11f1b841
        // Col3: ae,e0,b4,52 -> aee0b452
        // Full: d4bf5d302798e51e11f1b841aee0b452
        
        $display("After ShiftRows:  %h", after_sr);
        $display("  Expected:       d4bf5d302798e51e11f1b841aee0b452");
        
        // NIST MixColumns result (row-major display):
        //   04 66 81 e5
        //   e0 cb 19 9a
        //   48 f8 d3 7a
        //   28 06 26 4c
        // Column-major:
        // Col0: 04,e0,48,28 -> 04e04828
        // Col1: 66,cb,f8,06 -> 66cbf806
        // Col2: 81,19,d3,26 -> 8119d326
        // Col3: e5,9a,7a,4c -> e59a7a4c
        // Full: 04e0482866cbf8068119d326e59a7a4c
        
        $display("After MixColumns: %h", after_mc);
        $display("  Expected:       04e0482866cbf8068119d326e59a7a4c");
        
        // After AddRoundKey with key[1] = a0fafe1788542cb123a339392a6c7605
        // 04e0482866cbf8068119d326e59a7a4c XOR a0fafe1788542cb123a339392a6c7605
        // = a49c7ff26689bf4b14142e52cfba8d3c (this should match)
        // Wait no - need to verify byte ordering...
        
        $display("Round Output:     %h", state_out);
        $display("  Key[1]:         %h", round_key);
        
        $display("");
        $display("============================================");
        
        //------------------------------------------------------------------
        // Also test single S-Box lookup
        //------------------------------------------------------------------
        $display("");
        $display("S-Box Verification:");
        $display("  S[0x19] should be 0xd4");
        $display("  S[0x3d] should be 0x27");
        $display("  S[0x00] should be 0x63");
        
        // Check if our implementation matches
        $display("");
        $display("First 4 bytes of input:  %h %h %h %h", 
                 state_in[127:120], state_in[119:112], 
                 state_in[111:104], state_in[103:96]);
        $display("First 4 bytes after sub: %h %h %h %h",
                 after_sub[127:120], after_sub[119:112],
                 after_sub[111:104], after_sub[103:96]);
        
        $display("");
        $display("============================================");
        $finish;
    end

endmodule
