/*
 * Secure UART Peripheral with Integrated AES-128 Encryption
 * 
 * Complete implementation combining UART communication with transparent
 * AES encryption/decryption. CPU interface remains simple: write/read
 * plaintext while encryption happens automatically in hardware.
 * 
 * Features:
 * - Transparent AES-128 encryption/decryption (when enabled)
 * - Bypass mode for plaintext transmission (when disabled)
 * - Standard UART functionality (baud rate, flow control, interrupts)
 * - CPU writes plaintext, UART transmits ciphertext
 * - UART receives ciphertext, CPU reads plaintext
 * 
 * Register Map:
 * 0x00 - UART_CTRL:    [3:0] baud_sel, [4] tx_enable, [5] rx_enable
 * 0x04 - UART_STATUS:  [0] tx_busy, [1] rx_ready, [2] rx_error
 * 0x08 - TX_DATA:      Write plaintext byte (encrypted before transmission)
 * 0x0C - RX_DATA:      Read plaintext byte (decrypted after reception)
 * 0x10 - INT_EN:       [0] tx_done_int_en, [1] rx_ready_int_en
 * 0x14 - INT_CLR:      [0] clear_tx, [1] clear_rx
 * 
 * 0x20 - AES_CTRL:     [0] AES_EN (enable encryption/decryption)
 * 0x24 - AES_STATUS:   [0] TX_ENCRYPTING, [1] RX_DECRYPTING, [2] KEY_READY
 * 0x28 - AES_KEY0:     Key [127:96]
 * 0x2C - AES_KEY1:     Key [95:64]
 * 0x30 - AES_KEY2:     Key [63:32]
 * 0x34 - AES_KEY3:     Key [31:0]
 */

