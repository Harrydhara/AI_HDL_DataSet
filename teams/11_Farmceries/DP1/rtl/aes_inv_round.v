// =============================================================================
// File: aes_inv_round.v
// Description: AES Inverse Round Transformation for Decryption
//              Sequence: InvShiftRows → InvSubBytes → AddRoundKey → InvMixColumns
//              (Note: final round skips InvMixColumns)
// =============================================================================

module aes_inv_round (
    input  wire [127:0] state_in,       // Input state
    input  wire [127:0] round_key,      // Round key for this round
    input  wire         final_round,    // 1=final round (skip InvMixColumns)
    output wire [127:0] state_out       // Output state
);

    // Intermediate signals
    wire [127:0] after_inv_shift;
    wire [127:0] after_inv_sub;
    wire [127:0] after_add_key;
    wire [127:0] after_inv_mix;

    // Step 1: InvShiftRows
    aes_shift_rows inv_shift_rows (
        .state_in(state_in),
        .inverse(1'b1),                 // Inverse mode
        .state_out(after_inv_shift)
    );

    // Step 2: InvSubBytes - instantiate 16 S-Boxes
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : gen_inv_sbox
            aes_sbox inv_sbox_inst (
                .data_in(after_inv_shift[8*i+7:8*i]),
                .inverse(1'b1),
                .data_out(after_inv_sub[8*i+7:8*i])
            );
        end
    endgenerate

    // Step 3: AddRoundKey
    aes_add_round_key add_round_key (
        .state_in(after_inv_sub),
        .round_key(round_key),
        .state_out(after_add_key)
    );

    // Step 4: InvMixColumns (skip in final round)
    aes_mix_columns inv_mix_columns (
        .state_in(after_add_key),
        .inverse(1'b1),                 // Inverse mode
        .state_out(after_inv_mix)
    );

    // For final round, bypass InvMixColumns
    assign state_out = final_round ? after_add_key : after_inv_mix;

endmodule
