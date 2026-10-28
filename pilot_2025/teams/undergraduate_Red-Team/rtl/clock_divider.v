`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/17/2024 08:08:30 PM
// Design Name: 
// Module Name: clock_divider
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


// Clock Divider Module for Basys 3

module clock_divider #(
    parameter DIV_FACTOR = 1000000 // Default division factor (e.g., 1 kHz from 100 MHz)
)(
    input wire clk_in,    // Input clock (100 MHz)
    input wire reset,     // Active-high reset
    output reg clk_out    // Output divided clock
);

    // Calculate the maximum count value based on the division factor
    localparam MAX_COUNT = DIV_FACTOR / 2 - 1;

    // Counter for clock division
    reg [$clog2(MAX_COUNT):0] counter;

    always @(posedge clk_in or posedge reset) begin
        if (reset) begin
            counter <= 0;
            clk_out <= 0;
        end else if (counter == MAX_COUNT) begin
            counter <= 0;
            clk_out <= ~clk_out; // Toggle the output clock
        end else begin
            counter <= counter + 1;
        end
    end

endmodule