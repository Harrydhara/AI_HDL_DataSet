`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/05/2025 09:50:47 PM
// Design Name: 
// Module Name: alarm
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


// Alarm Module for Digital Watch

module alarm(
    input wire clk,                // Main clock signal
    input wire reset,              // Reset signal
    input wire [5:0] current_hh,   // Current hours signal (0-23)
    input wire [5:0] current_mm,   // Current minutes signal (0-59)
    input wire [5:0] current_ss,   // Current seconds signal (0-59)
    input wire btn_inc_hh,         // Button to increment alarm hours
    input wire btn_inc_mm,         // Button to increment alarm minutes
    input wire btn_inc_ss,         // Button to increment alarm seconds
    input wire alarm_enable,       // Enable/disable alarm signal
    output reg alarm_active,       // Output to indicate alarm is active
    output reg alarm_led           // Output signal to blink an LED when alarm is active
);

    // Registers to store the alarm time
    reg [5:0] alarm_hh;
    reg [5:0] alarm_mm;
    reg [5:0] alarm_ss;

    // Blinking logic counter
    reg [23:0] blink_counter;
    parameter BLINK_THRESHOLD = 10000000; // Adjust for LED blink speed

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset alarm time and outputs
            alarm_hh <= 6'b0;
            alarm_mm <= 6'b0;
            alarm_ss <= 6'b0;
            alarm_active <= 1'b0;
            alarm_led <= 1'b0;
            blink_counter <= 24'b0;
        end else begin
            // Handle alarm time adjustments using buttons
            if (btn_inc_hh) begin
                if (alarm_hh == 23)
                    alarm_hh <= 6'b0;
                else
                    alarm_hh <= alarm_hh + 1;
            end

            if (btn_inc_mm) begin
                if (alarm_mm == 59)
                    alarm_mm <= 6'b0;
                else
                    alarm_mm <= alarm_mm + 1;
            end

            if (btn_inc_ss) begin
                if (alarm_ss == 59)
                    alarm_ss <= 6'b0;
                else
                    alarm_ss <= alarm_ss + 1;
            end

            // Check if current time matches the alarm time
            if (alarm_enable && current_hh == alarm_hh && current_mm == alarm_mm && current_ss == alarm_ss) begin
                alarm_active <= 1'b1;
            end else if (!alarm_enable) begin
                alarm_active <= 1'b0;
            end

            // Blink LED if alarm is active
            if (alarm_active) begin
                blink_counter <= blink_counter + 1;
                if (blink_counter >= BLINK_THRESHOLD) begin
                    blink_counter <= 24'b0;
                    alarm_led <= ~alarm_led;
                end
            end else begin
                alarm_led <= 1'b0;
                blink_counter <= 24'b0;
            end
        end
    end

endmodule

