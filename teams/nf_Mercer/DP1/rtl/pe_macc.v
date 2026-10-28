`default_nettype none
module pe_macc (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] a_in,
    input  wire [31:0] b_in,
    input  wire [31:0] acc_in,
    output reg  [31:0] a_out,
    output reg  [31:0] b_out,
    output reg  [31:0] acc_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_out  <= 32'd0;
            b_out  <= 32'd0;
            acc_out <= 32'd0;
        end else begin
            a_out  <= a_in;
            b_out  <= b_in;
            acc_out <= acc_in + (a_in * b_in);
        end
    end
endmodule
