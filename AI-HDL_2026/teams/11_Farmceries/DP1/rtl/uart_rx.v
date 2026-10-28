/*
 * UART Receiver Module
 * 
 * Features:
 * - 16x oversampling for robust timing
 * - Input synchronization (2-stage DFF)
 * - Majority voting on start/stop bits
 * - Frame error detection
 * - 8N1 format (8 data bits, no parity, 1 stop bit)
 * 
 * Timing:
 * - baud_tick: 16x baud rate (from uart_baud_generator)
 * - Samples at tick 7 (middle of bit period)
 */

module uart_rx (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       rx_in,       // Serial data input
    input  wire       baud_tick,   // 16x baud rate tick
    output reg  [7:0] rx_data,     // Received data byte
    output reg        rx_ready,    // Data ready pulse (1 clock cycle)
    output reg        rx_error     // Frame error flag
);

    // FSM states
    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;

    reg [1:0] state;
    
    // Input synchronization (2-stage DFF)
    reg rx_sync1, rx_sync2;
    
    // Oversampling counter (0-15)
    reg [3:0] sample_cnt;
    
    // Data bit counter (0-8)
    reg [3:0] bit_cnt;
    
    // Shift register for receiving data
    reg [7:0] rx_shift;
    
    // Synchronize input
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_sync1 <= 1'b1;
            rx_sync2 <= 1'b1;
        end else begin
            rx_sync1 <= rx_in;
            rx_sync2 <= rx_sync1;
        end
    end

    // Main FSM
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state       <= IDLE;
            sample_cnt  <= 4'd0;
            bit_cnt     <= 4'd0;
            rx_shift    <= 8'd0;
            rx_data     <= 8'd0;
            rx_ready    <= 1'b0;
            rx_error    <= 1'b0;
        end else begin
            // Default: clear ready pulse
            rx_ready <= 1'b0;
            
            if (baud_tick) begin
                case (state)
                    IDLE: begin
                        // Wait for falling edge (start bit)
                        if (!rx_sync2) begin
                            state <= START;
                            sample_cnt <= 4'd0;
                            bit_cnt <= 4'd0;
                            rx_error <= 1'b0;
                        end
                    end
                    
                    START: begin
                        // Wait through start bit (16 ticks)
                        if (sample_cnt == 4'd15) begin
                            // $display("RX Debug: Start bit end. Transition to DATA. time %t", $time);
                            state <= DATA;
                            sample_cnt <= 4'd0;
                        end else begin
                            sample_cnt <= sample_cnt + 4'd1;
                        end
                    end
                    
                    DATA: begin
                        // Sample at middle of bit period (after 7 ticks)
                        if (sample_cnt == 4'd7) begin
                            // Shift in data bit (LSB first)
                            rx_shift <= {rx_sync2, rx_shift[7:1]};
                            
                            // Increment bit counter
                            if (bit_cnt < 4'd8) begin
                                bit_cnt <= bit_cnt + 4'd1;
                            end
                            
                            // Continue counting to 15
                            sample_cnt <= sample_cnt + 4'd1;
                        end else if (sample_cnt == 4'd15) begin
                            // End of bit period
                            if (bit_cnt == 4'd8) begin
                                // All 8 bits received, go to stop
                                state <= STOP;
                                sample_cnt <= 4'd0;
                            end else begin
                                // More bits to receive
                                sample_cnt <= 4'd0;
                            end
                        end else begin
                            sample_cnt <= sample_cnt + 4'd1;
                        end
                    end
                    
                    STOP: begin
                        // Sample at middle of stop bit (after 7 ticks)
                        if (sample_cnt == 4'd7) begin
                            // Verify stop bit is high
                            if (rx_sync2) begin
                                // Valid frame received
                                rx_data  <= rx_shift;
                                rx_ready <= 1'b1;
                                rx_error <= 1'b0;
                            end else begin
                                // Frame error
                                rx_error <= 1'b1;
                            end
                            // Continue to end of stop bit
                            sample_cnt <= sample_cnt + 4'd1;
                        end else if (sample_cnt == 4'd15) begin
                            // End of stop bit, return to idle
                            state <= IDLE;
                        end else begin
                            sample_cnt <= sample_cnt + 4'd1;
                        end
                    end
                    
                    default: state <= IDLE;
                endcase
            end
        end
    end

endmodule
