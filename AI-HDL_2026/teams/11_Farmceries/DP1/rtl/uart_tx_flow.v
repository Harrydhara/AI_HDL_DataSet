`default_nettype none

/**
 * UART Transmitter with Flow Control
 * 
 * Wraps uart_tx with CTS (Clear To Send) flow control support.
 * When CTS is asserted (high), transmission is paused.
 * 
 * CTS Protocol:
 * - CTS low (0): Clear to send, TX can transmit
 * - CTS high (1): Not clear to send, TX must wait
 * 
 * Operation:
 * - If flow_ctrl_en = 0: CTS ignored, normal operation
 * - If flow_ctrl_en = 1: TX waits for CTS low before transmitting
 * - TX can be paused mid-transmission if CTS goes high
 * 
 * Note: This module gates the baud_tick to the underlying uart_tx
 * when CTS is asserted, effectively freezing the state machine.
 */
module uart_tx_flow (
    input  wire       clk,            // System clock
    input  wire       rst_n,          // Active-low reset
    input  wire       baud_tick,      // Baud rate tick from generator
    input  wire [7:0] tx_data,        // Data to transmit
    input  wire       tx_start,       // Start transmission (1-cycle pulse)
    input  wire       cts_n,          // Clear To Send (active low)
    input  wire       flow_ctrl_en,   // Flow control enable
    output wire       tx_out,         // Serial output
    output wire       tx_busy         // 1 = transmitting, 0 = idle
);

    // Internal signals
    wire gated_baud_tick;
    wire cts_active;
    
    // CTS is active (blocking transmission) when:
    // - Flow control is enabled AND
    // - CTS is asserted high (not clear to send)
    assign cts_active = flow_ctrl_en && cts_n;
    
    // Gate baud_tick when CTS is active
    // This pauses the TX state machine during flow control
    assign gated_baud_tick = baud_tick && !cts_active;
    
    // Instantiate the base UART TX module
    uart_tx tx_core (
        .clk(clk),
        .rst_n(rst_n),
        .baud_tick(gated_baud_tick),  // Use gated tick
        .tx_data(tx_data),
        .tx_start(tx_start),
        .tx_out(tx_out),
        .tx_busy(tx_busy)
    );

endmodule

`default_nettype wire
