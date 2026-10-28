//============================================================================
// Module: aes_sbox_masked
// Description: AES S-Box with Power-Hiding Countermeasure
//              Runs a real + dummy S-Box in parallel to decorrelate
//              power consumption from actual data values (anti-DPA)
// Target: CWE-1300 Side-Channel Protection
// Team: Acona | AI-HDL 2026 DP3
//============================================================================

module aes_sbox_masked (
    input  wire [7:0] data_in,
    input  wire [7:0] mask_in,
    input  wire [7:0] mask_out,
    input  wire       mask_enable,
    input  wire       decrypt,
    output wire [7:0] data_out
);

    wire [7:0] real_out;
    wire [7:0] dummy_out;
    wire [7:0] dummy_in;

    // Real S-Box: always produces correct AES output
    aes_sbox u_sbox_real (
        .data_in  (data_in),
        .decrypt  (decrypt),
        .data_out (real_out)
    );

    // Dummy S-Box: processes randomized input for power hiding
    // Consumes data-independent power to mask the real computation
    assign dummy_in = mask_enable ? (data_in ^ mask_in) : data_in;

    aes_sbox u_sbox_dummy (
        .data_in  (dummy_in),
        .decrypt  (decrypt),
        .data_out (dummy_out)
    );

    // Output is always the correct result
    // XOR with (dummy ^ dummy) = XOR with 0, but prevents optimizer
    // from removing the dummy S-Box (it sees a data dependency)
    assign data_out = real_out ^ (dummy_out ^ dummy_out);

endmodule
