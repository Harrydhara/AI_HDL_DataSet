`default_nettype none
module pe_activation #(
    parameter ACT_RELU = 1,      // enable ReLU
    parameter QUANT_SHIFT = 0    // right-shift for quantization
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] acc_in,
    output reg  [31:0] acc_out
);

    wire [31:0] relu_out;
    wire [31:0] quant_out;

    // ReLU: max(0, x)
    assign relu_out = ACT_RELU ? (acc_in[31] ? 32'd0 : acc_in) : acc_in;

    // Quantization: shift right
    assign quant_out = relu_out >> QUANT_SHIFT;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            acc_out <= 32'd0;
        else
            acc_out <= quant_out;
    end

endmodule
