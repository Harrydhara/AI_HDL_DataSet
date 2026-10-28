//============================================================================
// Module: tqvp_aes128_top
// Description: Top-Level Wrapper for AES-128 Crypto Accelerator
//              This module provides the synthesis entry point and wraps
//              the main tqvp_aes128 module for TinyQV integration.
//
// Purpose:
//   - Provides consistent top-level module name for synthesis tools
//   - Matches expected module hierarchy for AIHDL 2026 competition
//   - Direct pass-through to tqvp_aes128 core implementation
//
// Author: AIHDL 2026 Competition Team (Team Acona)
// Date: January 2026
// Target: TinyQV RISC-V Peripheral (64MHz)
//============================================================================

module tqvp_aes128_top (
    //------------------------------------------------------------------------
    // System Interface
    //------------------------------------------------------------------------
    input  wire         clk,            // System clock (64MHz target)
    input  wire         rst_n,          // Active-low reset
    
    //------------------------------------------------------------------------
    // TinyQV GPIO Interface
    //------------------------------------------------------------------------
    input  wire [7:0]   ui_in,          // 8-bit user input (directly from pins)
    output wire [7:0]   uo_out,         // 8-bit user output (directly to pins)
    
    //------------------------------------------------------------------------
    // TinyQV Peripheral Bus Interface
    //------------------------------------------------------------------------
    input  wire [5:0]   address,        // Register address offset
    input  wire [31:0]  data_in,        // Write data from CPU
    input  wire [1:0]   data_write_n,   // Write transaction width (0,1,2=8,16,32-bit; 3=none)
    input  wire [1:0]   data_read_n,    // Read transaction width (0,1,2=8,16,32-bit; 3=none)
    output wire [31:0]  data_out,       // Read data to CPU
    output wire         data_ready,     // Read data valid
    
    //------------------------------------------------------------------------
    // Interrupt Interface
    //------------------------------------------------------------------------
    output wire         user_interrupt  // Interrupt request to CPU
);

    //------------------------------------------------------------------------
    // Core AES-128 Accelerator Instance
    //------------------------------------------------------------------------
    tqvp_aes128 u_aes128_core (
        // System Interface
        .clk            (clk),
        .rst_n          (rst_n),
        
        // TinyQV GPIO Interface
        .ui_in          (ui_in),
        .uo_out         (uo_out),
        
        // TinyQV Peripheral Bus Interface
        .address        (address),
        .data_in        (data_in),
        .data_write_n   (data_write_n),
        .data_read_n    (data_read_n),
        .data_out       (data_out),
        .data_ready     (data_ready),
        
        // Interrupt Interface
        .user_interrupt (user_interrupt)
    );

endmodule
