/*
 * Optimized UART Controller
 * - Performance: Replaced 32-bit comparators with zero-detect down-counters.
 * - Power: Strict clock gating on counters (only toggle when busy).
 * - Area: Simplified control logic.
 */

`default_nettype none

module uart_controller (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  ui_in,
    output wire [7:0]  uo_out,
    input  wire [5:0]  address,
    input  wire [31:0] data_in,  
    input  wire [1:0]  data_write_n,
    input  wire [1:0]  data_read_n,
    output reg  [31:0] data_out,
    output reg         data_ready,
    output wire        user_interrupt
);

    // Register Map
    localparam ADDR_DATA   = 6'h00;
    localparam ADDR_INPUT  = 6'h04;
    localparam ADDR_CTRL   = 6'h08;
    localparam ADDR_RX     = 6'h0C;

    // Internal Registers
    reg [31:0] tx_reg;
    reg [31:0] div_reg;
    reg [7:0]  rx_shifter;
    reg        rx_valid;
    reg        test_irq_latched;
    
    // Performance Optimization: Down-Counters
    // Counting down to 0 is faster in hardware than comparing A >= B
    reg [31:0] tx_cnt; 
    reg [31:0] rx_cnt;

    // State Registers
    reg [9:0]  tx_frame;
    reg [3:0]  tx_bit_idx; // 0 = Idle
    reg [3:0]  rx_bit_idx; // 0 = Idle
    reg        rx_pin_r;

    // Helper Signals
    wire rx_pin    = ui_in[0];
    wire write_req = (data_write_n != 2'b11);
    wire read_req  = (data_read_n  != 2'b11);
    wire tx_busy   = (tx_bit_idx != 0);
    
    // Safety: Protect against div_reg == 0 to prevent lock-up
    wire [31:0] div_load_val = (div_reg == 0) ? 32'd100 : div_reg;

    // -------------------------------------------------------------------------
    // Optimization 1: Combinational Read Mux (Pre-calculate next data)
    // -------------------------------------------------------------------------
    reg [31:0] next_data_out;
    always @(*) begin
        case (address)
            ADDR_DATA:  next_data_out = tx_reg;
            ADDR_INPUT: next_data_out = {24'b0, ui_in};
            ADDR_CTRL:  next_data_out = div_reg;
            ADDR_RX:    next_data_out = {23'b0, !tx_busy, rx_valid, rx_shifter};
            default:    next_data_out = 32'b0;
        endcase
    end

    // I/O & Interrupts
    assign uo_out = tx_reg[7:0] + ui_in;
    assign user_interrupt = rx_valid || test_irq_latched;

    // -------------------------------------------------------------------------
    // Main Control Block (Bus + TX)
    // -------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out         <= 32'b0;
            data_ready       <= 1'b0;
            tx_reg           <= 32'b0;
            div_reg          <= 32'b0;
            test_irq_latched <= 1'b0;
            rx_valid         <= 1'b0;
            tx_frame         <= 10'h3FF;
            tx_bit_idx       <= 0;
            tx_cnt           <= 0;
        end else begin
            // Bus Handshake
            data_ready <= (write_req || read_req) && !data_ready;

            // Interrupt Latch
            if (ui_in[6]) test_irq_latched <= 1'b1;

            // Read Operation (Uses optimized mux)
            if (read_req && !data_ready) begin
                data_out <= next_data_out;
                // Clear-on-Read for RX
                if (address == ADDR_RX) rx_valid <= 1'b0; 
            end

            // Write Operation
            if (write_req && !data_ready) begin
                case (address)
                    ADDR_DATA: begin
                        tx_reg <= data_in;
                        if (!tx_busy) begin
                            // Start TX Immediately
                            tx_frame   <= {1'b1, data_in[7:0], 1'b0};
                            tx_bit_idx <= 4'd10;
                            tx_cnt     <= div_load_val; // Load full cycle
                        end
                    end
                    ADDR_CTRL: begin
                        div_reg <= data_in;
                        if (data_in[0]) begin
                            test_irq_latched <= 1'b0;
                            rx_valid         <= 1'b0;
                        end
                    end
                endcase
            end

            // RX Completion Signal (Cross-process)
            if (rx_bit_idx == 4'd10 && rx_cnt == 0) rx_valid <= 1'b1;

            // -----------------------------------------------------------------
            // Optimization 2: TX Logic with Down-Counter
            // -----------------------------------------------------------------
            if (tx_busy) begin
                if (tx_cnt == 0) begin
                    // Bit Finished
                    if (tx_bit_idx == 1) begin
                        tx_bit_idx <= 0; // Done
                    end else begin
                        tx_cnt     <= div_load_val; // Reload
                        tx_frame   <= {1'b1, tx_frame[9:1]};
                        tx_bit_idx <= tx_bit_idx - 1;
                    end
                end else begin
                    tx_cnt <= tx_cnt - 1; // Count Down
                end
            end
        end
    end

    // -------------------------------------------------------------------------
    // UART Receiver Logic (Optimized)
    // -------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_cnt      <= 0;
            rx_bit_idx  <= 0;
            rx_shifter  <= 0;
            rx_pin_r    <= 1'b1;
        end else begin
            rx_pin_r <= rx_pin;

            if (rx_bit_idx == 0) begin
                // Idle: Detect Start Bit (Falling Edge)
                if (rx_pin_r && !rx_pin) begin
                    rx_bit_idx <= 1;
                    // Load HALF cycle for start bit centering
                    // Logic shift right by 1 is cheap/free in hardware
                    rx_cnt <= {1'b0, div_load_val[31:1]}; 
                end
            end else begin
                // Active Receiving
                if (rx_cnt == 0) begin
                    // Timer Expired: Process Bit
                    rx_cnt <= div_load_val; // Reload FULL cycle for next bits

                    if (rx_bit_idx == 4'd10) begin
                        rx_bit_idx <= 0; // Stop bit done, return to idle
                    end else begin
                        rx_bit_idx <= rx_bit_idx + 1;
                        // Sample Data Bits (1-8)
                        // Note: rx_bit_idx is currently 1 (Start), moving to 2 (Data 0)
                        if (rx_bit_idx >= 1 && rx_bit_idx <= 8) begin
                            rx_shifter <= {rx_pin, rx_shifter[7:1]};
                        end
                    end
                end else begin
                    rx_cnt <= rx_cnt - 1; // Count Down
                end
            end
        end
    end

endmodule