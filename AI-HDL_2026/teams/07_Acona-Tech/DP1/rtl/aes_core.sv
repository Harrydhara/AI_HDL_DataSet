//============================================================================
// Module: aes_core
// Description: AES-128 Encryption/Decryption Core
//
// Data Flow - Encryption (10 rounds):
//   Round 0:     AddRoundKey
//   Rounds 1-9:  SubBytes → ShiftRows → MixColumns → AddRoundKey
//   Round 10:    SubBytes → ShiftRows → AddRoundKey (no MixColumns)
//
// Data Flow - Decryption (Inverse Cipher):
//   Round 0:     AddRoundKey (Key[10])
//   Rounds 1-9:  InvShiftRows → InvSubBytes → AddRoundKey → InvMixColumns
//   Round 10:    InvShiftRows → InvSubBytes → AddRoundKey (Key[0])
//
// IMPORTANT FIXES:
//   1) Initial AddRoundKey moved to ST_INIT (mode_decrypt already latched)
//   2) Round schedule aligned so TB can feed round_key = keys[round_num]
//   3) DO NOT InvMixColumns(round_key) in this flow (because InvMixColumns is after XOR)
//============================================================================

module aes_core (
    input  wire         clk,
    input  wire         rst_n,

    input  wire [127:0] data_in,
    output reg  [127:0] data_out,

    input  wire [127:0] round_key,
    output reg  [3:0]   round_num,

    input  wire         start,
    input  wire         decrypt,
    output reg          busy,
    output reg          done
);

    //------------------------------------------------------------------------
    // FSM States
    //------------------------------------------------------------------------
    localparam [2:0] ST_IDLE  = 3'd0;
    localparam [2:0] ST_INIT  = 3'd1;  // Initial AddRoundKey
    localparam [2:0] ST_ROUND = 3'd2;  // Rounds 1-9
    localparam [2:0] ST_FINAL = 3'd3;  // Final round
    localparam [2:0] ST_DONE  = 3'd4;

    reg [2:0] state, next_state;
    reg [3:0] round_cnt;
    reg       mode_decrypt;

    reg [127:0] state_reg;

    //------------------------------------------------------------------------
    // Round Transformation Wires
    //------------------------------------------------------------------------
    wire [127:0] after_sub_bytes;
    wire [127:0] after_shift_rows;
    wire [127:0] after_mix_columns;

    wire [127:0] after_inv_shift_rows;
    wire [127:0] after_inv_sub_bytes;

    wire [127:0] after_add_key_inv;
    wire [127:0] after_inv_mix_columns;

    //------------------------------------------------------------------------
    // SubBytes (Encryption)
    //------------------------------------------------------------------------
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : gen_sbox_enc
            aes_sbox u_sbox_enc (
                .data_in  (state_reg[127 - i*8 -: 8]),
                .decrypt  (1'b0),
                .data_out (after_sub_bytes[127 - i*8 -: 8])
            );
        end
    endgenerate

    //------------------------------------------------------------------------
    // ShiftRows (Encryption) - column-major mapping
    //------------------------------------------------------------------------
    // Row 0
    assign after_shift_rows[127:120] = after_sub_bytes[127:120];  // s0
    assign after_shift_rows[95:88]   = after_sub_bytes[95:88];    // s4
    assign after_shift_rows[63:56]   = after_sub_bytes[63:56];    // s8
    assign after_shift_rows[31:24]   = after_sub_bytes[31:24];    // s12

    // Row 1: left 1
    assign after_shift_rows[119:112] = after_sub_bytes[87:80];    // s5 -> s1
    assign after_shift_rows[87:80]   = after_sub_bytes[55:48];    // s9 -> s5
    assign after_shift_rows[55:48]   = after_sub_bytes[23:16];    // s13-> s9
    assign after_shift_rows[23:16]   = after_sub_bytes[119:112];  // s1 -> s13

    // Row 2: left 2
    assign after_shift_rows[111:104] = after_sub_bytes[47:40];    // s10-> s2
    assign after_shift_rows[79:72]   = after_sub_bytes[15:8];     // s14-> s6
    assign after_shift_rows[47:40]   = after_sub_bytes[111:104];  // s2 -> s10
    assign after_shift_rows[15:8]    = after_sub_bytes[79:72];    // s6 -> s14

    // Row 3: left 3
    assign after_shift_rows[103:96]  = after_sub_bytes[7:0];      // s15-> s3
    assign after_shift_rows[71:64]   = after_sub_bytes[103:96];   // s3 -> s7
    assign after_shift_rows[39:32]   = after_sub_bytes[71:64];    // s7 -> s11
    assign after_shift_rows[7:0]     = after_sub_bytes[39:32];    // s11-> s15

    //------------------------------------------------------------------------
    // MixColumns (Encryption)
    //------------------------------------------------------------------------
    aes_mixcolumns u_mixcolumns_enc (
        .state_in  (after_shift_rows),
        .inverse   (1'b0),
        .state_out (after_mix_columns)
    );

    //------------------------------------------------------------------------
    // InvShiftRows (Decryption) - from state_reg
    //------------------------------------------------------------------------
    // Row 0
    assign after_inv_shift_rows[127:120] = state_reg[127:120];  // s0
    assign after_inv_shift_rows[95:88]   = state_reg[95:88];    // s4
    assign after_inv_shift_rows[63:56]   = state_reg[63:56];    // s8
    assign after_inv_shift_rows[31:24]   = state_reg[31:24];    // s12

    // Row 1: right 1
    assign after_inv_shift_rows[119:112] = state_reg[23:16];    // s13 -> s1
    assign after_inv_shift_rows[87:80]   = state_reg[119:112];  // s1  -> s5
    assign after_inv_shift_rows[55:48]   = state_reg[87:80];    // s5  -> s9
    assign after_inv_shift_rows[23:16]   = state_reg[55:48];    // s9  -> s13

    // Row 2: right 2 (same as left 2)
    assign after_inv_shift_rows[111:104] = state_reg[47:40];    // s10 -> s2
    assign after_inv_shift_rows[79:72]   = state_reg[15:8];     // s14 -> s6
    assign after_inv_shift_rows[47:40]   = state_reg[111:104];  // s2  -> s10
    assign after_inv_shift_rows[15:8]    = state_reg[79:72];    // s6  -> s14

    // Row 3: right 3
    assign after_inv_shift_rows[103:96]  = state_reg[71:64];    // s7  -> s3
    assign after_inv_shift_rows[71:64]   = state_reg[39:32];    // s11 -> s7
    assign after_inv_shift_rows[39:32]   = state_reg[7:0];      // s15 -> s11
    assign after_inv_shift_rows[7:0]     = state_reg[103:96];   // s3  -> s15

    //------------------------------------------------------------------------
    // InvSubBytes (Decryption)
    //------------------------------------------------------------------------
    generate
        for (i = 0; i < 16; i = i + 1) begin : gen_sbox_dec
            aes_sbox u_sbox_dec (
                .data_in  (after_inv_shift_rows[127 - i*8 -: 8]),
                .decrypt  (1'b1),
                .data_out (after_inv_sub_bytes[127 - i*8 -: 8])
            );
        end
    endgenerate

    //------------------------------------------------------------------------
    // Decryption AddRoundKey (NO key transform here)
    //------------------------------------------------------------------------
    assign after_add_key_inv = after_inv_sub_bytes ^ round_key;

    //------------------------------------------------------------------------
    // InvMixColumns (Decryption) - applied AFTER XOR (this is correct for this flow)
    //------------------------------------------------------------------------
    aes_mixcolumns u_mixcolumns_dec (
        .state_in  (after_add_key_inv),
        .inverse   (1'b1),
        .state_out (after_inv_mix_columns)
    );

    //------------------------------------------------------------------------
    // FSM State Register
    //------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) state <= ST_IDLE;
        else        state <= next_state;
    end

    //------------------------------------------------------------------------
    // FSM Next State Logic
    //------------------------------------------------------------------------
    always @(*) begin
        next_state = state;
        case (state)
            ST_IDLE:  if (start) next_state = ST_INIT;
            ST_INIT:  next_state = ST_ROUND;
            ST_ROUND: if (round_cnt == 4'd9) next_state = ST_FINAL;
            ST_FINAL: next_state = ST_DONE;
            ST_DONE:  next_state = ST_IDLE;
            default:  next_state = ST_IDLE;
        endcase
    end

    //------------------------------------------------------------------------
    // Mode Register (latch at start)
    //------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mode_decrypt <= 1'b0;
        end else if (state == ST_IDLE && start) begin
            mode_decrypt <= decrypt;
        end
    end

    //------------------------------------------------------------------------
    // Round Counter
    // We want:
    //   INIT uses round_num = 0 (enc) or 10 (dec)
    //   ROUND cycles represent rounds 1..9
    //   FINAL uses round_num = 10 (enc) or 0 (dec)
    // We'll use round_cnt:
    //   ST_IDLE : 0
    //   ST_INIT : 1 (so ST_ROUND sees 1..9)
    //   ST_ROUND: increments 1->...->9
    //   ST_FINAL: 10
    //------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            round_cnt <= 4'd0;
        end else begin
            case (state)
                ST_IDLE:  round_cnt <= 4'd0;
                ST_INIT:  round_cnt <= 4'd1;
                ST_ROUND: round_cnt <= round_cnt + 4'd1;
                ST_FINAL: round_cnt <= 4'd10;
                default:  round_cnt <= round_cnt;
            endcase
        end
    end

    //------------------------------------------------------------------------
    // Round Number Output (external key selection)
    // INIT: enc->0  dec->10
    // ROUND: enc->1..9  dec->9..1
    // FINAL: enc->10 dec->0
    //------------------------------------------------------------------------
    always @(*) begin
        if (!mode_decrypt) begin
            if (state == ST_INIT)       round_num = 4'd0;
            else if (state == ST_FINAL) round_num = 4'd10;
            else                        round_num = round_cnt; // 1..9 in ROUND
        end else begin
            if (state == ST_INIT)       round_num = 4'd10;
            else if (state == ST_FINAL) round_num = 4'd0;
            else                        round_num = 4'd10 - round_cnt; // 9..1 in ROUND
        end
    end

    //------------------------------------------------------------------------
    // State Register Update
    //------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_reg <= 128'd0;
        end else begin
            case (state)
                ST_IDLE: begin
                    if (start) begin
                        // Load input only (no XOR here)
                        state_reg <= data_in;
                    end
                end

                ST_INIT: begin
                    // Initial AddRoundKey (now correct key: 0 for enc, 10 for dec)
                    state_reg <= state_reg ^ round_key;
                end

                ST_ROUND: begin
                    if (mode_decrypt) begin
                        // InvShiftRows -> InvSubBytes -> AddRoundKey -> InvMixColumns
                        state_reg <= after_inv_mix_columns;
                    end else begin
                        // SubBytes -> ShiftRows -> MixColumns -> AddRoundKey
                        state_reg <= after_mix_columns ^ round_key;
                    end
                end

                ST_FINAL: begin
                    if (mode_decrypt) begin
                        // Final decrypt: InvShiftRows -> InvSubBytes -> AddRoundKey (NO InvMixColumns)
                        state_reg <= after_inv_sub_bytes ^ round_key;
                    end else begin
                        // Final encrypt: SubBytes -> ShiftRows -> AddRoundKey (NO MixColumns)
                        state_reg <= after_shift_rows ^ round_key;
                    end
                end

                default: state_reg <= state_reg;
            endcase
        end
    end

    //------------------------------------------------------------------------
    // Output Register
    //------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 128'd0;
        end else if (state == ST_DONE) begin
            data_out <= state_reg;
        end
    end

    //------------------------------------------------------------------------
    // Status Outputs
    //------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            busy <= 1'b0;
            done <= 1'b0;
        end else begin
            busy <= (state != ST_IDLE);
            done <= (state == ST_DONE);
        end
    end

endmodule
