//============================================================================
// Module: aes_core_fast
// Description: AES-128 Core with Optimized MixColumns
//
// DP2 OPTIMIZATION: Uses aes_mixcolumns_fast for reduced critical path
//
// This is a copy of aes_core.sv with aes_mixcolumns replaced by
// aes_mixcolumns_fast to reduce InvMixColumns logic depth.
//
// Author: AIHDL 2026 Competition Team (Team Acona)
// Date: February 2026
// Phase: DP2 - PPA Optimization
//============================================================================

module aes_core_fast (
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
    localparam [2:0] ST_INIT  = 3'd1;
    localparam [2:0] ST_ROUND = 3'd2;
    localparam [2:0] ST_FINAL = 3'd3;
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
    // InvMixColumns (Decryption) - USING FAST VERSION
    //------------------------------------------------------------------------
    assign after_add_key_inv = after_inv_sub_bytes ^ round_key;

    aes_mixcolumns_fast u_mixcolumns_dec (
        .state_in  (after_add_key_inv),
        .inverse   (1'b1),
        .state_out (after_inv_mix_columns)
    );

    //------------------------------------------------------------------------
    // FSM
    //------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= ST_IDLE;
        else
            state <= next_state;
    end

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
        if (!rst_n)
            round_cnt <= 4'd0;
        else begin
            case (state)
                ST_IDLE:  round_cnt <= 4'd0;
                ST_INIT:  round_cnt <= 4'd1;
                ST_ROUND: round_cnt <= round_cnt + 4'd1;
                default:  round_cnt <= round_cnt;
            endcase
        end
    end

    //------------------------------------------------------------------------
    // Round Number Output
    //------------------------------------------------------------------------
    always @(*) begin
        if (!mode_decrypt) begin
            case (state)
                ST_INIT:  round_num = 4'd0;
                ST_ROUND: round_num = round_cnt;
                ST_FINAL: round_num = 4'd10;
                default:  round_num = 4'd0;
            endcase
        end else begin
            case (state)
                ST_INIT:  round_num = 4'd10;
                ST_ROUND: round_num = 4'd10 - round_cnt;
                ST_FINAL: round_num = 4'd0;
                default:  round_num = 4'd0;
            endcase
        end
    end

    //------------------------------------------------------------------------
    // State Register
    //------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_reg <= 128'd0;
        end else begin
            case (state)
                ST_IDLE: if (start) state_reg <= data_in;

                ST_INIT: state_reg <= state_reg ^ round_key;

                ST_ROUND: begin
                    if (mode_decrypt)
                        state_reg <= after_inv_mix_columns;
                    else
                        state_reg <= after_mix_columns ^ round_key;
                end

                ST_FINAL: begin
                    if (mode_decrypt)
                        state_reg <= after_inv_sub_bytes ^ round_key;
                    else
                        state_reg <= after_shift_rows ^ round_key;
                end

                default: state_reg <= state_reg;
            endcase
        end
    end

    //------------------------------------------------------------------------
    // Output
    //------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_out <= 128'd0;
        else if (state == ST_DONE)
            data_out <= state_reg;
    end

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
