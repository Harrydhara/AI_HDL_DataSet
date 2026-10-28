`timescale 1ns/1ps

module ai_accelerator(

    input wire clk,
    input wire rst,

    input wire [31:0] addr,
    input wire [31:0] wdata,
    input wire we,

    output reg [31:0] rdata

);

reg [31:0] a;
reg [31:0] b;
reg [31:0] result;

always @(posedge clk) begin

    if(rst) begin
        a <= 0;
        b <= 0;
        result <= 0;
    end

    else if(we) begin
        case(addr)

            32'h40000000: a <= wdata;
            32'h40000004: b <= wdata;

        endcase
    end

end

always @(posedge clk)

    result <= a * b;

always @(*)

    if(addr == 32'h40000008)
        rdata = result;
    else
        rdata = 0;

endmodule
