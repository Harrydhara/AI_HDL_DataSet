//============================================================================
// Module: tqvp_aes128_opt_v4
// Description: Fully Optimized AES-128 with Pipelined Key Fetch
//
// DP2 OPTIMIZATIONS:
//   1. Clock Gating - Power reduction (~88% idle savings)
//   2. Fast MixColumns - Reduced InvMixColumns logic depth
//   3. Unrolled Key Expansion - Pre-computed round keys
//   4. Pipelined Key Fetch - Register between key MUX and core
//
// Expected Results:
//   - Logic Depth: 30 → ~15 levels (-50%)
//   - Cycles: 12 → 22 (+10 cycles)
//   - Same throughput at higher Fmax
//
// Author: AIHDL 2026 Competition Team (Team Acona)
// Date: February 2026
// Phase: DP2 - PPA Optimization
//============================================================================

module tqvp_aes128_opt_v4 (
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

    //========================================================================
    // Internal Signals
    //========================================================================
    wire [127:0] key_reg;
    wire [127:0] din_reg;
    wire [127:0] dout_reg;
    wire         start;
    wire         decrypt;
    wire         key_load;

    wire         core_busy;
    wire         core_done;

    wire         key_valid;
    wire         key_busy;
    wire [127:0] round_key;
    wire [3:0]   round_num;

    assign uo_out = 8'h00;

    //========================================================================
    // Clock Gating
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
    // Register Interface
    //========================================================================
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

    //========================================================================
    // Unrolled Key Expansion
    //========================================================================
    aes_key_expansion_unrolled u_key_expansion (
        .clk            (key_exp_gated_clk),
        .rst_n          (rst_n),
        .cipher_key     (key_reg),
        .key_load       (key_load),
        .round_num      (round_num),
        .decrypt        (decrypt),
        .round_key      (round_key),
        .key_valid      (key_valid),
        .key_busy       (key_busy)
    );

    //========================================================================
    // AES Core with Pipelined Key Fetch
    //========================================================================
    aes_core_fast_v2 u_aes_core (
        .clk            (core_gated_clk),
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


//============================================================================
// Top-Level Wrapper
//============================================================================

module tqvp_aes128_top_opt_v4 (
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

    tqvp_aes128_opt_v4 u_aes128 (
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
