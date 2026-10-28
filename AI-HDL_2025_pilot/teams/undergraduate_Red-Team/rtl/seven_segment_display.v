`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/17/2024 08:12:47 PM
// Design Name: 
// Module Name: seven_segment_display
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


// Seven Segment Display Module for Basys 3

module seven_segment_display(
    input wire clk,            // Input clock (slow clock for multiplexing)
    input wire reset,          // Active-high reset
    input wire [15:0] data,    // 4-digit hexadecimal input data
    output reg [6:0] seg,      // Seven-segment output (a to g)
    output reg [3:0] an        // Anode control for 4 digits
);

    // Digit selection counter
    reg [1:0] digit_select;

    // Current digit value
    reg [3:0] current_digit;

    // Seven-segment encoding
    always @(*) begin
        case (current_digit)
            4'h0: seg = 7'b1000000; // 0
            4'h1: seg = 7'b1111001; // 1
            4'h2: seg = 7'b0100100; // 2
            4'h3: seg = 7'b0110000; // 3
            4'h4: seg = 7'b0011001; // 4
            4'h5: seg = 7'b0010010; // 5
            4'h6: seg = 7'b0000010; // 6
            4'h7: seg = 7'b1111000; // 7
            4'h8: seg = 7'b0000000; // 8
            4'h9: seg = 7'b0010000; // 9
            4'hA: seg = 7'b0001000; // A
            4'hB: seg = 7'b0000011; // B
            4'hC: seg = 7'b1000110; // C
            4'hD: seg = 7'b0100001; // D
            4'hE: seg = 7'b0000110; // E
            4'hF: seg = 7'b0001110; // F
            default: seg = 7'b1111111; // Blank
        endcase
    end

    // Anode control logic
    always @(*) begin
        case (digit_select)
            2'b00: an = 4'b1110; // Enable digit 0
            2'b01: an = 4'b1101; // Enable digit 1
            2'b10: an = 4'b1011; // Enable digit 2
            2'b11: an = 4'b0111; // Enable digit 3
            default: an = 4'b1111; // All off
        endcase
    end

    // Multiplexing logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            digit_select <= 2'b00;
        end else begin
            digit_select <= digit_select + 1;
        end
    end

    // Current digit selection
    always @(*) begin
        case (digit_select)
            2'b00: current_digit = data[3:0];    // Digit 0
            2'b01: current_digit = data[7:4];    // Digit 1
            2'b10: current_digit = data[11:8];   // Digit 2
            2'b11: current_digit = data[15:12];  // Digit 3
            default: current_digit = 4'b0000;
        endcase
    end

endmodule
