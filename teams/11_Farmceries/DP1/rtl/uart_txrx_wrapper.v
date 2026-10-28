/*
 * UART TX->RX Loopback Test Wrapper
 * 
 * Integrates uart_baud_generator, uart_tx, and uart_rx for loopback testing.
 * TX output is connected to RX input for end-to-end verification.
 */

module uart_txrx_wrapper (
    input  wire       clk,
    input  wire       rst_n,
    
    // TX interface
    input  wire [7:0] tx_data,
    input  wire       tx_start,
    output wire       tx_busy,
    
    // RX interface  
    output wire [7:0] rx_data,
    output wire       rx_ready,
    output wire       rx_error,
    
    // Configuration
    input  wire [3:0] baud_sel
);

    // Internal signals
    wire baud_tick;
    wire serial_line;  // TX output → RX input

    // Instantiate baud generator
    uart_baud_generator baud_gen (
        .clk(clk),
        .rst_n(rst_n),
        .baud_sel(baud_sel),
        .enable(1'b1),
        .baud_tick(baud_tick)
    );

    // Instantiate UART transmitter
    uart_tx tx (
        .clk(clk),
        .rst_n(rst_n),
        .baud_tick(baud_tick),
        .tx_data(tx_data),
        .tx_start(tx_start),
        .tx_out(serial_line),
        .tx_busy(tx_busy)
    );

    // Instantiate UART receiver
    uart_rx rx (
        .clk(clk),
        .rst_n(rst_n),
        .rx_in(serial_line),
        .baud_tick(baud_tick),
        .rx_data(rx_data),
        .rx_ready(rx_ready),
        .rx_error(rx_error)
    );

endmodule
