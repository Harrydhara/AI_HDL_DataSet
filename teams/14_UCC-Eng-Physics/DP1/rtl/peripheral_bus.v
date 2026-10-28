`timescale 1ns/1ps

module peripheral_bus(

    input wire clk,
    input wire rst,

    input wire [31:0] addr,
    input wire [31:0] wdata,
    input wire we,

    output wire [31:0] rdata,

    output wire [31:0] accel_rdata

);

assign rdata = accel_rdata;

endmodule
