// =============================================================================
// File: aes_add_round_key.v
// Description: AES AddRoundKey Transformation
//              XOR state with round key (128-bit XOR operation)
//              Same operation for both encryption and decryption
// =============================================================================

module aes_add_round_key (
    input  wire [127:0] state_in,    // Input state (16 bytes)
    input  wire [127:0] round_key,   // Round key (16 bytes)
    output wire [127:0] state_out    // Output state XORed with round key
);

    // Simple XOR operation - same for encryption and decryption
    assign state_out = state_in ^ round_key;

endmodule
