`default_nettype none
// ---------------------------------------------------------------------------
// pe_macc  –  Processing Element: Multiply-Accumulate
// ---------------------------------------------------------------------------
module pe_macc (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] a_in,
    input  wire [31:0] b_in,
    input  wire [31:0] acc_in,
    output wire [31:0] a_out,      // combinational pass-through (saves 32 FFs)
    output wire [31:0] b_out,      // combinational pass-through (saves 32 FFs)
    output reg  [31:0] acc_out
);
    // Pass-through: no register, just wire
    assign a_out = a_in;
    assign b_out = b_in;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            acc_out <= 32'd0;
        else
            acc_out <= acc_in + (a_in * b_in);
    end

endmodule