//============================================================================
// Module: tqvp_aes128
// Description: AES-128 Crypto Accelerator Top-Level Module
//
// FIX:
// - DO NOT invert decrypt into key_expansion (it breaks encryption).
// - Instead, remap round_num ONLY for key_expansion when decrypt=1 to cancel
//   key_expansion's internal reverse (key_select = 10 - round_num).
//
// Result:
// - Encryption uses round_num as-is (0..10)  -> correct
// - Decryption: core outputs 10..0, but key_expansion expects 0..10 because it
//   will internally do (10 - round_num). So feed (10 - core_round_num) into it.
//============================================================================

module tqvp_aes128 (
    input  wire         clk,
    input  wire         rst_n,

    input  wire [7:0]   ui_in,
    output wire [7:0]   uo_out,

    input  wire [5:0]   address,
    input  wire [31:0]  data_in,
    input  wire [1:0]   data_write_n,
    input  wire [1:0]   data_read_n,
    output wire [31:0]  data_out,
    output wire         data_ready,

    output wire         user_interrupt
);

    // Register interface to AES core
    wire [127:0] key_reg;
    wire [127:0] din_reg;
    wire [127:0] dout_reg;
    wire         start;
    wire         decrypt;
    wire         key_load;

    // AES core status
    wire         core_busy;
    wire         core_done;

    // Key expansion
    wire         key_valid;
    wire         key_busy;
    wire [127:0] round_key;
    wire [3:0]   round_num;          // from aes_core
    wire [3:0]   round_num_keyexp;   // to aes_key_expansion (fixed mapping)

    // GPIO not used
    assign uo_out = 8'h00;

    //------------------------------------------------------------------------
    // Register Interface
    //------------------------------------------------------------------------
    aes_reg_interface u_reg_interface (
        .clk            (clk),
        .rst_n          (rst_n),

        .address        (address),
        .data_in        (data_in),
        .data_write_n   (data_write_n),
        .data_read_n    (data_read_n),
        .data_out       (data_out),
        .data_ready     (data_ready),

        .key_reg        (key_reg),
        .din_reg        (din_reg),
        .dout_reg       (dout_reg),
        .start          (start),
        .decrypt        (decrypt),
        .busy           (core_busy),
        .done           (core_done),
        .key_load       (key_load),
        .key_valid      (key_valid),
        .key_busy       (key_busy),

        .user_interrupt (user_interrupt)
    );

    //------------------------------------------------------------------------
    // Round number remap ONLY for key_expansion
    // aes_key_expansion does:
    //   key_select = decrypt ? (10 - round_num_in) : round_num_in
    //
    // We want the final selected key index to match aes_core's round_num output.
    // So:
    //   encrypt: round_num_in = round_num
    //   decrypt: round_num_in = 10 - round_num   (cancels the internal 10-)
    //------------------------------------------------------------------------
    assign round_num_keyexp = decrypt ? (4'd10 - round_num) : round_num;

    //------------------------------------------------------------------------
    // Key Expansion
    //------------------------------------------------------------------------
    aes_key_expansion u_key_expansion (
        .clk            (clk),
        .rst_n          (rst_n),
        .cipher_key     (key_reg),
        .key_load       (key_load),
        .round_num      (round_num_keyexp), // FIXED
        .decrypt        (decrypt),          // DO NOT invert
        .round_key      (round_key),
        .key_valid      (key_valid),
        .key_busy       (key_busy)
    );

    //------------------------------------------------------------------------
    // AES Core
    //------------------------------------------------------------------------
    aes_core u_aes_core (
        .clk            (clk),
        .rst_n          (rst_n),
        .data_in        (din_reg),
        .round_key      (round_key),
        .decrypt        (decrypt),
        .start          (start),
        .data_out       (dout_reg),
        .round_num      (round_num),
        .busy           (core_busy),
        .done           (core_done)
    );

endmodule
