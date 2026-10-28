/*
 * Module: tensorbolt_ai_accelerator
 * Target: TinyQV Peripheral (DP1)
 * Optimization: OpenLane Robustness (Clean Resets, No Latches, Explicit Muxing)
 */

`default_nettype none

module tensorbolt_ai_accelerator (
    input  wire        clk,
    input  wire        rst_n,      // Standardization: ONLY use this for reset

    // IO Ports (Unused pins tied off strictly)
    input  wire [7:0]  ui_in,
    output wire [7:0]  uo_out,

    // TinyQV Peripheral Bus
    input  wire [5:0]  address,
    input  wire [31:0] data_in,
    input  wire [1:0]  data_write_n,
    input  wire [1:0]  data_read_n,
    output reg  [31:0] data_out,
    output reg         data_ready,
    output wire        user_interrupt
);

    // -------------------------------------------------------------
    // 1. Constants & Address Map
    // -------------------------------------------------------------
    localparam STATE_IDLE    = 2'd0;
    localparam STATE_COMPUTE = 2'd1;
    localparam STATE_DONE    = 2'd2;

    localparam ADDR_CTRL   = 4'h0;
    localparam ADDR_OP_A   = 4'h1;
    localparam ADDR_OP_B   = 4'h2;
    localparam ADDR_RES    = 4'h3;

    // -------------------------------------------------------------
    // 2. Internal Registers
    // -------------------------------------------------------------
    reg [1:0]  state;
    reg [1:0]  next_state;     // Combinational next state
    reg [3:0]  latency_count;
    
    reg [31:0] reg_op_a;
    reg [31:0] reg_op_b;
    reg [31:0] reg_result;

    // Command/Status Flags
    reg busy_flag;
    reg done_flag;
    
    // Internal Signals
    wire write_enable;
    wire read_enable;
    wire [3:0] word_addr;
    wire start_cmd;
    wire clear_cmd;

    // Bus decoding helpers
    assign write_enable = (data_write_n != 2'b11);
    assign read_enable  = (data_read_n  != 2'b11);
    assign word_addr    = address[5:2];

    // Interrupt tied low (Safety)
    assign user_interrupt = 1'b0;
    assign uo_out = 8'b0;

    // -------------------------------------------------------------
    // 3. Command Decoding (Combinational)
    // -------------------------------------------------------------
    // optimization: Decode commands explicitly to avoid logic deep inside clocked blocks
    assign start_cmd = (write_enable && (word_addr == ADDR_CTRL) && data_in[0]);
    assign clear_cmd = (write_enable && (word_addr == ADDR_CTRL) && data_in[1]);

    // -------------------------------------------------------------
    // 4. Data Path & Registers (Sequential)
    // -------------------------------------------------------------
    // optimization: Explicit 'else' keeps logic deterministic and maps to simple MUX+DFF
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_op_a   <= 32'd0;
            reg_op_b   <= 32'd0;
            reg_result <= 32'd0;
        end else begin
            // Operation A Register Write
            if (write_enable && (word_addr == ADDR_OP_A))
                reg_op_a <= data_in;
            else
                reg_op_a <= reg_op_a; // Explicit hold

            // Operation B Register Write
            if (write_enable && (word_addr == ADDR_OP_B))
                reg_op_b <= data_in;
            else
                reg_op_b <= reg_op_b; // Explicit hold

            // Result Logic (Cleared by CMD or updated by Compute)
            if (clear_cmd)
                reg_result <= 32'd0;
            else if (state == STATE_COMPUTE)
                reg_result <= reg_result + 32'd1; // Placeholder math
            else
                reg_result <= reg_result;
        end
    end

    // -------------------------------------------------------------
    // 5. Finite State Machine (Robust Two-Process Style)
    // -------------------------------------------------------------
    
    // Process A: State Transition (Sequential)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state         <= STATE_IDLE;
            latency_count <= 4'd0;
            busy_flag     <= 1'b0;
            done_flag     <= 1'b0;
        end else begin
            state <= next_state;

            // Counter Logic with explicit reset
            if (state == STATE_IDLE && start_cmd)
                latency_count <= 4'd10; // Load latency
            else if (state == STATE_COMPUTE)
                latency_count <= latency_count - 1'b1;
            else
                latency_count <= latency_count;
            
            // Flag Logic
            busy_flag <= (next_state == STATE_COMPUTE);
            done_flag <= (state == STATE_DONE);
        end
    end

    // Process B: Next State Logic (Combinational)
    // optimization: Default assignment prevents inferred latches
    always @(*) begin
        next_state = state; // Default: Stay in current state

        case (state)
            STATE_IDLE: begin
                if (start_cmd) 
                    next_state = STATE_COMPUTE;
            end

            STATE_COMPUTE: begin
                if (latency_count == 4'd0) 
                    next_state = STATE_DONE;
            end

            STATE_DONE: begin
                if (clear_cmd || start_cmd) 
                    next_state = STATE_IDLE;
            end
            
            default: next_state = STATE_IDLE; // Safety catch-all
        endcase
    end

    // -------------------------------------------------------------
    // 6. Bus Output Logic (Clean Muxing)
    // -------------------------------------------------------------
    
    // Data Ready Logic
    always @(*) begin
    data_ready = (write_enable || read_enable);
end

    // Data Out Mux (Combinational)
    // optimization: Full case coverage prevents X propagation
    always @(*) begin
        data_out = 32'd0; // Default safe value
        if (read_enable) begin
            case (word_addr)
                ADDR_CTRL: data_out = {30'd0, done_flag, busy_flag};
                ADDR_OP_A: data_out = reg_op_a;
                ADDR_OP_B: data_out = reg_op_b;
                ADDR_RES:  data_out = reg_result;
                default:   data_out = 32'd0;
            endcase
        end
    end

endmodule
