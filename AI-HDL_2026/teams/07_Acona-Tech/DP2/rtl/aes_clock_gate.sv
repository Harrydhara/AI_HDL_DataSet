//============================================================================
// Module: aes_clock_gate
// Description: Integrated Clock Gating (ICG) Cell for Power Optimization
//
// Purpose:
//   - Reduces dynamic power by gating clock to inactive modules
//   - Uses latch-based design to prevent clock glitches
//   - Industry-standard ICG cell structure
//
// How it works:
//   - When enable=0, gated_clk is held LOW (no clock pulses)
//   - When enable=1, gated_clk follows input clk
//   - Latch captures enable on falling edge to prevent glitches
//
// Power Savings:
//   - Eliminates clock tree power to gated registers
//   - Eliminates register switching power when disabled
//   - Typical savings: 15-30% dynamic power
//
// Usage:
//   aes_clock_gate u_cg (
//       .clk       (clk),
//       .enable    (module_active),
//       .test_mode (scan_enable),    // Bypass for DFT
//       .gated_clk (module_clk)
//   );
//
// Author: AIHDL 2026 Competition Team (Team Acona)
// Date: February 2026
// Phase: DP2 - PPA Optimization
//============================================================================

module aes_clock_gate (
    input  wire clk,        // Input clock
    input  wire enable,     // Clock enable (1 = clock passes, 0 = clock blocked)
    input  wire test_mode,  // Test mode bypass (for scan/DFT)
    output wire gated_clk   // Gated clock output
);

    //------------------------------------------------------------------------
    // Latch-based Clock Gating
    //------------------------------------------------------------------------
    // The enable signal is latched on the FALLING edge of the clock.
    // This ensures the gated clock has clean edges without glitches.
    //
    // Timing diagram:
    //
    // clk:        ───┐   ┌───┐   ┌───┐   ┌───┐   ┌───
    //                └───┘   └───┘   └───┘   └───┘
    //
    // enable:     ─────────────┐           ┌─────────
    //             (enable=1)   └───────────┘ (enable=0)
    //
    // latch_out:  ─────────────────┐       ┌─────────
    //             (captures on     └───────┘
    //              falling edge)
    //
    // gated_clk:  ───┐   ┌───┐   ┌─┐       ┌───┐   ┌─
    //                └───┘   └───┘ └───────┘   └───┘
    //             (clean edges, no glitches)
    //------------------------------------------------------------------------
    
    reg enable_latch;
    
    // Latch enable on falling edge of clock (when clk is LOW)
    // This is a level-sensitive latch, not an edge-triggered flip-flop
    always @(*) begin
        if (!clk) begin
            enable_latch <= enable | test_mode;
        end
    end
    
    // AND the latched enable with the clock
    assign gated_clk = clk & enable_latch;

endmodule


//============================================================================
// Module: aes_clock_gate_sync
// Description: Synchronous Clock Gating (Alternative Implementation)
//
// This version uses a flip-flop instead of a latch.
// Slightly more area but easier for some synthesis tools.
//============================================================================

module aes_clock_gate_sync (
    input  wire clk,        // Input clock
    input  wire rst_n,      // Active-low reset
    input  wire enable,     // Clock enable
    input  wire test_mode,  // Test mode bypass
    output wire gated_clk   // Gated clock output
);

    reg enable_ff;
    
    // Register enable on falling edge (negedge)
    always @(negedge clk or negedge rst_n) begin
        if (!rst_n) begin
            enable_ff <= 1'b0;
        end else begin
            enable_ff <= enable | test_mode;
        end
    end
    
    // AND with clock
    assign gated_clk = clk & enable_ff;

endmodule
