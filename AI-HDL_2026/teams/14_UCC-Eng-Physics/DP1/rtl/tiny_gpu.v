`timescale 1ns/1ps

module tiny_gpu(

    input wire clk,
    input wire rst,

    input wire [31:0] addr,
    input wire [31:0] wdata,
    input wire we,

    output wire [31:0] rdata

);

wire [31:0] accel_rdata;

ai_accelerator accel(

    .clk(clk),
    .rst(rst),
    .addr(addr),
    .wdata(wdata),
    .we(we),
    .rdata(accel_rdata)

);

assign rdata = accel_rdata;

endmodule
