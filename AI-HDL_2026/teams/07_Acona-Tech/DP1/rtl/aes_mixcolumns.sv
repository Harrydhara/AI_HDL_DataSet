//============================================================================
// Module: aes_mixcolumns
// Description: AES MixColumns and InvMixColumns Transformations
//              Implements GF(2^8) matrix multiplication for column mixing
//
// Features:
//   - Forward MixColumns for encryption
//   - Inverse MixColumns for decryption  
//   - Efficient xtime implementation for GF(2^8) multiplication
//   - Processes all 4 columns in parallel
//   - Fully combinational logic
//
// NIST FIPS-197 Reference:
//   - Forward MixColumns uses matrix:
//     | 02 03 01 01 |
//     | 01 02 03 01 |
//     | 01 01 02 03 |
//     | 03 01 01 02 |
//
//   - Inverse MixColumns uses matrix:
//     | 0e 0b 0d 09 |
//     | 09 0e 0b 0d |
//     | 0d 09 0e 0b |
//     | 0b 0d 09 0e |
//
// State byte ordering (128-bit input, column-major):
//   state_in[127:0] = {s0,s1,s2,s3, s4,s5,s6,s7, s8,s9,s10,s11, s12,s13,s14,s15}
//                     |--Col 0---|  |--Col 1---|  |---Col 2---|  |----Col 3----|
//
// Author: AIHDL 2026 Competition Team (Team Acona)
// Date: January 2026
// Target: TinyQV RISC-V Peripheral (64MHz)
//============================================================================

