`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/05/2025 09:40:49 PM
// Design Name: 
// Module Name: clock_timezone
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


// Digital Clock Module with Timezone Support in Verilog

module clock_timezone(
    input wire clk,                // Clock signal
    input wire reset,              // Reset signal
    input wire set,                // Set signal
    input wire [5:0] set_hh,       // Hours to set (0-23)
    input wire [5:0] set_mm,       // Minutes to set (0-59)
    input wire [5:0] set_ss,       // Seconds to set (0-59)
    input wire [2:0] tz_select,    // Timezone select signal (3-bit for up to 8 timezones)
    output reg [5:0] hh,           // Current hours (adjusted for timezone)
    output reg [5:0] mm,           // Current minutes
    output reg [5:0] ss            // Current seconds
);

    reg [31:0] counter;           // Counter to divide the clock signal
    parameter CLK_FREQ = 100000000; // Assume 100 MHz clock frequency
    parameter ONE_SEC = CLK_FREQ;   // Number of clock cycles in one second

    // Hardcoded timezone offsets in hours (can be negative or positive)
    wire signed [4:0] timezone_offsets [0:7];
    assign timezone_offsets[0] = 0;   // UTC
    assign timezone_offsets[1] = -5;  // EST
    assign timezone_offsets[2] = -8;  // PST
    assign timezone_offsets[3] = 1;   // CET
    assign timezone_offsets[4] = 5;   // IST
    assign timezone_offsets[5] = 9;   // JST
    assign timezone_offsets[6] = -3;  // BRT
    assign timezone_offsets[7] = 11;  // AEDT

    reg signed [5:0] adjusted_hh;     // Temporary register for adjusted hours

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset the clock to 00:00:00
            hh <= 6'b0;
            mm <= 6'b0;
            ss <= 6'b0;
            counter <= 32'b0;
        end else if (set) begin
            // Set the clock to the specified time
            hh <= set_hh;
            mm <= set_mm;
            ss <= set_ss;
            counter <= 32'b0;
        end else begin
            // Increment the counter and update the clock
            if (counter == ONE_SEC - 1) begin
                counter <= 32'b0;

                // Increment seconds
                if (ss == 59) begin
                    ss <= 6'b0;

                    // Increment minutes
                    if (mm == 59) begin
                        mm <= 6'b0;

                        // Increment hours
                        if (hh == 23) begin
                            hh <= 6'b0;
                        end else begin
                            hh <= hh + 1;
                        end
                    end else begin
                        mm <= mm + 1;
                    end
                end else begin
                    ss <= ss + 1;
                end

            end else begin
                counter <= counter + 1;
            end
        end
    end

    // Adjust hours based on timezone offset
    always @(*) begin
        adjusted_hh = hh + timezone_offsets[tz_select];

        // Handle overflow and underflow for 24-hour format
        if (adjusted_hh >= 24) begin
            adjusted_hh = adjusted_hh - 24;
        end else if (adjusted_hh < 0) begin
            adjusted_hh = adjusted_hh + 24;
        end

        // Output the adjusted hours
        hh = adjusted_hh;
    end

endmodule

