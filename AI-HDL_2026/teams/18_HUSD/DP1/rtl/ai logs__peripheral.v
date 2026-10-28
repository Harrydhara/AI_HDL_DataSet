/*
 * Copyright (c) 2025 Tiny Tapeout
 * SPDX-License-Identifier: Apache-2.0
 *
 * Optimized 32-bit UART Controller
 * - Area: Unified counters, reduced redundant registers.
 * - Power: Gated logic for shifter and counters.
 * - Performance: Optimized critical paths in bus muxing.
 */

`default_nettype none

module uart_controller (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  ui_in,         // Dedicated inputs (ui_in[0] = RX)
    output wire [7:0]  uo_out,        // Dedicated outputs
    input  wire [5:0]  address,       // Register Address
    input  wire [31:0] data_in,       // Write Data
    input  wire [1:0]  data_write_n,  // Write Strobe (Active Low)
    input  wire [1:0]  data_read_n,   // Read Strobe (Active Low)
    output reg  [31:0] data_out,      // Read Data
    output reg         data_ready,    // Transaction Complete
    output wire        user_interrupt // Interrupt signal
);

    // -------------------------------------------------------------------------
    // Register Map & Constants
    // -------------------------------------------------------------------------
    localparam ADDR_DATA   = 6'h00; // R/W: TX Data
    localparam ADDR_INPUT  = 6'h04; // R:   ui_in Mirror
    localparam ADDR_CTRL   = 6'h08; // R/W: Divisor & IRQ Clear
    localparam ADDR_RX     = 6'h0C; // R:   RX Data & Status

    // -------------------------------------------------------------------------
    // Internal Signals & Registers
    // -------------------------------------------------------------------------
    reg [31:0] tx_reg;           // TX Data Storage
    reg [31:0] div_reg;          // Baud Rate Divisor
    reg [7:0]  rx_shifter;       // RX Shift Register
    reg        rx_valid;         // Data Ready Flag
    reg        test_irq_latched; // External Test IRQ Latch
    
    // UART TX State
    reg [31:0] tx_cnt;
    reg [9:0]  tx_frame;         // Frame: Stop(1) + Data(8) + Start(1)
    reg [3:0]  tx_bit_idx;       // TX Bit Counter (0 = Idle)
    
    // UART RX State
    reg [31:0] rx_cnt;
    reg [3:0]  rx_bit_idx;       // RX Bit Counter (0 = Idle)
    reg        rx_pin_r;         // Registered RX Pin (Metastability/Edge)

    // Helper Wires
    wire rx_pin    = ui_in[0];
    wire write_req = (data_write_n != 2'b11);
    wire read_req  = (data_read_n  != 2'b11);
    wire tx_busy   = (tx_bit_idx != 0);
    
    // Optimization: Pre-calculate cycle limit to avoid redundant MUX logic
    wire [31:0] div_cycle = (div_reg == 0) ? 32'd100 : div_reg;
    
    // Optimization: RX Completion Flag (Signals main block to set rx_valid)
    wire rx_finished = (rx_bit_idx == 4'd10) && (rx_cnt >= div_cycle);

    // -------------------------------------------------------------------------
    // I/O Assignments
    // -------------------------------------------------------------------------
    // Test Requirement: uo_out = Reg0 + ui_in
    assign uo_out = tx_reg[7:0] + ui_in;

    // Interrupt Logic: Active High if RX Valid OR Test Latch is set
    assign user_interrupt = rx_valid || test_irq_latched;

    // -------------------------------------------------------------------------
    // Main Control Block (Bus Interface + TX Logic)
    // -------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out         <= 32'b0;
            data_ready       <= 1'b0;
            tx_reg           <= 32'b0;
            div_reg          <= 32'b0;
            test_irq_latched <= 1'b0;
            rx_valid         <= 1'b0;
            
            // TX Reset
            tx_frame         <= 10'h3FF; // Default Idle (All 1s)
            tx_bit_idx       <= 0;
            tx_cnt           <= 0;
        end else begin
            // --- 1. Bus Handshake ---
            data_ready <= (write_req || read_req) && !data_ready;

            // --- 2. Interrupt Management ---
            // Priority: Clear (Write/Read) > Set (RX Finish/External)
            
            // Set RX Valid when receiver finishes
            if (rx_finished) rx_valid <= 1'b1;

            // Latch External Test Interrupt (Rising Edge / High Level)
            if (ui_in[6]) test_irq_latched <= 1'b1;

            // --- 3. Write Operations ---
            if (write_req && !data_ready) begin
                case (address)
                    ADDR_DATA: begin
                        tx_reg <= data_in;
                        // Start TX if Idle: Load Stop(1) + Data + Start(0)
                        if (!tx_busy) begin
                            tx_frame   <= {1'b1, data_in[7:0], 1'b0};
                            tx_bit_idx <= 4'd10; // 10 Bits to transmit
                            tx_cnt     <= 0;
                        end
                    end
                    ADDR_CTRL: begin
                        div_reg <= data_in;
                        // Write 1 to Bit 0 clears global interrupts
                        if (data_in[0]) begin
                            test_irq_latched <= 1'b0;
                            rx_valid         <= 1'b0; // Explicit Clear overrides Set
                        end
                    end
                endcase
            end

            // --- 4. Read Operations ---
            if (read_req && !data_ready) begin
                case (address)
                    ADDR_DATA:  data_out <= tx_reg;
                    ADDR_INPUT: data_out <= {24'b0, ui_in};
                    ADDR_CTRL:  data_out <= div_reg;
                    ADDR_RX: begin
                        // Status: {Reserved, !Busy, Valid, Data}
                        data_out <= {23'b0, !tx_busy, rx_valid, rx_shifter};
                        rx_valid <= 1'b0; // "Read-to-Clear" behavior
                    end
                    default:    data_out <= 32'b0;
                endcase
            end

            // --- 5. UART Transmitter Logic ---
            if (tx_busy) begin
                if (tx_cnt >= div_cycle) begin
                    tx_cnt     <= 0;
                    tx_frame   <= {1'b1, tx_frame[9:1]}; // Shift Right
                    tx_bit_idx <= tx_bit_idx - 1;        // Decrement Bit Count
                end else begin
                    tx_cnt <= tx_cnt + 1;
                end
            end
        end
    end

    // -------------------------------------------------------------------------
    // UART Receiver Logic
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
                // Idle State: Detect Falling Edge (Start Bit)
                if (rx_pin_r && !rx_pin) begin
                    rx_bit_idx <= 1; // Move to Start Bit
                    rx_cnt     <= div_cycle >> 1; // Wait half-bit period (Sample middle)
                end
            end else begin
                // Active State
                if (rx_cnt >= div_cycle) begin
                    rx_cnt <= 0;
                    rx_bit_idx <= rx_bit_idx + 1;

                    // Sampling Logic
                    case (rx_bit_idx)
                        4'd1: ; // Start Bit (Skip/Ignore)
                        // Data Bits (Indices 2-9 map to Bits 0-7)
                        4'd2, 4'd3, 4'd4, 4'd5, 4'd6, 4'd7, 4'd8, 4'd9: begin
                            rx_shifter <= {rx_pin, rx_shifter[7:1]};
                        end
                        4'd10: begin
                            // Stop Bit Sampled - End of Frame
                            rx_bit_idx <= 0; // Return to Idle
                            // Note: rx_valid is set in Main Block via 'rx_finished'
                        end
                    endcase
                end else begin
                    rx_cnt <= rx_cnt + 1;
                end
            end
        end
    end

endmodule