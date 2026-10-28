`default_nettype none

/**
 * UART Peripheral with FIFOs and Flow Control
 * 
 * Complete UART peripheral integrating:
 * - Baud rate generator
 * - UART transmitter with CTS flow control
 * - UART receiver
 * - TX and RX FIFO buffers (16 bytes each)
 * - RTS generation for RX flow control
 * - Memory-mapped register interface
 * 
 * Features:
 * - 16-byte TX FIFO for burst writes
 * - 16-byte RX FIFO with watermark detection
 * - Hardware flow control (RTS/CTS)
 * - Configurable flow control enable
 */
module uart_peripheral (
    input  wire        clk,          // System clock (70 MHz)
    input  wire        rst_n,        // Active-low reset
    
    // TinyQV CPU Bus Interface
    input  wire [5:0]  address,      // Register address
    input  wire [31:0] data_in,      // Write data
    input  wire [1:0]  data_write_n, // Write control
    input  wire [1:0]  data_read_n,  // Read control
    output wire [31:0] data_out,     // Read data
    output wire        data_ready,   // Read data valid
    
    // UART Physical Interface
    input  wire        uart_rx,      // UART RX input
    output wire        uart_tx,      // UART TX output
    
    // Flow Control Signals
    input  wire        cts_n,        // Clear To Send input (active low)
    output wire        rts_n,        // Request To Send output (active low)
    
    // Interrupt output
    output wire        uart_interrupt
);

    // Internal signals
    wire [3:0] baud_sel;
    wire       baud_tick;
    wire       flow_ctrl_en;
    
    // TX path signals
    wire [7:0] tx_data_from_reg;
    wire       tx_start_from_reg;
    wire       tx_busy_to_reg;
    
    // TX FIFO signals
    wire [7:0] tx_fifo_data;
    wire       tx_fifo_wr_en;
    wire       tx_fifo_rd_en;
    wire       tx_fifo_full;
    wire       tx_fifo_empty;
    wire [4:0] tx_fifo_count;
    
    // TX control signals
    wire [7:0] tx_data_to_uart;
    wire       tx_start_to_uart;
    wire       tx_busy_from_uart;
    
    // RX path signals
    wire [7:0] rx_data_from_uart;
    wire       rx_ready_from_uart;
    wire       rx_error_from_uart;
    
    // RX FIFO signals
    wire [7:0] rx_fifo_data;
    wire       rx_fifo_wr_en;
    wire       rx_fifo_rd_en;
    wire       rx_fifo_full;
    wire       rx_fifo_empty;
    wire       rx_fifo_watermark;
    wire [4:0] rx_fifo_count;
    
    // RX signals to register interface
    wire [7:0] rx_data_to_reg;
    wire       rx_ready_to_reg;
    wire       rx_data_read;  // Pulse from register interface when CPU reads
    
    //=========================================================================
    // Baud Rate Generator
    //=========================================================================
    uart_baud_generator baud_gen (
        .clk(clk),
        .rst_n(rst_n),
        .baud_sel(baud_sel),
        .enable(1'b1),
        .baud_tick(baud_tick)
    );
    
    //=========================================================================
    // TX Path: Register -> TX FIFO -> UART TX with Flow Control
    //=========================================================================
    
    // TX FIFO: Buffers data from CPU writes
    // TX FIFO watermark output (unused)
    wire tx_fifo_watermark;
    uart_fifo #(
        .DEPTH(16),
        .DATA_WIDTH(8),
        .WATERMARK(14)
    ) tx_fifo (
        .clk(clk),
        .rst_n(rst_n),
        .wr_data(tx_data_from_reg),
        .wr_en(tx_start_from_reg && !tx_fifo_full),  // Write when CPU writes TX_DATA
        .rd_data(tx_data_to_uart),
        .rd_en(tx_fifo_rd_en),
        .full(tx_fifo_full),
        .empty(tx_fifo_empty),
        .watermark(tx_fifo_watermark),  // Unused but connected for clean synthesis
        .count(tx_fifo_count)
    );
    
    // TX FIFO read control: Read when UART is idle and FIFO has data
    assign tx_fifo_rd_en = !tx_busy_from_uart && !tx_fifo_empty;
    assign tx_start_to_uart = tx_fifo_rd_en;  // Start TX when reading from FIFO
    
    // Report busy to register interface if FIFO has data or UART is busy
    assign tx_busy_to_reg = !tx_fifo_empty || tx_busy_from_uart;
    
    // UART Transmitter with Flow Control
    uart_tx_flow transmitter (
        .clk(clk),
        .rst_n(rst_n),
        .baud_tick(baud_tick),
        .tx_data(tx_data_to_uart),
        .tx_start(tx_start_to_uart),
        .cts_n(cts_n),
        .flow_ctrl_en(flow_ctrl_en),
        .tx_out(uart_tx),
        .tx_busy(tx_busy_from_uart)
    );
    
    //=========================================================================
    // RX Path: UART RX -> RX FIFO -> Register Interface
    //=========================================================================
    
    // UART Receiver
    uart_rx receiver (
        .clk(clk),
        .rst_n(rst_n),
        .rx_in(uart_rx),
        .baud_tick(baud_tick),
        .rx_data(rx_data_from_uart),
        .rx_ready(rx_ready_from_uart),
        .rx_error(rx_error_from_uart)
    );
    
    // RX FIFO: Buffers received data
    uart_fifo #(
        .DEPTH(16),
        .DATA_WIDTH(8),
        .WATERMARK(14)
    ) rx_fifo (
        .clk(clk),
        .rst_n(rst_n),
        .wr_data(rx_data_from_uart),
        .wr_en(rx_ready_from_uart && !rx_fifo_full),  // Write when byte received
        .rd_data(rx_data_to_reg),
        .rd_en(rx_fifo_rd_en),
        .full(rx_fifo_full),
        .empty(rx_fifo_empty),
        .watermark(rx_fifo_watermark),
        .count(rx_fifo_count)
    );
    
    // RX FIFO read control: Read when CPU reads RX_DATA register
    assign rx_ready_to_reg = !rx_fifo_empty;
    assign rx_fifo_rd_en = rx_data_read && !rx_fifo_empty;
    
    //=========================================================================
    // RTS Generation
    //=========================================================================
    uart_rts_gen rts_generator (
        .clk(clk),
        .rst_n(rst_n),
        .rx_fifo_watermark(rx_fifo_watermark),
        .flow_ctrl_en(flow_ctrl_en),
        .rts_n(rts_n)
    );
    
    //=========================================================================
    // Register Interface
    //=========================================================================
    uart_register_interface reg_interface (
        .clk(clk),
        .rst_n(rst_n),
        
        // CPU bus
        .address(address),
        .data_in(data_in),
        .data_write_n(data_write_n),
        .data_read_n(data_read_n),
        .data_out(data_out),
        .data_ready(data_ready),
        
        // TX interface
        .tx_data(tx_data_from_reg),
        .tx_start(tx_start_from_reg),
        .tx_busy(tx_busy_to_reg),
        
        // RX interface
        .rx_data(rx_data_to_reg),
        .rx_ready(rx_ready_to_reg),
        .rx_error(rx_error_from_uart),  // Error signal directly from UART
        .rx_data_read(rx_data_read),     // Output: pulse when CPU reads RX_DATA
        
        // Configuration
        .baud_sel(baud_sel),
        .flow_ctrl_en(flow_ctrl_en),
        
        // Interrupt
        .uart_interrupt(uart_interrupt)
    );

endmodule

`default_nettype wire