`default_nettype none

module secure_uart_peripheral #(
    // 16 = full AES-128 buffering, lower values enable reduced block mode.
    parameter integer AES_BLOCK_BYTES = 16
) (
    input  wire        clk,
    input  wire        rst_n,
    
    // UART Physical Interface
    input  wire        uart_rx_pin,
    output wire        uart_tx_pin,
    
    // Flow Control (optional)
    input  wire        cts_n,
    output wire        rts_n,
    
    // CPU Register Interface
    input  wire [5:0]  address,
    input  wire [31:0] data_in,
    input  wire [1:0]  data_write_n,
    input  wire [1:0]  data_read_n,
    output reg  [31:0] data_out,
    output reg         data_ready,
    
    // Interrupt
    output wire        interrupt
);

    // =========================================================================
    // Register Decode
    // =========================================================================
    
    localparam ADDR_UART_CTRL   = 6'h00;
    localparam ADDR_UART_STATUS = 6'h04;
    localparam ADDR_TX_DATA     = 6'h08;
    localparam ADDR_RX_DATA     = 6'h0C;
    localparam ADDR_INT_EN      = 6'h10;
    localparam ADDR_INT_CLR     = 6'h14;
    
    localparam ADDR_AES_CTRL    = 6'h20;
    localparam ADDR_AES_STATUS  = 6'h24;
    localparam ADDR_AES_KEY0    = 6'h28;
    localparam ADDR_AES_KEY1    = 6'h2C;
    localparam ADDR_AES_KEY2    = 6'h30;
    localparam ADDR_AES_KEY3    = 6'h34;
    
    wire bus_write = (data_write_n == 2'b00);
    wire bus_read = (data_read_n == 2'b00);
    
    // =========================================================================
    // Configuration Registers
    // =========================================================================
    
    reg [5:0] uart_ctrl_reg;    // [3:0] baud_sel, [4] tx_en, [5] rx_en
    reg [1:0] int_en_reg;
    reg       aes_enable_reg;
    reg [127:0] aes_key_reg;
    reg       aes_key_ready;
    
    wire [3:0] baud_sel = uart_ctrl_reg[3:0];
    wire       uart_tx_en = uart_ctrl_reg[4];
    wire       uart_rx_en = uart_ctrl_reg[5];
    wire       aes_enable = aes_enable_reg;
    wire       baud_enable;
    
    // =========================================================================
    // UART Core Modules
    // =========================================================================
    
    wire baud_tick;
    
    uart_baud_generator baud_gen (
        .clk(clk),
        .rst_n(rst_n),
        .baud_sel(baud_sel),
        .enable(baud_enable),
        .baud_tick(baud_tick)
    );
    
    // TX Path
    wire uart_tx_busy;
    reg [7:0] uart_tx_data;
    reg uart_tx_start;
    
    uart_tx transmitter (
        .clk(clk),
        .rst_n(rst_n),
        .baud_tick(baud_tick),
        .tx_data(uart_tx_data),
        .tx_start(uart_tx_start),
        .tx_out(uart_tx_pin),
        .tx_busy(uart_tx_busy)
    );
    
    // RX Path
    wire [7:0] uart_rx_data;
    wire uart_rx_ready;
    wire uart_rx_error;
    
    uart_rx receiver (
        .clk(clk),
        .rst_n(rst_n),
        .rx_in(uart_rx_pin),
        .baud_tick(baud_tick),
        .rx_data(uart_rx_data),
        .rx_ready(uart_rx_ready),
        .rx_error(uart_rx_error)
    );
    
    assign rts_n = 1'b0;  // Always ready (simplified for now)
    
    // =========================================================================
    // AES Streaming Controller
    // =========================================================================
    
    wire [7:0] aes_tx_out;
    wire aes_tx_valid;
    wire aes_tx_ready;
    wire [7:0] aes_rx_out;
    wire aes_rx_valid;
    wire aes_rx_ready;
    wire aes_tx_busy;
    wire aes_rx_busy;
    
    // Signals for CPU interface
    reg cpu_tx_write;
    reg [7:0] cpu_tx_data;
    reg cpu_rx_read;
    
    aes_uart_streaming #(
        .BLOCK_BYTES(AES_BLOCK_BYTES)
    ) aes_stream (
        .clk(clk),
        .rst_n(rst_n),
        .aes_enable(aes_enable),
        .aes_key(aes_key_reg),
        
        // TX: CPU write → AES → UART transmit
        .tx_data_in(cpu_tx_data),
        .tx_valid_in(cpu_tx_write),
        .tx_ready_out(aes_tx_ready),
        .tx_data_out(aes_tx_out),
        .tx_valid_out(aes_tx_valid),
        .tx_ready_in(uart_tx_en && ~uart_tx_busy),
        
        // RX: UART receive → AES → CPU read
        .rx_data_in(uart_rx_data),
        .rx_valid_in(uart_rx_en && uart_rx_ready),
        .rx_ready_out(aes_rx_ready),
        .rx_data_out(aes_rx_out),
        .rx_valid_out(aes_rx_valid),
        .rx_ready_in(cpu_rx_read),

        .tx_busy_out(aes_tx_busy),
        .rx_busy_out(aes_rx_busy)
    );
    
    // Connect AES output to UART TX
    always @(posedge clk) begin
        uart_tx_start <= 1'b0;
        if (uart_tx_en && aes_tx_valid && !uart_tx_busy) begin
            uart_tx_data <= aes_tx_out;
            uart_tx_start <= 1'b1;
        end
    end
    
    // =========================================================================
    // CPU Register Interface
    // =========================================================================
    
    reg [7:0] rx_data_buffer;
    reg rx_data_available;
    
    // Capture decrypted data for CPU reads
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_data_buffer <= 8'h0;
            rx_data_available <= 1'b0;
        end else begin
            if (aes_rx_valid) begin
                rx_data_buffer <= aes_rx_out;
                rx_data_available <= 1'b1;
            end else if (cpu_rx_read) begin
                rx_data_available <= 1'b0;
            end
        end
    end
    
    // Keep baud generation active only when UART is enabled or datapaths are busy.
    assign baud_enable = uart_tx_en || uart_rx_en || uart_tx_busy || aes_tx_busy || aes_rx_busy;

    // Register Write
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            uart_ctrl_reg <= 6'h0;
            int_en_reg <= 2'b0;
            aes_enable_reg <= 1'b0;
            aes_key_reg <= 128'h0;
            aes_key_ready <= 1'b0;
            cpu_tx_write <= 1'b0;
            cpu_tx_data <= 8'h0;
        end else begin
            cpu_tx_write <= 1'b0;
            
            if (bus_write) begin
                case (address)
                    ADDR_UART_CTRL: uart_ctrl_reg <= data_in[5:0];
                    ADDR_INT_EN: int_en_reg <= data_in[1:0];
                    
                    ADDR_TX_DATA: begin
                        cpu_tx_data <= data_in[7:0];
                        cpu_tx_write <= 1'b1;
                    end
                    
                    ADDR_AES_CTRL: aes_enable_reg <= data_in[0];
                    ADDR_AES_KEY0: aes_key_reg[127:96] <= data_in;
                    ADDR_AES_KEY1: aes_key_reg[95:64] <= data_in;
                    ADDR_AES_KEY2: aes_key_reg[63:32] <= data_in;
                    ADDR_AES_KEY3: begin
                        aes_key_reg[31:0] <= data_in;
                        aes_key_ready <= 1'b1;
                    end
                endcase
            end
        end
    end
    
    // Register Read
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 32'h0;
            data_ready <= 1'b0;
            cpu_rx_read <= 1'b0;
        end else begin
            data_ready <= bus_read || bus_write;
            cpu_rx_read <= 1'b0;
            
            if (bus_read) begin
                case (address)
                    ADDR_UART_CTRL: data_out <= {26'h0, uart_ctrl_reg};
                    
                    ADDR_UART_STATUS: begin
                        data_out <= {29'h0, uart_rx_error, rx_data_available, uart_tx_busy};
                    end
                    
                    ADDR_RX_DATA: begin
                        data_out <= {24'h0, rx_data_buffer};
                        cpu_rx_read <= 1'b1;
                    end
                    
                    ADDR_INT_EN: data_out <= {30'h0, int_en_reg};
                    
                    ADDR_AES_CTRL: data_out <= {31'h0, aes_enable_reg};
                    
                    ADDR_AES_STATUS: begin
                        data_out <= {29'h0, aes_key_ready, aes_rx_busy, aes_tx_busy};
                    end
                    
                    ADDR_AES_KEY0: data_out <= aes_key_reg[127:96];
                    ADDR_AES_KEY1: data_out <= aes_key_reg[95:64];
                    ADDR_AES_KEY2: data_out <= aes_key_reg[63:32];
                    ADDR_AES_KEY3: data_out <= aes_key_reg[31:0];
                    
                    default: data_out <= 32'h0;
                endcase
            end else begin
                data_out <= 32'h0;
            end
        end
    end
    
    // =========================================================================
    // Interrupt Logic
    // =========================================================================
    
    reg tx_done_pending;
    reg rx_ready_pending;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_done_pending <= 1'b0;
            rx_ready_pending <= 1'b0;
        end else begin
            // TX done when UART completes and AES not busy
            if (!uart_tx_busy && aes_tx_valid)
                tx_done_pending <= 1'b1;
            else if (bus_write && address == ADDR_INT_CLR && data_in[0])
                tx_done_pending <= 1'b0;
            
            // RX ready when data available in buffer
            if (rx_data_available)
                rx_ready_pending <= 1'b1;
            else if (bus_write && address == ADDR_INT_CLR && data_in[1])
                rx_ready_pending <= 1'b0;
        end
    end
    
    assign interrupt = (int_en_reg[0] && tx_done_pending) || 
                       (int_en_reg[1] && rx_ready_pending);

endmodule

`default_nettype wire
