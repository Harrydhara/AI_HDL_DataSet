// =============================================================================
// File: aes_core.v
// Description: AES-128 Core Encryption/Decryption Engine
//              Control FSM managing 10-round AES encryption
//              States: IDLE → LOAD → KEY_EXP → INIT_RK → ROUND_1-10 → DONE
// =============================================================================

module aes_core (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         start,          // Start encryption/decryption
    input  wire         mode,           // 0=encrypt, 1=decrypt
    input  wire [127:0] plaintext,      // Input plaintext (encrypt) or ciphertext (decrypt)
    input  wire [127:0] key,            // 128-bit encryption key
    output reg  [127:0] ciphertext,     // Output ciphertext (encrypt) or plaintext (decrypt)
    output reg          done,           // Operation complete
    output reg          busy            // Operation in progress
);

    // FSM states
    localparam IDLE      = 4'd0;
    localparam LOAD      = 4'd1;
    localparam KEY_EXP   = 4'd2;
    localparam INIT_RK   = 4'd3;
    localparam ROUND_1   = 4'd4;
    localparam ROUND_2   = 4'd5;
    localparam ROUND_3   = 4'd6;
    localparam ROUND_4   = 4'd7;
    localparam ROUND_5   = 4'd8;
    localparam ROUND_6   = 4'd9;
    localparam ROUND_7   = 4'd10;
    localparam ROUND_8   = 4'd11;
    localparam ROUND_9   = 4'd12;
    localparam ROUND_10  = 4'd13;
    localparam DONE_ST   = 4'd14;

    reg [3:0] state, next_state;
    reg [3:0] round_cnt;
    reg [127:0] state_reg;      // AES state register
    reg [127:0] round_keys [0:10]; // Store all 11 round keys
    
    // Key expansion signals
    wire        key_exp_start;
    wire        key_exp_done;
    wire [1407:0] key_exp_round_keys_flat;  // Flat packed array (11 × 128 = 1408 bits)
    reg [127:0] key_exp_round_keys [0:10];  // Unpacked for easier use
    
    // Round function signals
    wire [127:0] round_out;
    wire [127:0] inv_round_out;
    wire         is_final_round;
    wire [127:0] current_round_key;
    wire [3:0]   decrypt_round_idx;  // Reverse key index for decryption

    // Key expansion module instantiation
    aes_key_expansion key_exp_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(key_exp_start),
        .master_key(key),
        .done(key_exp_done),
        .round_keys_flat(key_exp_round_keys_flat)
    );

    // Unpack flat array into unpacked array for easier indexing
    always @(*) begin : unpack_round_keys
        integer i;
        for (i = 0; i < 11; i = i + 1) begin
            key_exp_round_keys[i] = key_exp_round_keys_flat[i*128 +: 128];
        end
    end

    assign key_exp_start = (state == KEY_EXP);

    // Round function instantiation
    assign is_final_round = (state == ROUND_10);
    
    // For decryption, use keys in reverse order: K9, K8, ..., K1, K0
    assign decrypt_round_idx = 4'd10 - round_cnt;
    assign current_round_key = mode ? round_keys[decrypt_round_idx] : round_keys[round_cnt];

    // Forward (encryption) round
    aes_round round_inst (
        .state_in(state_reg),
        .round_key(current_round_key),
        .is_final_round(is_final_round),
        .inverse(1'b0),
        .state_out(round_out)
    );

    // Inverse (decryption) round
    aes_inv_round inv_round_inst (
        .state_in(state_reg),
        .round_key(current_round_key),
        .final_round(is_final_round),
        .state_out(inv_round_out)
    );

    // State transition
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    // Next state logic
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (start)
                    next_state = LOAD;
            end
            LOAD:      next_state = KEY_EXP;
            KEY_EXP: begin
                if (key_exp_done)
                    next_state = INIT_RK;
            end
            INIT_RK:   next_state = ROUND_1;
            ROUND_1:   next_state = ROUND_2;
            ROUND_2:   next_state = ROUND_3;
            ROUND_3:   next_state = ROUND_4;
            ROUND_4:   next_state = ROUND_5;
            ROUND_5:   next_state = ROUND_6;
            ROUND_6:   next_state = ROUND_7;
            ROUND_7:   next_state = ROUND_8;
            ROUND_8:   next_state = ROUND_9;
            ROUND_9:   next_state = ROUND_10;
            ROUND_10:  next_state = DONE_ST;
            DONE_ST:   next_state = IDLE;
            default:   next_state = IDLE;
        endcase
    end

    // Output and datapath logic
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_reg <= 128'h0;
            ciphertext <= 128'h0;
            done <= 1'b0;
            busy <= 1'b0;
            round_cnt <= 4'd0;
            for (i = 0; i < 11; i = i + 1) begin
                round_keys[i] <= 128'h0;
            end
        end else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    busy <= 1'b0;
                    round_cnt <= 4'd0;
                end
                
                LOAD: begin
                    // Load plaintext/ciphertext into state register
                    state_reg <= plaintext;
                    busy <= 1'b1;
                end
                
                KEY_EXP: begin
                    // Wait for key expansion to complete
                    if (key_exp_done) begin
                        // Copy round keys from key expansion module
                        for (i = 0; i < 11; i = i + 1) begin
                            round_keys[i] <= key_exp_round_keys[i];
                        end
                    end
                end
                
                INIT_RK: begin
                    // Initial AddRoundKey
                    // Encryption: XOR with K0
                    // Decryption: XOR with K10
                    if (mode)
                        state_reg <= state_reg ^ round_keys[10];  // Decrypt starts with K10
                    else
                        state_reg <= state_reg ^ round_keys[0];   // Encrypt starts with K0
                    round_cnt <= 4'd1;
                end
                
                ROUND_1, ROUND_2, ROUND_3, ROUND_4, ROUND_5,
                ROUND_6, ROUND_7, ROUND_8, ROUND_9, ROUND_10: begin
                    // Execute round transformation (forward or inverse)
                    state_reg <= mode ? inv_round_out : round_out;
                    round_cnt <= round_cnt + 1;
                end
                
                DONE_ST: begin
                    // Store final result
                    ciphertext <= state_reg;
                    done <= 1'b1;
                    busy <= 1'b0;
                end
            endcase
        end
    end

endmodule
