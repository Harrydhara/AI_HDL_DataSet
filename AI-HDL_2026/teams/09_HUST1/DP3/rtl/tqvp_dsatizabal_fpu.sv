`default_nettype none

module tqvp_dsatizabal_fpu (
    input  wire       clk,
    input  wire       rst_n,

    input  wire [7:0]  ui_in,
    output wire [7:0]  uo_out,

    input  wire [5:0]  address,
    input  wire [31:0] data_in,
    input  wire [1:0]  data_write_n,
    input  wire [1:0]  data_read_n,
    output wire [31:0] data_out,
    output wire        data_ready
);

    // === Memory-mapped Registers ===
    reg [15:0] operand_a;
    reg [15:0] operand_b;
    reg [2:0]  operation;

    reg        busy;
    reg        valid_in;

    reg [15:0] result;
    reg        ready;

    // === FSM States (Verilog-2001 compatible) ===
    localparam [2:0] ST_IDLE           = 3'b000;
    localparam [2:0] ST_READING        = 3'b001;
    localparam [2:0] ST_OPERANDS_READY = 3'b010;
    localparam [2:0] ST_CALCULATING    = 3'b011;

    reg [2:0] state;

    // === FPU Operations (Verilog-2001 compatible) ===
    localparam [2:0] OP_ADD  = 3'b000;
    localparam [2:0] OP_SUB  = 3'b001;
    localparam [2:0] OP_MULT = 3'b010;

    // === Muxed B for subtract
    wire [15:0] b_muxed = (operation == OP_SUB) ? {~operand_b[15], operand_b[14:0]} : operand_b;

    // === Pipelined Adder ===
    wire [15:0] add_result;
    wire        add_valid_out;

    fpu_adder add_inst (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in && (operation == OP_ADD || operation == OP_SUB) && (state == ST_OPERANDS_READY)),
        .a(operand_a),
        .b(b_muxed),
        .valid_out(add_valid_out),
        .result(add_result)
    );

    // === Pipelined Multiplier ===
    wire [15:0] mul_result;
    wire        mul_valid_out;

    fpu_mult mul_inst (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in && (operation == OP_MULT) && (state == ST_OPERANDS_READY)),
        .a(operand_a[15:0]),
        .b(operand_b[15:0]),
        .valid_out(mul_valid_out),
        .result(mul_result)
    );

    // === Write Logic & FSM ===
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            operand_a     <= 16'b0;
            operand_b     <= 16'b0;
            operation     <= 3'b0;
            valid_in      <= 1'b0;
            busy          <= 1'b0;
            state         <= ST_IDLE;
            result        <= 16'b0;
            ready         <= 1'b0;
        end else begin
            case (state)
                ST_IDLE: begin
                    if (data_write_n != 2'b11) begin
                        if (address[1:0] == 2'b00) begin
                            operation    <= address[4:2];
                            operand_a    <= data_in[15:0];
                            ready        <= 1'b0;
                            busy         <= 1'b1;
                            state        <= ST_READING;
                        end
                    end
                end

                ST_READING: begin
                    if (data_write_n != 2'b11) begin
                        if (address[1:0] == 2'b01) begin
                            operand_b    <= data_in[15:0];
                            state        <= ST_OPERANDS_READY;
                            valid_in     <= 1'b1;
                        end
                    end
                end

                ST_OPERANDS_READY: begin
                    state        <= ST_CALCULATING;
                end

                ST_CALCULATING: begin
                    if (add_valid_out) begin
                        result <= add_result;
                        state  <= ST_IDLE;
                        ready  <= 1'b1;
                        busy   <= 1'b0;
                    end else if (mul_valid_out) begin
                        result <= mul_result;
                        state  <= ST_IDLE;
                        ready  <= 1'b1;
                        busy   <= 1'b0;
                    end
                end
            endcase
        end
    end

    // === Read Logic ===
    assign data_out = (address == 6'h00) ? { 16'b0, operand_a } :
                      (address == 6'h04) ? { 16'b0, operand_b } :
                      (address == 6'h08) ? {29'b0, operation} : // TODO: do I need to add control signals?
                      (address == 6'h0C) ? {16'b0, result} :
                      (address == 6'h10) ? {31'b0, busy} :
                      32'h0;

    assign data_ready       = ready;

    assign uo_out           = 8'b0;

    wire _unused = &{ui_in, data_read_n, 1'b0};

endmodule
