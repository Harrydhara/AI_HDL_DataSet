`default_nettype none

/**
 * UART Baud Rate Generator
 * 
 * Generates baud rate tick pulses from system clock.
 * Uses lookup table to select divisor based on baud_sel input.
 * 
 * Clock: 70 MHz (TinyQV system clock)
 * Supported baud rates: 9600, 19200, 38400, 115200
 * 
 * OUTPUT: 16x oversampling clock (16 ticks per bit period)
 * 
 * How it works:
 * - Counter counts from 0 to divisor-1
 * - When counter reaches divisor-1, output 1-cycle pulse and reset
 * - Divisor = CLK_FREQ / (BAUD_RATE * 16)
 * 
 * Example for 9600 baud:
 *   divisor = 70,000,000 / (9600 * 16) = 455.73 ≈ 456
 *   Tick pulse every 456 clock cycles = 153.6 kHz (16x 9600 Hz)
 */
module uart_baud_generator (
    input  wire       clk,          // System clock (70 MHz)
    input  wire       rst_n,        // Active-low reset
    input  wire [3:0] baud_sel,     // Baud rate selection
    input  wire       enable,       // Enable signal (1=run, 0=stop)
    output wire       baud_tick     // 1-cycle pulse at baud rate
);

    // Baud rate lookup table (16x oversampling)
    // baud_sel encoding:
    // 4'h0 = 9600 baud
    // 4'h1 = 19200 baud
    // 4'h2 = 38400 baud  
    // 4'hC = 115200 baud (matches CTRL register encoding)
    localparam [15:0] DIVISOR_9600   = 16'd456;   // 70MHz / (9600 * 16) ≈ 455.73
    localparam [15:0] DIVISOR_19200  = 16'd228;   // 70MHz / (19200 * 16) ≈ 227.86
    localparam [15:0] DIVISOR_38400  = 16'd114;   // 70MHz / (38400 * 16) ≈ 113.93
    localparam [15:0] DIVISOR_115200 = 16'd38;    // 70MHz / (115200 * 16) ≈ 37.98

    // Current divisor value (from lookup table)
    reg [15:0] divisor;
    
    // Counter - counts from 0 to divisor-1
    reg [15:0] counter;
    
    // Lookup divisor based on baud_sel
    always @(*) begin
        case (baud_sel)
            4'h0:    divisor = DIVISOR_9600;
            4'h1:    divisor = DIVISOR_19200;
            4'h2:    divisor = DIVISOR_38400;
            4'hC:    divisor = DIVISOR_115200;
            default: divisor = DIVISOR_9600;  // Default to 9600
        endcase
    end
    
    // Counter logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 16'h0000;
        end else if (enable) begin
            if (counter >= divisor - 1) begin
                counter <= 16'h0000;  // Reset counter
            end else begin
                counter <= counter + 1;
            end
        end else begin
            counter <= 16'h0000;  // Reset when disabled
        end
    end
    
    // Generate tick pulse when counter reaches divisor-1
    assign baud_tick = enable && (counter == divisor - 1);

endmodule

`default_nettype wire
