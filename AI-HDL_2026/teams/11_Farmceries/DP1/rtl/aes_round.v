// =============================================================================
// File: aes_round.v
// Description: AES Round Function
//              Integrates SubBytes → ShiftRows → MixColumns → AddRoundKey
//              Supports both regular rounds (1-9) and final round (10, no MixColumns)
// =============================================================================

module aes_round (
    input  wire [127:0] state_in,       // Input state
    input  wire [127:0] round_key,      // Round key
    input  wire         is_final_round, // 1=final round (skip MixColumns)
    input  wire         inverse,        // 0=encrypt, 1=decrypt
    output wire [127:0] state_out       // Output state after round
);

    // Intermediate wires for transformation stages
    wire [127:0] after_subbytes;
    wire [127:0] after_shiftrows;
    wire [127:0] after_mixcolumns;
    wire [127:0] before_addroundkey;

    // Instantiate SubBytes (S-Box substitution)
    wire [7:0] sb_in [0:15];
    wire [7:0] sb_out [0:15];
    
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : gen_subbytes
            assign sb_in[i] = state_in[127 - i*8 -: 8];
            
            aes_sbox sbox_inst (
                .data_in(sb_in[i]),
                .inverse(inverse),
                .data_out(sb_out[i])
            );
        end
    endgenerate
    
    assign after_subbytes = {sb_out[0], sb_out[1], sb_out[2], sb_out[3],
                            sb_out[4], sb_out[5], sb_out[6], sb_out[7],
                            sb_out[8], sb_out[9], sb_out[10], sb_out[11],
                            sb_out[12], sb_out[13], sb_out[14], sb_out[15]};

    // Instantiate ShiftRows
    aes_shift_rows shift_rows_inst (
        .state_in(after_subbytes),
        .inverse(inverse),
        .state_out(after_shiftrows)
    );

    // Instantiate MixColumns (bypassed for final round)
    aes_mix_columns mix_columns_inst (
        .state_in(after_shiftrows),
        .inverse(inverse),
        .state_out(after_mixcolumns)
    );

    // Bypass MixColumns for final round
    assign before_addroundkey = is_final_round ? after_shiftrows : after_mixcolumns;

    // Instantiate AddRoundKey
    aes_add_round_key add_round_key_inst (
        .state_in(before_addroundkey),
        .round_key(round_key),
        .state_out(state_out)
    );

endmodule
