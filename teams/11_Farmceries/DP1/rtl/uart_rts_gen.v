`default_nettype none

/**
 * UART RTS (Request To Send) Generator
 * 
 * Generates RTS signal based on RX FIFO status for hardware flow control.
 * 
 * RTS Protocol:
 * - RTS low (0): Ready to receive, remote can send
 * - RTS high (1): Not ready, remote should pause transmission
 * 
 * Operation:
 * - Monitors rx_fifo_watermark signal (asserted when FIFO ≥ threshold)
 * - When watermark is reached, asserts RTS to signal remote to stop
 * - When watermark clears, deasserts RTS to allow remote to resume
 * 
 * Optional hysteresis can be added to prevent RTS toggling on boundary conditions.
 * Current implementation uses direct mapping for simplicity.
 */
module uart_rts_gen (
    input  wire clk,                // System clock
    input  wire rst_n,              // Active-low reset
    input  wire rx_fifo_watermark,  // RX FIFO watermark status
    input  wire flow_ctrl_en,       // Flow control enable
    output reg  rts_n               // Request To Send (active low)
);

    // RTS generation logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rts_n <= 1'b0;  // Default: ready (low) to receive
        end else begin
            if (flow_ctrl_en) begin
                // RTS is active-low: 0 = ready to receive, 1 = not ready
                // Direct mapping: watermark=0 -> RTS=0 (ready), watermark=1 -> RTS=1 (not ready)
                rts_n <= rx_fifo_watermark;
            end else begin
                // Flow control disabled: always ready
                rts_n <= 1'b0;
            end
        end
    end

endmodule

`default_nettype wire
