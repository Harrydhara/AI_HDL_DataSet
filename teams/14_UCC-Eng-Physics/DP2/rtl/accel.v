module accel (
    input wire clk,
    input wire rst,
    input wire start,
    input wire [2:0] opcode,
    input wire [31:0] in_data,
    output reg done,
    output reg [31:0] result
);

// ======================================================
// 1. Activity Detection (KEY FOR SWITCHING REDUCTION)
// ======================================================
wire active_compute;
assign active_compute = start && (opcode != 3'b000);

// ======================================================
// 2. Intermediate Signals (COMBINATIONAL BLOCK)
// ======================================================
reg [31:0] alu_out;

always @(*) begin
    // DEFAULT → prevents unnecessary switching
    alu_out = 32'd0;

    if (active_compute) begin
        case (opcode)
            3'b001: alu_out = in_data + 32'd1;
            3'b010: alu_out = in_data - 32'd1;
            3'b011: alu_out = in_data * 2;
            3'b100: alu_out = in_data >> 1;
            default: alu_out = 32'd0;
        endcase
    end
end

// ======================================================
// 3. REGISTER UPDATE GATING (CRITICAL)
// ======================================================
always @(posedge clk or posedge rst) begin
    if (rst) begin
        result <= 32'd0;
        done   <= 1'b0;
    end else begin

        
        if (active_compute) begin
            result <= alu_out;
            done   <= 1'b1;
        end else begin
            done <= 1'b0;
        end
    end
end

endmodule
