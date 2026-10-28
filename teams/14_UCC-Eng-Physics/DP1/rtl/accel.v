module accel(
    input clk,
    input rst,
    input [31:0] addr,
    input [31:0] wdata,
    input we,
    output reg [31:0] rdata
);

reg [31:0] reg0;

always @(posedge clk) begin
    if (rst)
        reg0 <= 32'b0;
    else if (we)
        reg0 <= wdata;
end

always @(*) begin
    rdata = reg0;
end

endmodule
