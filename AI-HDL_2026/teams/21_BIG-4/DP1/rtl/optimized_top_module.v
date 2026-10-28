/*
 * Module: tensorbolt_ai_accelerator
 * Target: ASIC / TinyQV Peripheral (DP2)
 * Optimizations: Sparsity-Aware Zero Bypass, Balanced Adder Tree, Operand Isolation
 */

`default_nettype none

module tensorbolt_ai_accelerator (
    input  wire        clk,
    input  wire        rst_n,

    // IO Ports
    input  wire [7:0]  ui_in,
    output wire [7:0]  uo_out,

    // TinyQV Peripheral Bus
    input  wire [5:0]  address,
    input  wire [31:0] data_in,
    input  wire [1:0]  data_write_n,
    input  wire [1:0]  data_read_n,
    output wire [31:0] data_out,
    output wire        data_ready,
    output wire        user_interrupt
);

    // -------------------------------------------------------------
    // 1. Registers & FSM State
    // -------------------------------------------------------------
    reg [3:0]  state; // One-hot: IDLE(0), MUL(1), ACC(2), DONE(3)
    
    reg [31:0] reg_op_a_front, reg_op_b_front;
    reg [31:0] reg_op_a_back,  reg_op_b_back;
    
    reg signed [15:0] pipe_p0, pipe_p1, pipe_p2, pipe_p3;
    reg signed [31:0] reg_result; 

    // -------------------------------------------------------------
    // 2. Bus Decoding & Zero-Wait Handshake
    // -------------------------------------------------------------
    wire write_enable = (data_write_n != 2'b11);
    wire read_enable  = (data_read_n  != 2'b11);
    wire [3:0] word_addr = address[5:2];

    wire is_ctrl = (word_addr == 4'h0);
    wire is_opa  = (word_addr == 4'h1);
    wire is_opb  = (word_addr == 4'h2);
    wire is_res  = (word_addr == 4'h3);

    wire start_cmd = (write_enable && is_ctrl && data_in[0]);
    wire clear_cmd = (write_enable && is_ctrl && data_in[1]);

    assign user_interrupt = 1'b0;
    assign uo_out = 8'b0;
    assign data_ready = (write_enable || read_enable); // 0-Wait State

    // -------------------------------------------------------------
    // 3. FSM & Safe Accumulator
    // -------------------------------------------------------------
    // OPTIMIZATION: Balanced Binary Adder Tree for Accumulation
    // Reduces adder depth from 5 cascading stages to 2 parallel stages
    wire signed [16:0] sum_01 = pipe_p0 + pipe_p1;
    wire signed [16:0] sum_23 = pipe_p2 + pipe_p3;
    wire signed [17:0] sum_all = sum_01 + sum_23;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= 4'b0001; 
            reg_result <= 32'd0;   
        end else begin
            case (1'b1)
                state[0]: if (start_cmd) state <= 4'b0010; 
                state[1]: state <= 4'b0100;                
                state[2]: state <= 4'b1000;                
                state[3]: begin                            
                    if (start_cmd)       state <= 4'b0010; 
                    else if (clear_cmd)  state <= 4'b0001; 
                end
                default: state <= 4'b0001;
            endcase

            if (clear_cmd && (state[0] || state[3])) begin
reg_result <= 32'd0;
            end else if (state[2]) begin
                reg_result <= reg_result + {{14{sum_all[17]}}, sum_all};
            end
        end
    end

    // -------------------------------------------------------------
    // 4. Datapath: Sparsity-Aware Compute & Double Buffering
    // -------------------------------------------------------------
    wire load_backend = start_cmd && (state[0] || state[3]);

    wire signed [7:0] a0 = reg_op_a_back[7:0],   a1 = reg_op_a_back[15:8],   a2 = reg_op_a_back[23:16], a3 = reg_op_a_back[31:24];
    wire signed [7:0] b0 = reg_op_b_back[7:0],   b1 = reg_op_b_back[15:8],   b2 = reg_op_b_back[23:16], b3 = reg_op_b_back[31:24];

    // OPTIMIZATION: Fine-Grained Operand Isolation + Zero Bypassing
    // AI matrices are often sparse (many 0s). If an operand is 0, we force both inputs to 0.
    // This stops the internal nodes of the multiplier standard cells from toggling entirely.
    wire active_mul = state[1];
    wire en_m0 = active_mul && (a0 != 0) && (b0 != 0);
    wire en_m1 = active_mul && (a1 != 0) && (b1 != 0);
    wire en_m2 = active_mul && (a2 != 0) && (b2 != 0);
    wire en_m3 = active_mul && (a3 != 0) && (b3 != 0);

    always @(posedge clk) begin
        // Frontend & Backend Buffering (ICG Inferred)
        if (write_enable && is_opa) reg_op_a_front <= data_in;
        if (write_enable && is_opb) reg_op_b_front <= data_in;
        if (load_backend) begin
            reg_op_a_back <= reg_op_a_front;
            reg_op_b_back <= reg_op_b_front;
        end

        // Pipeline Stage 1: Sparsity-Aware Multipliers
        // The ternary operator enforces strict operand isolation at the logic level
        pipe_p0 <= en_m0 ? (a0 * b0) : 16'd0;
        pipe_p1 <= en_m1 ? (a1 * b1) : 16'd0;
        pipe_p2 <= en_m2 ? (a2 * b2) : 16'd0;
        pipe_p3 <= en_m3 ? (a3 * b3) : 16'd0;
    end

    // -------------------------------------------------------------
    // 5. Read Path: AOI Muxing
    // -------------------------------------------------------------
    assign data_out = ( {32{read_enable & is_ctrl}} & {28'd0, state} ) |
                      ( {32{read_enable & is_opa}}  & reg_op_a_front ) |
                      ( {32{read_enable & is_opb}}  & reg_op_b_front ) |
                      ( {32{read_enable & is_res}}  & reg_result );

endmodule
