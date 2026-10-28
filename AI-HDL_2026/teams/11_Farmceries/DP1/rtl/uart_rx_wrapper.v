/*
 * UART RX Test Wrapper
 * 
 * Integrates uart_baud_generator and uart_rx for testing.
 * This allows the test to only drive rx_in and baud_sel,
 * while the baud_tick is generated internally.
 */

module uart_rx_wrapper (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       rx_in,
    input  wire [3:0] baud_sel,
    output wire [7:0] rx_data,
    output wire       rx_ready,
    output wire       rx_error
);

    // Internal baud tick
    wire baud_tick;

    // Instantiate baud generator
    uart_baud_generator baud_gen (
        .clk(clk),
        .rst_n(rst_n),
        .baud_sel(baud_sel),
        .enable(1'b1),  // Always enabled for testing
        .baud_tick(baud_tick)
    );

    // Instantiate UART receiver
    uart_rx rx (
        .clk(clk),
        .rst_n(rst_n),
        .rx_in(rx_in),
        .baud_tick(baud_tick),
        .rx_data(rx_data),
        .rx_ready(rx_ready),
        .rx_error(rx_error)
    );

endmodule