module aes_mixcolumns (
    input  wire [127:0] state_in,   // 128-bit input state (16 bytes)
    input  wire         inverse,    // Mode: 0 = MixColumns, 1 = InvMixColumns
    output wire [127:0] state_out   // 128-bit transformed state
);

    //------------------------------------------------------------------------
    // State Byte Extraction (Column-Major Order)
    // AES state arrangement:
    //   State Matrix:     | s0  s4  s8  s12 |   Row 0
    //                     | s1  s5  s9  s13 |   Row 1
    //                     | s2  s6  s10 s14 |   Row 2
    //                     | s3  s7  s11 s15 |   Row 3
    //                     Col0 Col1 Col2 Col3
    //------------------------------------------------------------------------
    
    // Column 0: bytes [127:96]
    wire [7:0] s0  = state_in[127:120];  // Row 0, Col 0
    wire [7:0] s1  = state_in[119:112];  // Row 1, Col 0
    wire [7:0] s2  = state_in[111:104];  // Row 2, Col 0
    wire [7:0] s3  = state_in[103:96];   // Row 3, Col 0
    
    // Column 1: bytes [95:64]
    wire [7:0] s4  = state_in[95:88];    // Row 0, Col 1
    wire [7:0] s5  = state_in[87:80];    // Row 1, Col 1
    wire [7:0] s6  = state_in[79:72];    // Row 2, Col 1
    wire [7:0] s7  = state_in[71:64];    // Row 3, Col 1
    
    // Column 2: bytes [63:32]
    wire [7:0] s8  = state_in[63:56];    // Row 0, Col 2
    wire [7:0] s9  = state_in[55:48];    // Row 1, Col 2
    wire [7:0] s10 = state_in[47:40];    // Row 2, Col 2
    wire [7:0] s11 = state_in[39:32];    // Row 3, Col 2
    
    // Column 3: bytes [31:0]
    wire [7:0] s12 = state_in[31:24];    // Row 0, Col 3
    wire [7:0] s13 = state_in[23:16];    // Row 1, Col 3
    wire [7:0] s14 = state_in[15:8];     // Row 2, Col 3
    wire [7:0] s15 = state_in[7:0];      // Row 3, Col 3

    //------------------------------------------------------------------------
    // xtime Function: Multiply by 0x02 in GF(2^8)
    // xtime(b) = (b << 1) XOR 0x1B if b[7] = 1, else (b << 1)
    // Reduction polynomial: x^8 + x^4 + x^3 + x + 1 (0x11B)
    //------------------------------------------------------------------------
    function [7:0] xtime;
        input [7:0] b;
        begin
            xtime = {b[6:0], 1'b0} ^ (8'h1b & {8{b[7]}});
        end
    endfunction

    //------------------------------------------------------------------------
    // GF(2^8) Multiplication by Constants
    // All multipliers derived from xtime operations
    //------------------------------------------------------------------------
    
    // Multiply by 0x02 (single xtime)
    function [7:0] gf_mult_02;
        input [7:0] b;
        begin
            gf_mult_02 = xtime(b);
        end
    endfunction
    
    // Multiply by 0x03 = 0x02 XOR 0x01
    function [7:0] gf_mult_03;
        input [7:0] b;
        begin
            gf_mult_03 = xtime(b) ^ b;
        end
    endfunction
    
    // Multiply by 0x04 = xtime(xtime(b))
    function [7:0] gf_mult_04;
        input [7:0] b;
        begin
            gf_mult_04 = xtime(xtime(b));
        end
    endfunction
    
    // Multiply by 0x08 = xtime(xtime(xtime(b)))
    function [7:0] gf_mult_08;
        input [7:0] b;
        begin
            gf_mult_08 = xtime(xtime(xtime(b)));
        end
    endfunction
    
    // Multiply by 0x09 = 0x08 XOR 0x01
    function [7:0] gf_mult_09;
        input [7:0] b;
        begin
            gf_mult_09 = gf_mult_08(b) ^ b;
        end
    endfunction
    
    // Multiply by 0x0B = 0x08 XOR 0x02 XOR 0x01
    function [7:0] gf_mult_0b;
        input [7:0] b;
        begin
            gf_mult_0b = gf_mult_08(b) ^ xtime(b) ^ b;
        end
    endfunction
    
    // Multiply by 0x0D = 0x08 XOR 0x04 XOR 0x01
    function [7:0] gf_mult_0d;
        input [7:0] b;
        begin
            gf_mult_0d = gf_mult_08(b) ^ gf_mult_04(b) ^ b;
        end
    endfunction
    
    // Multiply by 0x0E = 0x08 XOR 0x04 XOR 0x02
    function [7:0] gf_mult_0e;
        input [7:0] b;
        begin
            gf_mult_0e = gf_mult_08(b) ^ gf_mult_04(b) ^ xtime(b);
        end
    endfunction

    //------------------------------------------------------------------------
    // Forward MixColumns Transformation
    // Matrix multiplication:
    // | r0 |   | 02 03 01 01 |   | s0 |
    // | r1 | = | 01 02 03 01 | x | s1 |
    // | r2 |   | 01 01 02 03 |   | s2 |
    // | r3 |   | 03 01 01 02 |   | s3 |
    //------------------------------------------------------------------------
    
    // Column 0 - Forward MixColumns
    wire [7:0] mc0_r0 = gf_mult_02(s0) ^ gf_mult_03(s1) ^ s2 ^ s3;
    wire [7:0] mc0_r1 = s0 ^ gf_mult_02(s1) ^ gf_mult_03(s2) ^ s3;
    wire [7:0] mc0_r2 = s0 ^ s1 ^ gf_mult_02(s2) ^ gf_mult_03(s3);
    wire [7:0] mc0_r3 = gf_mult_03(s0) ^ s1 ^ s2 ^ gf_mult_02(s3);
    
    // Column 1 - Forward MixColumns
    wire [7:0] mc1_r0 = gf_mult_02(s4) ^ gf_mult_03(s5) ^ s6 ^ s7;
    wire [7:0] mc1_r1 = s4 ^ gf_mult_02(s5) ^ gf_mult_03(s6) ^ s7;
    wire [7:0] mc1_r2 = s4 ^ s5 ^ gf_mult_02(s6) ^ gf_mult_03(s7);
    wire [7:0] mc1_r3 = gf_mult_03(s4) ^ s5 ^ s6 ^ gf_mult_02(s7);
    
    // Column 2 - Forward MixColumns
    wire [7:0] mc2_r0 = gf_mult_02(s8) ^ gf_mult_03(s9) ^ s10 ^ s11;
    wire [7:0] mc2_r1 = s8 ^ gf_mult_02(s9) ^ gf_mult_03(s10) ^ s11;
    wire [7:0] mc2_r2 = s8 ^ s9 ^ gf_mult_02(s10) ^ gf_mult_03(s11);
    wire [7:0] mc2_r3 = gf_mult_03(s8) ^ s9 ^ s10 ^ gf_mult_02(s11);
    
    // Column 3 - Forward MixColumns
    wire [7:0] mc3_r0 = gf_mult_02(s12) ^ gf_mult_03(s13) ^ s14 ^ s15;
    wire [7:0] mc3_r1 = s12 ^ gf_mult_02(s13) ^ gf_mult_03(s14) ^ s15;
    wire [7:0] mc3_r2 = s12 ^ s13 ^ gf_mult_02(s14) ^ gf_mult_03(s15);
    wire [7:0] mc3_r3 = gf_mult_03(s12) ^ s13 ^ s14 ^ gf_mult_02(s15);

    //------------------------------------------------------------------------
    // Inverse MixColumns Transformation
    // Matrix multiplication:
    // | r0 |   | 0e 0b 0d 09 |   | s0 |
    // | r1 | = | 09 0e 0b 0d | x | s1 |
    // | r2 |   | 0d 09 0e 0b |   | s2 |
    // | r3 |   | 0b 0d 09 0e |   | s3 |
    //------------------------------------------------------------------------
    
    // Column 0 - Inverse MixColumns
    wire [7:0] imc0_r0 = gf_mult_0e(s0) ^ gf_mult_0b(s1) ^ gf_mult_0d(s2) ^ gf_mult_09(s3);
    wire [7:0] imc0_r1 = gf_mult_09(s0) ^ gf_mult_0e(s1) ^ gf_mult_0b(s2) ^ gf_mult_0d(s3);
    wire [7:0] imc0_r2 = gf_mult_0d(s0) ^ gf_mult_09(s1) ^ gf_mult_0e(s2) ^ gf_mult_0b(s3);
    wire [7:0] imc0_r3 = gf_mult_0b(s0) ^ gf_mult_0d(s1) ^ gf_mult_09(s2) ^ gf_mult_0e(s3);
    
    // Column 1 - Inverse MixColumns
    wire [7:0] imc1_r0 = gf_mult_0e(s4) ^ gf_mult_0b(s5) ^ gf_mult_0d(s6) ^ gf_mult_09(s7);
    wire [7:0] imc1_r1 = gf_mult_09(s4) ^ gf_mult_0e(s5) ^ gf_mult_0b(s6) ^ gf_mult_0d(s7);
    wire [7:0] imc1_r2 = gf_mult_0d(s4) ^ gf_mult_09(s5) ^ gf_mult_0e(s6) ^ gf_mult_0b(s7);
    wire [7:0] imc1_r3 = gf_mult_0b(s4) ^ gf_mult_0d(s5) ^ gf_mult_09(s6) ^ gf_mult_0e(s7);
    
    // Column 2 - Inverse MixColumns
    wire [7:0] imc2_r0 = gf_mult_0e(s8) ^ gf_mult_0b(s9) ^ gf_mult_0d(s10) ^ gf_mult_09(s11);
    wire [7:0] imc2_r1 = gf_mult_09(s8) ^ gf_mult_0e(s9) ^ gf_mult_0b(s10) ^ gf_mult_0d(s11);
    wire [7:0] imc2_r2 = gf_mult_0d(s8) ^ gf_mult_09(s9) ^ gf_mult_0e(s10) ^ gf_mult_0b(s11);
    wire [7:0] imc2_r3 = gf_mult_0b(s8) ^ gf_mult_0d(s9) ^ gf_mult_09(s10) ^ gf_mult_0e(s11);
    
    // Column 3 - Inverse MixColumns
    wire [7:0] imc3_r0 = gf_mult_0e(s12) ^ gf_mult_0b(s13) ^ gf_mult_0d(s14) ^ gf_mult_09(s15);
    wire [7:0] imc3_r1 = gf_mult_09(s12) ^ gf_mult_0e(s13) ^ gf_mult_0b(s14) ^ gf_mult_0d(s15);
    wire [7:0] imc3_r2 = gf_mult_0d(s12) ^ gf_mult_09(s13) ^ gf_mult_0e(s14) ^ gf_mult_0b(s15);
    wire [7:0] imc3_r3 = gf_mult_0b(s12) ^ gf_mult_0d(s13) ^ gf_mult_09(s14) ^ gf_mult_0e(s15);

    //------------------------------------------------------------------------
    // Output Assembly
    // Reconstruct 128-bit state from column results
    //------------------------------------------------------------------------
    
    // Forward MixColumns result
    wire [127:0] fwd_out = {mc0_r0,  mc0_r1,  mc0_r2,  mc0_r3,
                           mc1_r0,  mc1_r1,  mc1_r2,  mc1_r3,
                           mc2_r0,  mc2_r1,  mc2_r2,  mc2_r3,
                           mc3_r0,  mc3_r1,  mc3_r2,  mc3_r3};
    
    // Inverse MixColumns result
    wire [127:0] inv_out = {imc0_r0, imc0_r1, imc0_r2, imc0_r3,
                           imc1_r0, imc1_r1, imc1_r2, imc1_r3,
                           imc2_r0, imc2_r1, imc2_r2, imc2_r3,
                           imc3_r0, imc3_r1, imc3_r2, imc3_r3};
    
    // Select output based on mode
    assign state_out = inverse ? inv_out : fwd_out;

endmodule
