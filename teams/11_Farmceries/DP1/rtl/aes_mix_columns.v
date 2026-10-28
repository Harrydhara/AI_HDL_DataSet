// =============================================================================
// File: aes_mix_columns.v
// Description: AES MixColumns Transformation
//              Matrix multiplication in GF(2^8) Galois Field
//              Each column is multiplied by fixed matrix using xtime operation
// =============================================================================

module aes_mix_columns (
    input  wire [127:0] state_in,   // Input state (16 bytes)
    input  wire         inverse,    // 0=forward, 1=inverse MixColumns
    output wire [127:0] state_out   // Output state with mixed columns
);

    // GF(2^8) multiplication by {02} (xtime operation)
    function [7:0] xtime;
        input [7:0] x;
        begin
            xtime = (x[7]) ? ((x << 1) ^ 8'h1b) : (x << 1);
        end
    endfunction

    // GF(2^8) multiplication by {03} = {02} ⊕ {01}
    function [7:0] mul_03;
        input [7:0] x;
        begin
            mul_03 = xtime(x) ^ x;
        end
    endfunction

    // GF(2^8) multiplication by {09} (for inverse MixColumns)
    function [7:0] mul_09;
        input [7:0] x;
        reg [7:0] x2, x4, x8;
        begin
            x2 = xtime(x);
            x4 = xtime(x2);
            x8 = xtime(x4);
            mul_09 = x8 ^ x;  // {09} = {08} ⊕ {01}
        end
    endfunction

    // GF(2^8) multiplication by {0b}
    function [7:0] mul_0b;
        input [7:0] x;
        reg [7:0] x2, x4, x8;
        begin
            x2 = xtime(x);
            x4 = xtime(x2);
            x8 = xtime(x4);
            mul_0b = x8 ^ x2 ^ x;  // {0b} = {08} ⊕ {02} ⊕ {01}
        end
    endfunction

    // GF(2^8) multiplication by {0d}
    function [7:0] mul_0d;
        input [7:0] x;
        reg [7:0] x2, x4, x8;
        begin
            x2 = xtime(x);
            x4 = xtime(x2);
            x8 = xtime(x4);
            mul_0d = x8 ^ x4 ^ x;  // {0d} = {08} ⊕ {04} ⊕ {01}
        end
    endfunction

    // GF(2^8) multiplication by {0e}
    function [7:0] mul_0e;
        input [7:0] x;
        reg [7:0] x2, x4, x8;
        begin
            x2 = xtime(x);
            x4 = xtime(x2);
            x8 = xtime(x4);
            mul_0e = x8 ^ x4 ^ x2;  // {0e} = {08} ⊕ {04} ⊕ {02}
        end
    endfunction

    // Extract columns (each column is 32 bits / 4 bytes)
    wire [31:0] col0 = state_in[127:96];
    wire [31:0] col1 = state_in[95:64];
    wire [31:0] col2 = state_in[63:32];
    wire [31:0] col3 = state_in[31:0];

    // Mix each column
    wire [31:0] mixed_col0, mixed_col1, mixed_col2, mixed_col3;

    // Forward MixColumns transformation
    // Matrix: [02 03 01 01]
    //         [01 02 03 01]
    //         [01 01 02 03]
    //         [03 01 01 02]
    
    function [31:0] mix_column_forward;
        input [31:0] col;
        reg [7:0] s0, s1, s2, s3;
        reg [7:0] r0, r1, r2, r3;
        begin
            s0 = col[31:24];
            s1 = col[23:16];
            s2 = col[15:8];
            s3 = col[7:0];
            
            r0 = xtime(s0) ^ mul_03(s1) ^ s2 ^ s3;
            r1 = s0 ^ xtime(s1) ^ mul_03(s2) ^ s3;
            r2 = s0 ^ s1 ^ xtime(s2) ^ mul_03(s3);
            r3 = mul_03(s0) ^ s1 ^ s2 ^ xtime(s3);
            
            mix_column_forward = {r0, r1, r2, r3};
        end
    endfunction

    // Inverse MixColumns transformation
    // Matrix: [0e 0b 0d 09]
    //         [09 0e 0b 0d]
    //         [0d 09 0e 0b]
    //         [0b 0d 09 0e]
    
    function [31:0] mix_column_inverse;
        input [31:0] col;
        reg [7:0] s0, s1, s2, s3;
        reg [7:0] r0, r1, r2, r3;
        begin
            s0 = col[31:24];
            s1 = col[23:16];
            s2 = col[15:8];
            s3 = col[7:0];
            
            r0 = mul_0e(s0) ^ mul_0b(s1) ^ mul_0d(s2) ^ mul_09(s3);
            r1 = mul_09(s0) ^ mul_0e(s1) ^ mul_0b(s2) ^ mul_0d(s3);
            r2 = mul_0d(s0) ^ mul_09(s1) ^ mul_0e(s2) ^ mul_0b(s3);
            r3 = mul_0b(s0) ^ mul_0d(s1) ^ mul_09(s2) ^ mul_0e(s3);
            
            mix_column_inverse = {r0, r1, r2, r3};
        end
    endfunction

    // Apply transformation to all columns
    assign mixed_col0 = inverse ? mix_column_inverse(col0) : mix_column_forward(col0);
    assign mixed_col1 = inverse ? mix_column_inverse(col1) : mix_column_forward(col1);
    assign mixed_col2 = inverse ? mix_column_inverse(col2) : mix_column_forward(col2);
    assign mixed_col3 = inverse ? mix_column_inverse(col3) : mix_column_forward(col3);

    // Reassemble output state
    assign state_out = {mixed_col0, mixed_col1, mixed_col2, mixed_col3};

endmodule
