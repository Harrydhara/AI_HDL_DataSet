`timescale 1ns / 1ps

module sevseg(
    // Input signals
    input [5:0] binary_hours,     // Binary input for hours (0-23)
    input [5:0] binary_minutes,   // Binary input for minutes (0-59)
    input clk_1kHz,               // 1 kHz clock for digit multiplexing
    input rst,                    // Active-high reset
    input wire manual_update,     // Fresh Triggers immediate display update on button press  
    input wire long_press_active, //Fresh sets up for synch of long press with anode mux 
      
    // Output signals
    output reg [6:0] seg,         // Active-low segment control
    output reg [3:0] an,          // Active-low digit enable

    // Debug outputs for simulation or verification
    output reg [3:0] hours_tens,
    output reg [3:0] hours_ones,
    output reg [3:0] minutes_tens,
    output reg [3:0] minutes_ones,
    output reg [3:0] active_digit,
    output reg [1:0] current_digit,
    output reg [4:0] clk_div,
    output reg enable_50Hz
);


    //Fresh Binary to BCD for the flicker free display
    always @(posedge clk_1kHz or posedge rst) begin
        if (rst) begin
            hours_tens <= 0;
            hours_ones <= 0;
            minutes_tens <= 0;
            minutes_ones <= 0;
        end else if ((manual_update || long_press_active) && current_digit == 2'b11) begin
            // ✅ Apply updates one cycle before reaching digit 0
            hours_tens <= binary_hours / 10;
            hours_ones <= binary_hours % 10;
            minutes_tens <= binary_minutes / 10;
            minutes_ones <= binary_minutes % 10;
        end else if (enable_50Hz) begin
            hours_tens <= binary_hours / 10;
            hours_ones <= binary_hours % 10;
            minutes_tens <= binary_minutes / 10;
            minutes_ones <= binary_minutes % 10;
        end
    end

    // Function to decode BCD to 7-segment display pattern
    function [6:0] decode_digit;
        input [3:0] bcd;
        case (bcd)
            4'b0000: decode_digit = 7'b1000000; // 0
            4'b0001: decode_digit = 7'b1111001; // 1
            4'b0010: decode_digit = 7'b0100100; // 2
            4'b0011: decode_digit = 7'b0110000; // 3
            4'b0100: decode_digit = 7'b0011001; // 4
            4'b0101: decode_digit = 7'b0010010; // 5
            4'b0110: decode_digit = 7'b0000010; // 6
            4'b0111: decode_digit = 7'b1111000; // 7
            4'b1000: decode_digit = 7'b0000000; // 8
            4'b1001: decode_digit = 7'b0010000; // 9
            default: decode_digit = 7'b1111111; // Blank or invalid input
        endcase
    endfunction

    // Generate 50 Hz enable signal from 1 kHz clock
    always @(posedge clk_1kHz or posedge rst) begin
        if (rst) begin
            clk_div <= 0;              // Reset counter
            enable_50Hz <= 0;          // Reset enable signal
        end else if (clk_div == 19) begin // Count up to 19 for 50 Hz at 1 kHz (20 counts for one 50 Hz cycle)
            clk_div <= 0;
            enable_50Hz <= 1;          // Enable high for one clock cycle every 20 cycles
        end else begin
            clk_div <= clk_div + 1;     // Increment counter
            enable_50Hz <= 0;          // Keep enable low otherwise
        end
    end

    // Digit selection logic for time-division multiplexing
    always @(posedge clk_1kHz or posedge rst) begin
        if (rst) begin
            current_digit <= 2'b00;    // Reset to first digit upon reset
        end else if (enable_50Hz) begin
            current_digit <= current_digit + 1;  // Cycle through digits at 50 Hz
        end
    end

    // Enable the correct digit based on current_digit
    always @(*) begin
        case (current_digit)
            2'b00: an = 4'b1110; // Enable digit 0 (LSB of minutes)
            2'b01: an = 4'b1101; // Enable digit 1 (MSB of minutes)
            2'b10: an = 4'b1011; // Enable digit 2 (LSB of hours)
            2'b11: an = 4'b0111; // Enable digit 3 (MSB of hours)
            default: an = 4'b1111; // All digits off if unexpected value (shouldn't occur)
        endcase
    end

    // Determine which BCD digit to display based on current_digit
    always @(*) begin
        case (current_digit)
            2'b00: active_digit = minutes_ones;   // Display least significant digit of minutes
            2'b01: active_digit = minutes_tens;   // Display most significant digit of minutes
            2'b10: active_digit = hours_ones;     // Display least significant digit of hours
            2'b11: active_digit = hours_tens;     // Display most significant digit of hours
            default: active_digit = 4'b0000;      // Default to 0 if unexpected value
        endcase
    end

    // Decode the active BCD digit to corresponding 7-segment display pattern
    always @(*) begin
        seg = decode_digit(active_digit);
    end

endmodule