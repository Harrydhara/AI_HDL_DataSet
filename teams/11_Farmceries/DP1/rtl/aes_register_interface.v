// =============================================================================
// File: aes_register_interface.v
// Description: AES Register Interface for CPU Access
//              Provides memory-mapped registers for AES configuration and control
//              Register Map:
//                0x00: CTRL   - Control register (enable, status)
//                0x04: STATUS - Status register (busy, done flags)
//                0x08-0x0B: KEY0-KEY3 - 128-bit encryption key (4x32-bit)
//                0x0C: TX_COUNT - TX buffer byte count
//                0x10: RX_COUNT - RX buffer byte count
// =============================================================================

module aes_register_interface (
    input  wire        clk,
    input  wire        rst_n,
    
    // CPU Bus Interface (32-bit)
    input  wire        bus_write,         // Write enable
    input  wire        bus_read,          // Read enable
    input  wire [7:0]  bus_addr,          // Register address
    input  wire [31:0] bus_wdata,         // Write data
    output reg  [31:0] bus_rdata,         // Read data
    output reg         bus_ready,         // Transaction complete
    
    // AES Controller Interface
    output reg         aes_enable,        // Enable AES operations
    output reg  [127:0] aes_key,          // 128-bit encryption key
    input  wire        tx_busy,           // TX encryption busy
    input  wire        rx_busy,           // RX decryption busy
    input  wire [3:0]  tx_byte_count,     // TX buffer count
    input  wire [3:0]  rx_byte_count      // RX buffer count
);

    // Register Addresses
    localparam ADDR_CTRL     = 8'h00;
    localparam ADDR_STATUS   = 8'h04;
    localparam ADDR_KEY0     = 8'h08;
    localparam ADDR_KEY1     = 8'h0C;
    localparam ADDR_KEY2     = 8'h10;
    localparam ADDR_KEY3     = 8'h14;
    localparam ADDR_TX_COUNT = 8'h18;
    localparam ADDR_RX_COUNT = 8'h1C;
    
    // Control Register Bits
    // [0]: AES_EN - Enable AES encryption/decryption
    // [1]: KEY_LOAD - Load new key (write 1 to update)
    // [31:2]: Reserved
    
    // Status Register Bits  
    // [0]: TX_BUSY - TX encryption in progress
    // [1]: RX_BUSY - RX decryption in progress
    // [2]: KEY_READY - Key loaded and ready
    // [31:3]: Reserved
    
    reg [31:0] ctrl_reg;
    reg        key_ready;
    
    // Register Write
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ctrl_reg <= 32'h0;
            aes_key <= 128'h0;
            key_ready <= 1'b0;
            aes_enable <= 1'b0;
        end else begin
            // Update enable signal
            aes_enable <= ctrl_reg[0];
            
            if (bus_write) begin
                case (bus_addr)
                    ADDR_CTRL: begin
                        ctrl_reg <= bus_wdata;
                    end
                    
                    ADDR_KEY0: begin
                        aes_key[127:96] <= bus_wdata;
                    end
                    
                    ADDR_KEY1: begin
                        aes_key[95:64] <= bus_wdata;
                    end
                    
                    ADDR_KEY2: begin
                        aes_key[63:32] <= bus_wdata;
                    end
                    
                    ADDR_KEY3: begin
                        aes_key[31:0] <= bus_wdata;
                        key_ready <= 1'b1;  // Mark key as ready after last word written
                    end
                endcase
            end
        end
    end
    
    // Register Read
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bus_rdata <= 32'h0;
            bus_ready <= 1'b0;
        end else begin
            bus_ready <= bus_read || bus_write;
            
            if (bus_read) begin
                case (bus_addr)
                    ADDR_CTRL: begin
                        bus_rdata <= ctrl_reg;
                    end
                    
                    ADDR_STATUS: begin
                        bus_rdata <= {29'h0, key_ready, rx_busy, tx_busy};
                    end
                    
                    ADDR_KEY0: begin
                        bus_rdata <= aes_key[127:96];
                    end
                    
                    ADDR_KEY1: begin
                        bus_rdata <= aes_key[95:64];
                    end
                    
                    ADDR_KEY2: begin
                        bus_rdata <= aes_key[63:32];
                    end
                    
                    ADDR_KEY3: begin
                        bus_rdata <= aes_key[31:0];
                    end
                    
                    ADDR_TX_COUNT: begin
                        bus_rdata <= {28'h0, tx_byte_count};
                    end
                    
                    ADDR_RX_COUNT: begin
                        bus_rdata <= {28'h0, rx_byte_count};
                    end
                    
                    default: begin
                        bus_rdata <= 32'h0;
                    end
                endcase
            end else begin
                bus_rdata <= 32'h0;
            end
        end
    end

endmodule
