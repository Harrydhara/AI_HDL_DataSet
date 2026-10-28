//============================================================================
// Module: aes_core_fast_v2
// Description: AES-128 Core with Pipelined Key Fetch
//
// DP2 OPTIMIZATION: Pipeline register after key MUX
// ──────────────────────────────────────────────────
// This module adds a pipeline stage between key selection and
// AES round operations, cutting the critical path in half.
//
// FSM Changes:
//   - Added KEY_FETCH state before each round
//   - round_key is registered before use
//   - Total cycles: 22 (was 12)
//
// Expected improvement: 30 levels → ~15 levels
//
// Author: AIHDL 2026 Competition Team (Team Acona)
// Date: February 2026
// Phase: DP2 - PPA Optimization
//============================================================================

module aes_core_fast_v2 (
    input  wire         clk,
    input  wire         rst_n,

    input  wire [127:0] data_in,
    output reg  [127:0] data_out,

    input  wire [127:0] round_key,      // From key expansion (MUX output)
    output reg  [3:0]   round_num,

    input  wire         start,
    input  wire         decrypt,
    output reg          busy,
    output reg          done
);

    //------------------------------------------------------------------------
    // FSM States (Extended for key pipeline)
    //------------------------------------------------------------------------
    localparam [2:0] ST_IDLE      = 3'd0;
    localparam [2:0] ST_KEY_INIT  = 3'd1;  // Fetch initial round key
    localparam [2:0] ST_INIT      = 3'd2;  // Apply initial AddRoundKey
    localparam [2:0] ST_KEY_FETCH = 3'd3;  // Fetch round key (pipeline)
    localparam [2:0] ST_ROUND     = 3'd4;  // Apply round transformation
    localparam [2:0] ST_KEY_FINAL = 3'd5;  // Fetch final round key
    localparam [2:0] ST_FINAL     = 3'd6;  // Apply final round
    localparam [2:0] ST_DONE      = 3'd7;

    reg [2:0] state, next_state;
    reg [3:0] round_cnt;
    reg       mode_decrypt;

    reg [127:0] state_reg;
    reg [127:0] round_key_reg;  // Pipeline register for round key

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
    // ShiftRows (Encryption)
    //------------------------------------------------------------------------
    assign after_shift_rows[127:120] = after_sub_bytes[127:120];
    assign after_shift_rows[95:88]   = after_sub_bytes[95:88];
    assign after_shift_rows[63:56]   = after_sub_bytes[63:56];
    assign after_shift_rows[31:24]   = after_sub_bytes[31:24];

    assign after_shift_rows[119:112] = after_sub_bytes[87:80];
    assign after_shift_rows[87:80]   = after_sub_bytes[55:48];
    assign after_shift_rows[55:48]   = after_sub_bytes[23:16];
    assign after_shift_rows[23:16]   = after_sub_bytes[119:112];

    assign after_shift_rows[111:104] = after_sub_bytes[47:40];
    assign after_shift_rows[79:72]   = after_sub_bytes[15:8];
    assign after_shift_rows[47:40]   = after_sub_bytes[111:104];
    assign after_shift_rows[15:8]    = after_sub_bytes[79:72];

    assign after_shift_rows[103:96]  = after_sub_bytes[7:0];
    assign after_shift_rows[71:64]   = after_sub_bytes[103:96];
    assign after_shift_rows[39:32]   = after_sub_bytes[71:64];
    assign after_shift_rows[7:0]     = after_sub_bytes[39:32];

    //------------------------------------------------------------------------
    // MixColumns (Encryption) - USING FAST VERSION
    //------------------------------------------------------------------------
    aes_mixcolumns_fast u_mixcolumns_enc (
        .state_in  (after_shift_rows),
        .inverse   (1'b0),
        .state_out (after_mix_columns)
    );

    //------------------------------------------------------------------------
    // InvShiftRows (Decryption)
    //------------------------------------------------------------------------
    assign after_inv_shift_rows[127:120] = state_reg[127:120];
    assign after_inv_shift_rows[95:88]   = state_reg[95:88];
    assign after_inv_shift_rows[63:56]   = state_reg[63:56];
    assign after_inv_shift_rows[31:24]   = state_reg[31:24];

    assign after_inv_shift_rows[119:112] = state_reg[23:16];
    assign after_inv_shift_rows[87:80]   = state_reg[119:112];
    assign after_inv_shift_rows[55:48]   = state_reg[87:80];
    assign after_inv_shift_rows[23:16]   = state_reg[55:48];

    assign after_inv_shift_rows[111:104] = state_reg[47:40];
    assign after_inv_shift_rows[79:72]   = state_reg[15:8];
    assign after_inv_shift_rows[47:40]   = state_reg[111:104];
    assign after_inv_shift_rows[15:8]    = state_reg[79:72];

    assign after_inv_shift_rows[103:96]  = state_reg[71:64];
    assign after_inv_shift_rows[71:64]   = state_reg[39:32];
    assign after_inv_shift_rows[39:32]   = state_reg[7:0];
    assign after_inv_shift_rows[7:0]     = state_reg[103:96];

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
    // InvMixColumns (Decryption) - Uses REGISTERED round_key
    //------------------------------------------------------------------------
    assign after_add_key_inv = after_inv_sub_bytes ^ round_key_reg;

    aes_mixcolumns_fast u_mixcolumns_dec (
        .state_in  (after_add_key_inv),
        .inverse   (1'b1),
        .state_out (after_inv_mix_columns)
    );

    //------------------------------------------------------------------------
    // FSM State Register
    //------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= ST_IDLE;
        else
            state <= next_state;
    end

    //------------------------------------------------------------------------
    // FSM Next State Logic
    //------------------------------------------------------------------------
    always @(*) begin
        next_state = state;
        case (state)
            ST_IDLE:      if (start) next_state = ST_KEY_INIT;
            ST_KEY_INIT:  next_state = ST_INIT;
            ST_INIT:      next_state = ST_KEY_FETCH;
            ST_KEY_FETCH: next_state = ST_ROUND;
            ST_ROUND:     begin
                if (round_cnt == 4'd9)
                    next_state = ST_KEY_FINAL;
                else
                    next_state = ST_KEY_FETCH;
            end
            ST_KEY_FINAL: next_state = ST_FINAL;
            ST_FINAL:     next_state = ST_DONE;
            ST_DONE:      next_state = ST_IDLE;
            default:      next_state = ST_IDLE;
        endcase
    end

    //------------------------------------------------------------------------
    // Mode Register
    //------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            mode_decrypt <= 1'b0;
        else if (state == ST_IDLE && start)
            mode_decrypt <= decrypt;
    end

    //------------------------------------------------------------------------
    // Round Counter
    //------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            round_cnt <= 4'd0;
        end else begin
            case (state)
                ST_IDLE:  round_cnt <= 4'd0;
                ST_INIT:  round_cnt <= 4'd1;
                ST_ROUND: round_cnt <= round_cnt + 4'd1;
                default:  round_cnt <= round_cnt;
            endcase
        end
    end

    //------------------------------------------------------------------------
    // Round Number Output (for key MUX selection)
    //------------------------------------------------------------------------
    always @(*) begin
        if (!mode_decrypt) begin
            // Encryption: 0 → 1 → 2 → ... → 10
            case (state)
                ST_KEY_INIT:  round_num = 4'd0;
                ST_INIT:      round_num = 4'd0;
                ST_KEY_FETCH: round_num = round_cnt;
                ST_ROUND:     round_num = round_cnt;
                ST_KEY_FINAL: round_num = 4'd10;
                ST_FINAL:     round_num = 4'd10;
                default:      round_num = 4'd0;
            endcase
        end else begin
            // Decryption: 10 → 9 → 8 → ... → 0
            case (state)
                ST_KEY_INIT:  round_num = 4'd10;
                ST_INIT:      round_num = 4'd10;
                ST_KEY_FETCH: round_num = 4'd10 - round_cnt;
                ST_ROUND:     round_num = 4'd10 - round_cnt;
                ST_KEY_FINAL: round_num = 4'd0;
                ST_FINAL:     round_num = 4'd0;
                default:      round_num = 4'd0;
            endcase
        end
    end

    //------------------------------------------------------------------------
    // Round Key Pipeline Register (KEY OPTIMIZATION)
    //------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            round_key_reg <= 128'd0;
        end else begin
            // Register the round key during KEY_* states
            if (state == ST_KEY_INIT || state == ST_KEY_FETCH || state == ST_KEY_FINAL) begin
                round_key_reg <= round_key;
            end
        end
    end

    //------------------------------------------------------------------------
    // State Register (Main Datapath)
    //------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_reg <= 128'd0;
        end else begin
            case (state)
                ST_IDLE: begin
                    if (start)
                        state_reg <= data_in;
                end

                ST_KEY_INIT: begin
                    // Wait for key to be registered
                end

                ST_INIT: begin
                    // Initial AddRoundKey (uses registered key)
                    state_reg <= state_reg ^ round_key_reg;
                end

                ST_KEY_FETCH: begin
                    // Wait for key to be registered
                end

                ST_ROUND: begin
                    if (mode_decrypt)
                        state_reg <= after_inv_mix_columns;
                    else
                        state_reg <= after_mix_columns ^ round_key_reg;
                end

                ST_KEY_FINAL: begin
                    // Wait for key to be registered
                end

                ST_FINAL: begin
                    if (mode_decrypt)
                        state_reg <= after_inv_sub_bytes ^ round_key_reg;
                    else
                        state_reg <= after_shift_rows ^ round_key_reg;
                end

                default: state_reg <= state_reg;
            endcase
        end
    end

    //------------------------------------------------------------------------
    // Output Register
    //------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_out <= 128'd0;
        else if (state == ST_DONE)
            data_out <= state_reg;
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
