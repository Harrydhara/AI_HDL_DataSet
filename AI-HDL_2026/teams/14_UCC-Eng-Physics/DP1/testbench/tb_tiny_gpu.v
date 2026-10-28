`timescale 1ns/1ps

module tb_tiny_gpu;

reg clk;
reg rst;
reg [31:0] addr;
reg [31:0] wdata;
reg we;

wire [31:0] rdata;

tiny_gpu dut(

    .clk(clk),
    .rst(rst),
    .addr(addr),
    .wdata(wdata),
    .we(we),
    .rdata(rdata)

);

always #5 clk = ~clk;

initial begin

$dumpfile("designs/tiny_gpu/sim/wave.vcd");
$dumpvars(0,tb_tiny_gpu);

clk = 0;
rst = 1;
we = 0;

#10 rst = 0;

addr = 32'h40000000;
wdata = 3;
we = 1;
#10 we = 0;

addr = 32'h40000004;
wdata = 9;
we = 1;
#10 we = 0;

addr = 32'h40000008;

#10

$display("Result = %d", rdata);

#20 $finish;

end

endmodule
