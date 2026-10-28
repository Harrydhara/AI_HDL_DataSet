`default_nettype none

/* Testbench wrapper for uart_tx.
   Uses small CLK_HZ/BIT_RATE so each bit takes only 10 system clock cycles,
   making simulation fast.  PAYLOAD_BITS=8, STOP_BITS=1. */
module tb_uart_tx (
    input       clk,
    input       resetn,
    input       uart_tx_en,
    input [7:0] uart_tx_data,
    output      uart_txd,
    output      uart_tx_busy
);

`ifdef COCOTB_SIM
initial begin
    $dumpfile("uart_tx.vcd");
    $dumpvars(0, tb_uart_tx);
    #1;
end
`endif

    uart_tx #(
        .BIT_RATE    (10),
        .CLK_HZ      (100),
        .PAYLOAD_BITS(8),
        .STOP_BITS   (1)
    ) dut (
        .clk         (clk),
        .resetn      (resetn),
        .uart_txd    (uart_txd),
        .uart_tx_busy(uart_tx_busy),
        .uart_tx_en  (uart_tx_en),
        .uart_tx_data(uart_tx_data)
    );

endmodule
