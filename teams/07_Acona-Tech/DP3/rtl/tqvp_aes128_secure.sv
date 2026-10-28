//============================================================================
// Module: tqvp_aes128_secure
// Description: Security-Hardened AES-128 Top-Level for TinyQV
//
// Based on: tqvp_aes128_opt_v4 (DP2 final submission)
//
// DP3 SECURITY ADDITIONS:
//   1. aes_masking_lfsr     — Random mask generation for DPA resistance
//   2. aes_sbox_masked      — Used inside aes_core_secure (16 instances)
//   3. aes_fault_detector   — Shadow round counter for glitch detection
//   4. Secure reg interface — KEY_LOCK, ZEROIZE, LFSR_SEED registers
//   5. Ciphertext suppression on fault detection
//
// All DP2 optimizations preserved:
//   - Clock gating (88% idle power reduction)
//   - Fast MixColumns (parallel xtime)
//   - Unrolled key expansion (pre-computed round keys)
//   - Pipelined key fetch (22-cycle latency)
//
// Address bus: Extended from 6-bit to 7-bit for security registers
//
// Author: AIHDL 2026 Team Acona | DP3 Security Phase
//============================================================================

module tqvp_aes128_secure (
    input  wire         clk,
    input  wire         rst_n,

    input  wire [7:0]   ui_in,
    output wire [7:0]   uo_out,

    input  wire [6:0]   address,        // Extended to 7-bit for security regs
    input  wire [31:0]  data_in,
    input  wire [1:0]   data_write_n,
    input  wire [1:0]   data_read_n,
    output wire [31:0]  data_out,
    output wire         data_ready,

    output wire         user_interrupt
);

    //========================================================================
    // Internal Signals (DP2 original)
    //========================================================================
    wire [127:0] key_reg;
    wire [127:0] din_reg;
    wire [127:0] core_dout;       // Raw output from core
    wire [127:0] dout_to_reg;     // Potentially suppressed output to reg interface
    wire         start;
    wire         decrypt_mode;
    wire         key_load;

    wire         core_busy;
    wire         core_done;
    wire         core_done_gated; // Done gated by fault status

    wire         key_valid;
    wire         key_busy;
    wire [127:0] round_key;
    wire [3:0]   round_num;

    assign uo_out = 8'h00;

    //========================================================================
    // DP3 Security Signals
    //========================================================================
    wire         key_locked;
    wire         zeroize_pulse;
    wire [31:0]  lfsr_seed_data;
    wire         lfsr_seed_we;
    wire         fault_detected;
    wire         output_valid;
    wire         masking_active;
    wire [31:0]  lfsr_rand;

    // Fault detection interface from core
    wire         round_start;
    wire         encryption_start;
    wire [3:0]   round_count_out;

    //========================================================================
    // DP3: Ciphertext Suppression on Fault
    // If fault detected, force output to zero and suppress done signal
    //========================================================================
    assign dout_to_reg  = fault_detected ? 128'h0 : core_dout;
    assign core_done_gated = core_done & ~fault_detected;

    //========================================================================
    // Clock Gating (same as DP2)
    //========================================================================
    wire core_clk_enable;
    wire key_exp_clk_enable;
    wire core_gated_clk;
    wire key_exp_gated_clk;
    
    reg core_running;
    reg key_exp_running;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            core_running <= 1'b0;
        else if (start)
            core_running <= 1'b1;
        else if (core_done)
            core_running <= 1'b0;
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            key_exp_running <= 1'b0;
        else if (key_load)
            key_exp_running <= 1'b1;
        else if (key_valid && !key_busy)
            key_exp_running <= 1'b0;
    end
    
    assign core_clk_enable = start | core_running | core_busy | core_done;
    assign key_exp_clk_enable = key_load | key_exp_running | key_busy | core_running | core_busy | start;
    
    aes_clock_gate u_core_cg (
        .clk       (clk),
        .enable    (core_clk_enable),
        .test_mode (1'b0),
        .gated_clk (core_gated_clk)
    );
    
    aes_clock_gate u_key_exp_cg (
        .clk       (clk),
        .enable    (key_exp_clk_enable),
        .test_mode (1'b0),
        .gated_clk (key_exp_gated_clk)
    );

    //========================================================================
    // DP3: Masking LFSR
    //========================================================================
    aes_masking_lfsr u_lfsr (
        .clk       (clk),
        .rst_n     (rst_n),
        .enable    (core_busy),           // Generate masks while encrypting
        .seed_we   (lfsr_seed_we),
        .seed_data (lfsr_seed_data),
        .rand_out  (lfsr_rand),
        .valid     (masking_active)
    );

    //========================================================================
    // Security-Hardened Register Interface
    //========================================================================
    aes_reg_interface_secure u_reg_interface (
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
        .dout_reg       (dout_to_reg),        // DP3: Potentially suppressed output
        .start          (start),
        .decrypt        (decrypt_mode),
        .busy           (core_busy),
        .done           (core_done_gated),    // DP3: Gated by fault status
        .key_load       (key_load),
        .key_valid      (key_valid),
        .key_busy       (key_busy),
        .user_interrupt (user_interrupt),
        // DP3 Security
        .key_locked     (key_locked),
        .zeroize_pulse  (zeroize_pulse),
        .lfsr_seed_data (lfsr_seed_data),
        .lfsr_seed_we   (lfsr_seed_we),
        .fault_detected (fault_detected),
        .masking_active (masking_active)
    );

    //========================================================================
    // Unrolled Key Expansion (same as DP2, with zeroize support added)
    //========================================================================
    aes_key_expansion_unrolled u_key_expansion (
        .clk            (key_exp_gated_clk),
        .rst_n          (rst_n & ~zeroize_pulse),  // DP3: Reset on zeroize
        .cipher_key     (key_reg),
        .key_load       (key_load),
        .round_num      (round_num),
        .decrypt        (decrypt_mode),
        .round_key      (round_key),
        .key_valid      (key_valid),
        .key_busy       (key_busy)
    );

    //========================================================================
    // Security-Hardened AES Core
    //========================================================================
    aes_core_secure u_aes_core (
        .clk              (core_gated_clk),
        .rst_n            (rst_n),
        .data_in          (din_reg),
        .round_key        (round_key),
        .decrypt          (decrypt_mode),
        .start            (start),
        .data_out         (core_dout),
        .round_num        (round_num),
        .busy             (core_busy),
        .done             (core_done),
        // DP3 Security: Masking
        .lfsr_rand        (lfsr_rand),
        .mask_enable      (masking_active),
        // DP3 Security: Fault Detection
        .round_start      (round_start),
        .encryption_start (encryption_start),
        .round_count_out  (round_count_out),
        // DP3 Security: Zeroization
        .zeroize          (zeroize_pulse)
    );

    //========================================================================
    // DP3: Fault Detector (Shadow Round Counter)
    //========================================================================
    aes_fault_detector u_fault_detector (
        .clk              (clk),
        .rst_n            (rst_n),
        .round_start      (round_start),
        .encryption_start (encryption_start),
        .encryption_done  (core_done),
        .fsm_round_count  (round_count_out),
        .clear_fault      (zeroize_pulse),
        .fault_detected   (fault_detected),
        .output_valid     (output_valid)
    );

endmodule


//============================================================================
// Top-Level Wrapper (matches competition interface)
//============================================================================

module tqvp_aes128_top_secure (
    input  wire         clk,
    input  wire         rst_n,
    
    input  wire [7:0]   ui_in,
    output wire [7:0]   uo_out,
    
    input  wire [6:0]   address,        // 7-bit for security registers
    input  wire [31:0]  data_in,
    input  wire [1:0]   data_write_n,
    input  wire [1:0]   data_read_n,
    output wire [31:0]  data_out,
    output wire         data_ready,
    
    output wire         user_interrupt
);

    tqvp_aes128_secure u_aes128 (
        .clk            (clk),
        .rst_n          (rst_n),
        .ui_in          (ui_in),
        .uo_out         (uo_out),
        .address        (address),
        .data_in        (data_in),
        .data_write_n   (data_write_n),
        .data_read_n    (data_read_n),
        .data_out       (data_out),
        .data_ready     (data_ready),
        .user_interrupt (user_interrupt)
    );

endmodule
