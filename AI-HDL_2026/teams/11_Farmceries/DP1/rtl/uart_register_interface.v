`default_nettype none

/**
 * UART Register Interface
 * 
 * Memory-mapped register interface for UART control/status.
 * Connects TinyQV CPU bus to UART TX/RX modules.
 * 
 * Register Map (6-bit address space):
 * 0x00 - CTRL:      [3:0] baud_sel, [4] tx_enable, [5] rx_enable
 * 0x04 - STATUS:    [0] tx_busy, [1] rx_ready, [2] rx_error (read-only)
 * 0x08 - TX_DATA:   [7:0] data to transmit (write triggers transmission)
 * 0x0C - RX_DATA:   [7:0] received data (read-only)
 * 0x10 - INT_EN:    [0] tx_done_int_en, [1] rx_ready_int_en
 * 0x14 - INT_CLR:   [0] clear_tx_int, [1] clear_rx_int (write 1 to clear)
 * 0x18 - FLOW_CTRL: [0] flow_ctrl_en (enable RTS/CTS flow control)
 */
module uart_register_interface (
    input  wire        clk,
    input  wire        rst_n,
    
    // CPU Bus Interface (from peripheral.v)
    input  wire [5:0]  address,
    input  wire [31:0] data_in,
    input  wire [1:0]  data_write_n,  // 11=no write, 00=8bit, 01=16bit, 10=32bit
    input  wire [1:0]  data_read_n,   // 11=no read, 00=8bit, 01=16bit, 10=32bit
    output wire [31:0] data_out,
    output wire        data_ready,
    
    // UART TX Interface
    output wire [7:0]  tx_data,
    output reg         tx_start,
    input  wire        tx_busy,
    
    // UART RX Interface
    input  wire [7:0]  rx_data,
    input  wire        rx_ready,
    input  wire        rx_error,
    output reg         rx_data_read,  // Pulse when CPU reads RX_DATA
    
    // Baud rate selection
    output wire [3:0]  baud_sel,
    
    // Flow control enable
    output wire        flow_ctrl_en,
    
    // Interrupt output
    output wire        uart_interrupt
);

    // Register addresses
    localparam ADDR_CTRL      = 6'h00;
    localparam ADDR_STATUS    = 6'h04;
    localparam ADDR_TX_DATA   = 6'h08;
    localparam ADDR_RX_DATA   = 6'h0C;
    localparam ADDR_INT_EN    = 6'h10;
    localparam ADDR_INT_CLR   = 6'h14;
    localparam ADDR_FLOW_CTRL = 6'h18;
    
    // Registers
    reg [7:0] ctrl_reg;       // [3:0] baud_sel, [4] tx_en, [5] rx_en
    reg [7:0] tx_data_reg;    // Data to transmit
    reg [7:0] rx_data_reg;    // Received data (latched)
    reg [1:0] int_en_reg;     // [0] tx_done_int_en, [1] rx_ready_int_en
    reg [1:0] int_status_reg; // [0] tx_done_pending, [1] rx_ready_pending
    reg       flow_ctrl_reg;  // [0] flow_ctrl_en
    
    // Status flags (read-only, directly from UART modules)
    wire [7:0] status_reg;
    assign status_reg = {5'b0, rx_error, rx_ready, tx_busy};
    
    // Extract baud_sel from control register
    assign baud_sel = ctrl_reg[3:0];
    
    // Extract flow control enable
    assign flow_ctrl_en = flow_ctrl_reg;
    
    // Assign tx_data output
    assign tx_data = tx_data_reg;
    
    // Write logic + interrupt management (combined to avoid multiple drivers)
    wire write_en = (data_write_n != 2'b11);
    wire read_en = (data_read_n != 2'b11);
    reg tx_busy_prev;  // Track tx_busy edge for interrupt generation
    reg rx_ready_prev; // Track rx_ready edge for interrupt generation
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ctrl_reg       <= 8'h00;  // Default: 9600 baud (sel=0), disabled
            tx_data_reg    <= 8'h00;
            tx_start       <= 1'b0;
            int_en_reg     <= 2'b00;
            int_status_reg <= 2'b00;
            tx_busy_prev   <= 1'b0;
            rx_ready_prev  <= 1'b0;
            flow_ctrl_reg  <= 1'b0;   // Flow control disabled by default
            rx_data_read   <= 1'b0;
        end else begin
            // Default: clear single-cycle pulses
            tx_start <= 1'b0;
            rx_data_read <= 1'b0;
            
            // Track tx_busy for edge detection
            tx_busy_prev <= tx_busy;
            
            // Track rx_ready for interrupt edge detection
            rx_ready_prev <= rx_ready;
            
            // Set interrupt on rx_ready rising edge (FIFO transition from empty to non-empty)
            if (rx_ready && !rx_ready_prev) begin
                int_status_reg[1] <= 1'b1;
            end
            
            // Set TX interrupt when transmission completes (tx_busy falling edge)
            if (tx_busy_prev && !tx_busy) begin
                int_status_reg[0] <= 1'b1;  // Set TX done interrupt
            end
            
            // Handle CPU writes
            if (write_en) begin
                case (address)
                    ADDR_CTRL: begin
                        ctrl_reg <= data_in[7:0];
                    end
                    
                    ADDR_TX_DATA: begin
                        // Writing to TX_DATA triggers transmission
                        tx_data_reg <= data_in[7:0];
                        tx_start    <= 1'b1;  // Pulse for 1 cycle
                    end
                    
                    ADDR_INT_EN: begin
                        int_en_reg <= data_in[1:0];
                    end
                    
                    ADDR_INT_CLR: begin
                        // Write 1 to clear interrupt (has priority over setting)
                        if (data_in[0]) int_status_reg[0] <= 1'b0;
                        if (data_in[1]) int_status_reg[1] <= 1'b0;
                    end
                    
                    ADDR_FLOW_CTRL: begin
                        flow_ctrl_reg <= data_in[0];
                    end
                    
                    default: begin
                        // Ignore writes to undefined addresses
                    end
                endcase
            end
            
            // Handle CPU reads - generate rx_data_read pulse
            if (read_en && address == ADDR_RX_DATA) begin
                rx_data_read <= 1'b1;  // Pulse for 1 cycle
            end
        end
    end
    
    // Read logic
    reg [31:0] read_data;
    
    always @(*) begin
        case (address)
            ADDR_CTRL:      read_data = {24'h0, ctrl_reg};
            ADDR_STATUS:    read_data = {24'h0, status_reg};
            ADDR_TX_DATA:   read_data = {24'h0, tx_data_reg};
            ADDR_RX_DATA:   read_data = {24'h0, rx_data};  // Read directly from FIFO output
            ADDR_INT_EN:    read_data = {30'h0, int_en_reg};
            ADDR_INT_CLR:   read_data = {30'h0, int_status_reg};
            ADDR_FLOW_CTRL: read_data = {31'h0, flow_ctrl_reg};
            default:        read_data = 32'h00000000;
        endcase
    end
    
    assign data_out = read_data;
    
    // All reads complete in 1 cycle
    assign data_ready = 1'b1;
    
    // Generate interrupt signal
    assign uart_interrupt = |(int_status_reg & int_en_reg);
    
    // Prevent warnings for unused signals
    wire _unused = &{data_read_n, 1'b0};

endmodule

`default_nettype wire
