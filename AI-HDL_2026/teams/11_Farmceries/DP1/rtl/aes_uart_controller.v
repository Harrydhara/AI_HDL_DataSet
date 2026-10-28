// =============================================================================
// File: aes_uart_controller.v
// Description: AES-UART Integration Controller
//              Manages AES encryption/decryption for UART TX/RX data paths
//              Buffers 16 bytes, triggers AES operations, interfaces with registers
// =============================================================================

module aes_uart_controller (
    input  wire        clk,
    input  wire        rst_n,
    
    // AES Configuration
    input  wire        aes_enable,        // Enable AES encryption/decryption
    input  wire [127:0] aes_key,          // 128-bit encryption key
    
    // TX Path (Plaintext -> Ciphertext)
    input  wire        tx_data_valid,     // New TX byte available
    input  wire [7:0]  tx_data_in,        // Plaintext byte from CPU
    output reg         tx_data_ready,     // Ready to accept more TX data
    output reg         tx_block_valid,    // 16-byte encrypted block ready
    output reg  [127:0] tx_block_out,     // Ciphertext block to UART TX
    output reg         tx_block_read,     // Pulse to read encrypted block
    
    // RX Path (Ciphertext -> Plaintext)
    input  wire        rx_data_valid,     // New RX byte from UART
    input  wire [7:0]  rx_data_in,        // Ciphertext byte from UART
    output reg         rx_block_valid,    // 16-byte decrypted block ready
    output reg  [127:0] rx_block_out,     // Plaintext block to CPU
    input  wire        rx_block_read,     // CPU read decrypted block
    
    // Status
    output wire        tx_busy,           // TX encryption in progress
    output wire        rx_busy            // RX decryption in progress
);

    // TX Path State Machine
    localparam TX_IDLE      = 2'b00;
    localparam TX_BUFFER    = 2'b01;
    localparam TX_ENCRYPT   = 2'b10;
    localparam TX_OUTPUT    = 2'b11;
    
    reg [1:0] tx_state, tx_next_state;
    reg [3:0] tx_byte_count;          // Count bytes (0-15)
    reg [127:0] tx_plaintext_buffer;  // 16-byte buffer for plaintext
    
    // RX Path State Machine
    localparam RX_IDLE      = 2'b00;
    localparam RX_BUFFER    = 2'b01;
    localparam RX_DECRYPT   = 2'b10;
    localparam RX_OUTPUT    = 2'b11;
    
    reg [1:0] rx_state, rx_next_state;
    reg [3:0] rx_byte_count;          // Count bytes (0-15)
    reg [127:0] rx_ciphertext_buffer; // 16-byte buffer for ciphertext
    
    // AES Core Signals
    reg         aes_tx_start;
    wire        aes_tx_done;
    wire        aes_tx_busy_internal;
    wire [127:0] aes_tx_ciphertext;
    
    reg         aes_rx_start;
    wire        aes_rx_done;
    wire        aes_rx_busy_internal;
    wire [127:0] aes_rx_plaintext;
    
    // Instantiate AES cores for TX (encryption) and RX (decryption)
    aes_core aes_tx_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(aes_tx_start),
        .mode(1'b0),                // Encrypt mode
        .plaintext(tx_plaintext_buffer),
        .key(aes_key),
        .ciphertext(aes_tx_ciphertext),
        .done(aes_tx_done),
        .busy(aes_tx_busy_internal)
    );
    
    aes_core aes_rx_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(aes_rx_start),
        .mode(1'b1),                // Decrypt mode
        .plaintext(rx_ciphertext_buffer),
        .key(aes_key),
        .ciphertext(aes_rx_plaintext),
        .done(aes_rx_done),
        .busy(aes_rx_busy_internal)
    );
    
    assign tx_busy = (tx_state != TX_IDLE);
    assign rx_busy = (rx_state != RX_IDLE);
    
    // =========================================================================
    // TX Path: Plaintext Buffering & Encryption
    // =========================================================================
    
    // TX State Transition
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            tx_state <= TX_IDLE;
        else
            tx_state <= tx_next_state;
    end
    
    // TX Next State Logic
    always @(*) begin
        tx_next_state = tx_state;
        case (tx_state)
            TX_IDLE: begin
                if (aes_enable && tx_data_valid)
                    tx_next_state = TX_BUFFER;
            end
            TX_BUFFER: begin
                if (tx_byte_count == 15 && tx_data_valid)
                    tx_next_state = TX_ENCRYPT;
            end
            TX_ENCRYPT: begin
                if (aes_tx_done)
                    tx_next_state = TX_OUTPUT;
            end
            TX_OUTPUT: begin
                tx_next_state = TX_IDLE;
            end
        endcase
    end
    
    // TX Datapath
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_byte_count <= 4'd0;
            tx_plaintext_buffer <= 128'h0;
            tx_block_out <= 128'h0;
            tx_block_valid <= 1'b0;
            tx_data_ready <= 1'b1;
            aes_tx_start <= 1'b0;
            tx_block_read <= 1'b0;
        end else begin
            aes_tx_start <= 1'b0;
            tx_block_read <= 1'b0;
            
            case (tx_state)
                TX_IDLE: begin
                    tx_byte_count <= 4'd0;
                    tx_block_valid <= 1'b0;
                    tx_data_ready <= aes_enable;
                    
                    if (aes_enable && tx_data_valid) begin
                        // First byte starts buffering
                        tx_plaintext_buffer <= {120'h0, tx_data_in};
                        tx_byte_count <= 4'd1;
                    end
                end
                
                TX_BUFFER: begin
                    if (tx_data_valid && tx_byte_count < 16) begin
                        // Shift in new byte (MSB first for AES block)
                        tx_plaintext_buffer <= {tx_plaintext_buffer[119:0], tx_data_in};
                        tx_byte_count <= tx_byte_count + 1;
                        
                        // If this is the 16th byte, start encryption
                        if (tx_byte_count == 15) begin
                            aes_tx_start <= 1'b1;
                        end
                    end
                    tx_data_ready <= (tx_byte_count < 15);
                end
                
                TX_ENCRYPT: begin
                    tx_data_ready <= 1'b0;
                end
                
                TX_OUTPUT: begin
                    tx_block_out <= aes_tx_ciphertext;
                    tx_block_valid <= 1'b1;
                    tx_block_read <= 1'b1;  // Pulse to indicate data ready
                end
            endcase
        end
    end
    
    // =========================================================================
    // RX Path: Ciphertext Buffering & Decryption
    // =========================================================================
    
    // RX State Transition
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            rx_state <= RX_IDLE;
        else
            rx_state <= rx_next_state;
    end
    
    // RX Next State Logic
    always @(*) begin
        rx_next_state = rx_state;
        case (rx_state)
            RX_IDLE: begin
                if (aes_enable && rx_data_valid)
                    rx_next_state = RX_BUFFER;
            end
            RX_BUFFER: begin
                if (rx_byte_count == 15 && rx_data_valid)
                    rx_next_state = RX_DECRYPT;
            end
            RX_DECRYPT: begin
                if (aes_rx_done)
                    rx_next_state = RX_OUTPUT;
            end
            RX_OUTPUT: begin
                if (rx_block_read)
                    rx_next_state = RX_IDLE;
            end
        endcase
    end
    
    // RX Datapath
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_byte_count <= 4'd0;
            rx_ciphertext_buffer <= 128'h0;
            rx_block_out <= 128'h0;
            rx_block_valid <= 1'b0;
            aes_rx_start <= 1'b0;
        end else begin
            aes_rx_start <= 1'b0;
            
            case (rx_state)
                RX_IDLE: begin
                    rx_byte_count <= 4'd0;
                    rx_block_valid <= 1'b0;
                    
                    if (aes_enable && rx_data_valid) begin
                        // First byte starts buffering
                        rx_ciphertext_buffer <= {120'h0, rx_data_in};
                        rx_byte_count <= 4'd1;
                    end
                end
                
                RX_BUFFER: begin
                    if (rx_data_valid && rx_byte_count < 16) begin
                        // Shift in new byte (MSB first)
                        rx_ciphertext_buffer <= {rx_ciphertext_buffer[119:0], rx_data_in};
                        rx_byte_count <= rx_byte_count + 1;
                        
                        // If this is the 16th byte, start decryption
                        if (rx_byte_count == 15) begin
                            aes_rx_start <= 1'b1;
                        end
                    end
                end
                
                RX_DECRYPT: begin
                    // Wait for decryption to complete
                end
                
                RX_OUTPUT: begin
                    rx_block_out <= aes_rx_plaintext;
                    rx_block_valid <= 1'b1;
                    if (rx_block_read) begin
                        rx_block_valid <= 1'b0;
                    end
                end
            endcase
        end
    end

endmodule
