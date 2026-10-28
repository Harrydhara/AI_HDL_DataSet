//============================================================================
// Module: tqvp_aes128_opt
// Description: AES-128 Crypto Accelerator with Clock Gating Optimization
//
// DP2 OPTIMIZATION: Clock Gating
// ─────────────────────────────────
// This module adds clock gating to reduce dynamic power consumption.
//
// FIX: Added registered enable to prevent clock gating race condition
//
// Author: AIHDL 2026 Competition Team (Team Acona)
// Date: February 2026
// Phase: DP2 - PPA Optimization
//============================================================================

module tqvp_aes128_opt (
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
    wire [3:0]   round_num;
    wire [3:0]   round_num_keyexp;

    // GPIO not used
    assign uo_out = 8'h00;

    //========================================================================
    // DP2 OPTIMIZATION: Clock Gating Signals (FIXED)
    //========================================================================
    
    // Clock enable signals
    wire core_clk_enable;
    wire key_exp_clk_enable;
    
    // Gated clocks
    wire core_gated_clk;
    wire key_exp_gated_clk;
    
    //------------------------------------------------------------------------
    // FIX: Registered enable to hold clock on after start pulse
    //------------------------------------------------------------------------
    // Problem: start is HIGH for only 1 cycle, then goes LOW
    //          But core_busy needs a clock edge to go HIGH
    //          If we gate the clock when start goes LOW, core never starts!
    //
    // Solution: Use a registered "running" signal that stays HIGH
    //           until the operation completes
    //------------------------------------------------------------------------
    
    reg core_running;
    reg key_exp_running;
    
    // Core running register - stays HIGH from start until done
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            core_running <= 1'b0;
        end else if (start) begin
            core_running <= 1'b1;  // Set on start
        end else if (core_done) begin
            core_running <= 1'b0;  // Clear on done
        end
    end
    
    // Key expansion running register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            key_exp_running <= 1'b0;
        end else if (key_load) begin
            key_exp_running <= 1'b1;  // Set on key_load
        end else if (key_valid && !key_busy) begin
            key_exp_running <= 1'b0;  // Clear when keys ready
        end
    end
    
    //------------------------------------------------------------------------
    // Clock Enable Logic (FIXED)
    //------------------------------------------------------------------------
    // Core clock: enable when starting, running, or finishing
    assign core_clk_enable = start | core_running | core_busy | core_done;
    
    // Key expansion clock: enable when loading keys, expanding, or core active
    assign key_exp_clk_enable = key_load | key_exp_running | key_busy | core_running | core_busy | start;
    
    //------------------------------------------------------------------------
    // Clock Gating Cells
    //------------------------------------------------------------------------
    
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
    // Register Interface (Always clocked - needs to respond to CPU)
    //========================================================================
    aes_reg_interface u_reg_interface (
        .clk            (clk),          // NOT gated - must always respond
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
    // Round Number Remapping (Same as DP1)
    //========================================================================
    assign round_num_keyexp = decrypt ? (4'd10 - round_num) : round_num;

    //========================================================================
    // Key Expansion (With Gated Clock)
    //========================================================================
    aes_key_expansion u_key_expansion (
        .clk            (key_exp_gated_clk),  // DP2: GATED CLOCK
        .rst_n          (rst_n),
        .cipher_key     (key_reg),
        .key_load       (key_load),
        .round_num      (round_num_keyexp),
        .decrypt        (decrypt),
        .round_key      (round_key),
        .key_valid      (key_valid),
        .key_busy       (key_busy)
    );

    //========================================================================
    // AES Core (With Gated Clock)
    //========================================================================
    aes_core u_aes_core (
        .clk            (core_gated_clk),     // DP2: GATED CLOCK
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
// Module: tqvp_aes128_top_opt
// Description: Top-Level Wrapper for Optimized AES-128 Accelerator
//============================================================================

module tqvp_aes128_top_opt (
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

    tqvp_aes128_opt u_aes128_core_opt (
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
