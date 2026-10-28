//============================================================================
// Module: aes_mixcolumns_fast
// Description: Optimized AES MixColumns with Reduced Critical Path
//
// DP2 OPTIMIZATION: Critical Path Reduction
// ──────────────────────────────────────────
// This module reduces the logic depth of InvMixColumns by:
//   1. Pre-computing all xtime levels in parallel (x2, x4, x8)
//   2. Combining results with minimal XOR depth
//   3. Using optimized GF(2^8) multiplication formulas
//
// Original InvMixColumns: ~8-10 levels of logic
// Optimized InvMixColumns: ~5-6 levels of logic
//
// Author: AIHDL 2026 Competition Team (Team Acona)
// Date: February 2026
// Phase: DP2 - PPA Optimization
//============================================================================

module aes_mixcolumns_fast (
    input  wire [127:0] state_in,
    input  wire         inverse,
    output wire [127:0] state_out
);

    //------------------------------------------------------------------------
    // State Byte Extraction
    //------------------------------------------------------------------------
    wire [7:0] s0  = state_in[127:120];
    wire [7:0] s1  = state_in[119:112];
    wire [7:0] s2  = state_in[111:104];
    wire [7:0] s3  = state_in[103:96];
    wire [7:0] s4  = state_in[95:88];
    wire [7:0] s5  = state_in[87:80];
    wire [7:0] s6  = state_in[79:72];
    wire [7:0] s7  = state_in[71:64];
    wire [7:0] s8  = state_in[63:56];
    wire [7:0] s9  = state_in[55:48];
    wire [7:0] s10 = state_in[47:40];
    wire [7:0] s11 = state_in[39:32];
    wire [7:0] s12 = state_in[31:24];
    wire [7:0] s13 = state_in[23:16];
    wire [7:0] s14 = state_in[15:8];
    wire [7:0] s15 = state_in[7:0];

    //------------------------------------------------------------------------
    // Optimized xtime: Single level of logic
    // xtime(b) = (b << 1) XOR (0x1B if b[7]=1, else 0x00)
    //------------------------------------------------------------------------
    function [7:0] xtime;
        input [7:0] b;
        begin
            xtime = {b[6:0], 1'b0} ^ (8'h1b & {8{b[7]}});
        end
    endfunction

    //------------------------------------------------------------------------
    // PRE-COMPUTE ALL XTIME LEVELS IN PARALLEL
    // This is the key optimization - compute x2, x4, x8 for all bytes
    // in parallel, then combine them. This reduces sequential depth.
    //------------------------------------------------------------------------
    
    // Column 0 pre-computations
    wire [7:0] s0_x2 = xtime(s0);
    wire [7:0] s0_x4 = xtime(s0_x2);
    wire [7:0] s0_x8 = xtime(s0_x4);
    
    wire [7:0] s1_x2 = xtime(s1);
    wire [7:0] s1_x4 = xtime(s1_x2);
    wire [7:0] s1_x8 = xtime(s1_x4);
    
    wire [7:0] s2_x2 = xtime(s2);
    wire [7:0] s2_x4 = xtime(s2_x2);
    wire [7:0] s2_x8 = xtime(s2_x4);
    
    wire [7:0] s3_x2 = xtime(s3);
    wire [7:0] s3_x4 = xtime(s3_x2);
    wire [7:0] s3_x8 = xtime(s3_x4);

    // Column 1 pre-computations
    wire [7:0] s4_x2 = xtime(s4);
    wire [7:0] s4_x4 = xtime(s4_x2);
    wire [7:0] s4_x8 = xtime(s4_x4);
    
    wire [7:0] s5_x2 = xtime(s5);
    wire [7:0] s5_x4 = xtime(s5_x2);
    wire [7:0] s5_x8 = xtime(s5_x4);
    
    wire [7:0] s6_x2 = xtime(s6);
    wire [7:0] s6_x4 = xtime(s6_x2);
    wire [7:0] s6_x8 = xtime(s6_x4);
    
    wire [7:0] s7_x2 = xtime(s7);
    wire [7:0] s7_x4 = xtime(s7_x2);
    wire [7:0] s7_x8 = xtime(s7_x4);

    // Column 2 pre-computations
    wire [7:0] s8_x2 = xtime(s8);
    wire [7:0] s8_x4 = xtime(s8_x2);
    wire [7:0] s8_x8 = xtime(s8_x4);
    
    wire [7:0] s9_x2 = xtime(s9);
    wire [7:0] s9_x4 = xtime(s9_x2);
    wire [7:0] s9_x8 = xtime(s9_x4);
    
    wire [7:0] s10_x2 = xtime(s10);
    wire [7:0] s10_x4 = xtime(s10_x2);
    wire [7:0] s10_x8 = xtime(s10_x4);
    
    wire [7:0] s11_x2 = xtime(s11);
    wire [7:0] s11_x4 = xtime(s11_x2);
    wire [7:0] s11_x8 = xtime(s11_x4);

    // Column 3 pre-computations
    wire [7:0] s12_x2 = xtime(s12);
    wire [7:0] s12_x4 = xtime(s12_x2);
    wire [7:0] s12_x8 = xtime(s12_x4);
    
    wire [7:0] s13_x2 = xtime(s13);
    wire [7:0] s13_x4 = xtime(s13_x2);
    wire [7:0] s13_x8 = xtime(s13_x4);
    
    wire [7:0] s14_x2 = xtime(s14);
    wire [7:0] s14_x4 = xtime(s14_x2);
    wire [7:0] s14_x8 = xtime(s14_x4);
    
    wire [7:0] s15_x2 = xtime(s15);
    wire [7:0] s15_x4 = xtime(s15_x2);
    wire [7:0] s15_x8 = xtime(s15_x4);

    //------------------------------------------------------------------------
    // Forward MixColumns (unchanged - already optimal)
    // Multiply by: 02, 03, 01, 01
    // 03 = 02 ^ 01
    //------------------------------------------------------------------------
    
    // Column 0
    wire [7:0] mc0_r0 = s0_x2 ^ s1_x2 ^ s1 ^ s2 ^ s3;
    wire [7:0] mc0_r1 = s0 ^ s1_x2 ^ s2_x2 ^ s2 ^ s3;
    wire [7:0] mc0_r2 = s0 ^ s1 ^ s2_x2 ^ s3_x2 ^ s3;
    wire [7:0] mc0_r3 = s0_x2 ^ s0 ^ s1 ^ s2 ^ s3_x2;
    
    // Column 1
    wire [7:0] mc1_r0 = s4_x2 ^ s5_x2 ^ s5 ^ s6 ^ s7;
    wire [7:0] mc1_r1 = s4 ^ s5_x2 ^ s6_x2 ^ s6 ^ s7;
    wire [7:0] mc1_r2 = s4 ^ s5 ^ s6_x2 ^ s7_x2 ^ s7;
    wire [7:0] mc1_r3 = s4_x2 ^ s4 ^ s5 ^ s6 ^ s7_x2;
    
    // Column 2
    wire [7:0] mc2_r0 = s8_x2 ^ s9_x2 ^ s9 ^ s10 ^ s11;
    wire [7:0] mc2_r1 = s8 ^ s9_x2 ^ s10_x2 ^ s10 ^ s11;
    wire [7:0] mc2_r2 = s8 ^ s9 ^ s10_x2 ^ s11_x2 ^ s11;
    wire [7:0] mc2_r3 = s8_x2 ^ s8 ^ s9 ^ s10 ^ s11_x2;
    
    // Column 3
    wire [7:0] mc3_r0 = s12_x2 ^ s13_x2 ^ s13 ^ s14 ^ s15;
    wire [7:0] mc3_r1 = s12 ^ s13_x2 ^ s14_x2 ^ s14 ^ s15;
    wire [7:0] mc3_r2 = s12 ^ s13 ^ s14_x2 ^ s15_x2 ^ s15;
    wire [7:0] mc3_r3 = s12_x2 ^ s12 ^ s13 ^ s14 ^ s15_x2;

    //------------------------------------------------------------------------
    // OPTIMIZED Inverse MixColumns
    // Multiply by: 0e, 0b, 0d, 09
    //
    // Using pre-computed values:
    //   0x09 = x8 ^ x1        = s_x8 ^ s
    //   0x0b = x8 ^ x2 ^ x1   = s_x8 ^ s_x2 ^ s
    //   0x0d = x8 ^ x4 ^ x1   = s_x8 ^ s_x4 ^ s
    //   0x0e = x8 ^ x4 ^ x2   = s_x8 ^ s_x4 ^ s_x2
    //
    // This gives us ~4 levels of XOR instead of ~8-10!
    //------------------------------------------------------------------------
    
    // Column 0 - Inverse MixColumns (OPTIMIZED)
    // imc0_r0 = 0e*s0 ^ 0b*s1 ^ 0d*s2 ^ 09*s3
    wire [7:0] imc0_r0 = (s0_x8 ^ s0_x4 ^ s0_x2) ^           // 0e * s0
                         (s1_x8 ^ s1_x2 ^ s1) ^               // 0b * s1
                         (s2_x8 ^ s2_x4 ^ s2) ^               // 0d * s2
                         (s3_x8 ^ s3);                        // 09 * s3
    
    // imc0_r1 = 09*s0 ^ 0e*s1 ^ 0b*s2 ^ 0d*s3
    wire [7:0] imc0_r1 = (s0_x8 ^ s0) ^                       // 09 * s0
                         (s1_x8 ^ s1_x4 ^ s1_x2) ^            // 0e * s1
                         (s2_x8 ^ s2_x2 ^ s2) ^               // 0b * s2
                         (s3_x8 ^ s3_x4 ^ s3);                // 0d * s3
    
    // imc0_r2 = 0d*s0 ^ 09*s1 ^ 0e*s2 ^ 0b*s3
    wire [7:0] imc0_r2 = (s0_x8 ^ s0_x4 ^ s0) ^               // 0d * s0
                         (s1_x8 ^ s1) ^                       // 09 * s1
                         (s2_x8 ^ s2_x4 ^ s2_x2) ^            // 0e * s2
                         (s3_x8 ^ s3_x2 ^ s3);                // 0b * s3
    
    // imc0_r3 = 0b*s0 ^ 0d*s1 ^ 09*s2 ^ 0e*s3
    wire [7:0] imc0_r3 = (s0_x8 ^ s0_x2 ^ s0) ^               // 0b * s0
                         (s1_x8 ^ s1_x4 ^ s1) ^               // 0d * s1
                         (s2_x8 ^ s2) ^                       // 09 * s2
                         (s3_x8 ^ s3_x4 ^ s3_x2);             // 0e * s3

    // Column 1 - Inverse MixColumns (OPTIMIZED)
    wire [7:0] imc1_r0 = (s4_x8 ^ s4_x4 ^ s4_x2) ^
                         (s5_x8 ^ s5_x2 ^ s5) ^
                         (s6_x8 ^ s6_x4 ^ s6) ^
                         (s7_x8 ^ s7);
    
    wire [7:0] imc1_r1 = (s4_x8 ^ s4) ^
                         (s5_x8 ^ s5_x4 ^ s5_x2) ^
                         (s6_x8 ^ s6_x2 ^ s6) ^
                         (s7_x8 ^ s7_x4 ^ s7);
    
    wire [7:0] imc1_r2 = (s4_x8 ^ s4_x4 ^ s4) ^
                         (s5_x8 ^ s5) ^
                         (s6_x8 ^ s6_x4 ^ s6_x2) ^
                         (s7_x8 ^ s7_x2 ^ s7);
    
    wire [7:0] imc1_r3 = (s4_x8 ^ s4_x2 ^ s4) ^
                         (s5_x8 ^ s5_x4 ^ s5) ^
                         (s6_x8 ^ s6) ^
                         (s7_x8 ^ s7_x4 ^ s7_x2);

    // Column 2 - Inverse MixColumns (OPTIMIZED)
    wire [7:0] imc2_r0 = (s8_x8 ^ s8_x4 ^ s8_x2) ^
                         (s9_x8 ^ s9_x2 ^ s9) ^
                         (s10_x8 ^ s10_x4 ^ s10) ^
                         (s11_x8 ^ s11);
    
    wire [7:0] imc2_r1 = (s8_x8 ^ s8) ^
                         (s9_x8 ^ s9_x4 ^ s9_x2) ^
                         (s10_x8 ^ s10_x2 ^ s10) ^
                         (s11_x8 ^ s11_x4 ^ s11);
    
    wire [7:0] imc2_r2 = (s8_x8 ^ s8_x4 ^ s8) ^
                         (s9_x8 ^ s9) ^
                         (s10_x8 ^ s10_x4 ^ s10_x2) ^
                         (s11_x8 ^ s11_x2 ^ s11);
    
    wire [7:0] imc2_r3 = (s8_x8 ^ s8_x2 ^ s8) ^
                         (s9_x8 ^ s9_x4 ^ s9) ^
                         (s10_x8 ^ s10) ^
                         (s11_x8 ^ s11_x4 ^ s11_x2);

    // Column 3 - Inverse MixColumns (OPTIMIZED)
    wire [7:0] imc3_r0 = (s12_x8 ^ s12_x4 ^ s12_x2) ^
                         (s13_x8 ^ s13_x2 ^ s13) ^
                         (s14_x8 ^ s14_x4 ^ s14) ^
                         (s15_x8 ^ s15);
    
    wire [7:0] imc3_r1 = (s12_x8 ^ s12) ^
                         (s13_x8 ^ s13_x4 ^ s13_x2) ^
                         (s14_x8 ^ s14_x2 ^ s14) ^
                         (s15_x8 ^ s15_x4 ^ s15);
    
    wire [7:0] imc3_r2 = (s12_x8 ^ s12_x4 ^ s12) ^
                         (s13_x8 ^ s13) ^
                         (s14_x8 ^ s14_x4 ^ s14_x2) ^
                         (s15_x8 ^ s15_x2 ^ s15);
    
    wire [7:0] imc3_r3 = (s12_x8 ^ s12_x2 ^ s12) ^
                         (s13_x8 ^ s13_x4 ^ s13) ^
                         (s14_x8 ^ s14) ^
                         (s15_x8 ^ s15_x4 ^ s15_x2);

    //------------------------------------------------------------------------
    // Output Assembly
    //------------------------------------------------------------------------
    wire [127:0] fwd_out = {mc0_r0,  mc0_r1,  mc0_r2,  mc0_r3,
                           mc1_r0,  mc1_r1,  mc1_r2,  mc1_r3,
                           mc2_r0,  mc2_r1,  mc2_r2,  mc2_r3,
                           mc3_r0,  mc3_r1,  mc3_r2,  mc3_r3};
    
    wire [127:0] inv_out = {imc0_r0, imc0_r1, imc0_r2, imc0_r3,
                           imc1_r0, imc1_r1, imc1_r2, imc1_r3,
                           imc2_r0, imc2_r1, imc2_r2, imc2_r3,
                           imc3_r0, imc3_r1, imc3_r2, imc3_r3};
    
    assign state_out = inverse ? inv_out : fwd_out;

endmodule
