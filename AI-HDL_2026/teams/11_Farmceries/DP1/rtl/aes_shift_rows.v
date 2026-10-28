// =============================================================================
// File: aes_shift_rows.v
// Description: AES ShiftRows Transformation
//              Cyclically shifts bytes in each row of the state matrix
//              Row 0: no shift, Row 1: left 1, Row 2: left 2, Row 3: left 3
// =============================================================================

module aes_shift_rows (
    input  wire [127:0] state_in,   // Input state (16 bytes)
    input  wire         inverse,    // 0=forward, 1=inverse (right shifts)
    output wire [127:0] state_out   // Output state with shifted rows
);

    // Extract bytes from input state
    // State organized as column-major 4x4 matrix:
    //   [ s0  s4  s8  s12 ]
    //   [ s1  s5  s9  s13 ]
    //   [ s2  s6  s10 s14 ]
    //   [ s3  s7  s11 s15 ]
    
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

    // Perform ShiftRows transformation
    wire [7:0] r0, r1, r2, r3, r4, r5, r6, r7;
    wire [7:0] r8, r9, r10, r11, r12, r13, r14, r15;
    
    generate
        if (1) begin : shift_logic
            assign r0  = s0;      // Row 0: no shift
            assign r4  = s4;
            assign r8  = s8;
            assign r12 = s12;
            
            // Forward ShiftRows (encryption)
            // Row 1: left shift by 1
            assign r1  = inverse ? s13 : s5;
            assign r5  = inverse ? s1  : s9;
            assign r9  = inverse ? s5  : s13;
            assign r13 = inverse ? s9  : s1;
            
            // Row 2: left shift by 2
            assign r2  = inverse ? s10 : s10;
            assign r6  = inverse ? s14 : s14;
            assign r10 = inverse ? s2  : s2;
            assign r14 = inverse ? s6  : s6;
            
            // Row 3: left shift by 3 (or right shift by 1)
            assign r3  = inverse ? s7  : s15;
            assign r7  = inverse ? s11 : s3;
            assign r11 = inverse ? s15 : s7;
            assign r15 = inverse ? s3  : s11;
        end
    endgenerate

    // Reassemble output state
    assign state_out = {r0, r1, r2, r3, r4, r5, r6, r7,
                        r8, r9, r10, r11, r12, r13, r14, r15};

endmodule
