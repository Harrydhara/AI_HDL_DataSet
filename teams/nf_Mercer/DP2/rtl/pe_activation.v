`default_nettype none
// ---------------------------------------------------------------------------
// pe_activation  –  Post-MAC activation (ReLU + optional quantization shift)
// ---------------------------------------------------------------------------
module pe_activation #(
    parameter ACT_RELU    = 1,   // 1 = ReLU enabled
    parameter QUANT_SHIFT = 0    // right-shift amount for quantization
)(
    input  wire [31:0] acc_in,
    output wire [31:0] acc_out
);
    wire [31:0] relu_out;

    // ReLU: pass through when positive, zero otherwise (MSB = sign)
    assign relu_out = (ACT_RELU && acc_in[31]) ? 32'd0 : acc_in;

    // Quantization shift (reduces to nothing when QUANT_SHIFT == 0)
    assign acc_out  = relu_out >> QUANT_SHIFT;

endmodule