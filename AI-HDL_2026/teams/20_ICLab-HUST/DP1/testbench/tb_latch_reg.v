`default_nettype none

/* Testbench wrapper for latch_reg_p (positive-edge, configurable width).
   latch_reg_p is the variant used by tinyQV_time (via latch_reg32_p).
   WIDTH is fixed at 8 here; Python test interacts via the 8-bit ports. */
module tb_latch_reg #(parameter WIDTH = 8) (
    input              clk,
    input              wen,
    input  [WIDTH-1:0] data_in,
    output [WIDTH-1:0] data_out
);

`ifdef COCOTB_SIM
initial begin
    $dumpfile("latch_reg.vcd");
    $dumpvars(0, tb_latch_reg);
    #1;
end
`endif

    latch_reg_p #(.WIDTH(WIDTH)) dut (
        .clk     (clk),
        .wen     (wen),
        .data_in (data_in),
        .data_out(data_out)
    );

endmodule
