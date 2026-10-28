`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/17/2024 08:12:17 PM
// Design Name: 
// Module Name: buttonDebouncer
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


// Button Debouncer Module

module buttonDebouncer(
    input wire clk,         // Input clock (slow clock from clock divider)
    input wire reset,       // Active-high reset
    input wire button_in,   // Raw button input
    output reg button_out   // Debounced button output
);

    // State tracking registers
    reg [2:0] shift_reg;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            shift_reg <= 3'b000;
            button_out <= 0;
        end else begin
            // Shift in the new button state
            shift_reg <= {shift_reg[1:0], button_in};

            // Update the debounced output if all shift register values are the same
            if (shift_reg == 3'b111) begin
                button_out <= 1;
            end else if (shift_reg == 3'b000) begin
                button_out <= 0;
            end
        end
    end

endmodule