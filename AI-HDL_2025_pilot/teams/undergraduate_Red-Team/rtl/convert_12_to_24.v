`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/05/2025 09:47:56 PM
// Design Name: 
// Module Name: convert_12_to_24
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


// Module to Convert 12-hour Clock Signal to 24-hour Format

module convert_12_to_24(
    input wire [5:0] hh_12,      // Input hours in 12-hour format (1-12)
    input wire [5:0] mm_12,      // Input minutes (0-59)
    input wire is_pm,            // AM/PM signal (0 for AM, 1 for PM)
    output reg [5:0] hh_24,      // Output hours in 24-hour format (0-23)
    output reg [5:0] mm_24       // Output minutes (unchanged, 0-59)
);

    always @(*) begin
        // Transfer minutes directly
        mm_24 = mm_12;

        // Convert hours to 24-hour format
        if (is_pm) begin
            // PM case
            if (hh_12 == 6'd12) begin
                // 12 PM remains 12 in 24-hour format
                hh_24 = 6'd12;
            end else begin
                // Add 12 to PM hours
                hh_24 = hh_12 + 6'd12;
            end
        end else begin
            // AM case
            if (hh_12 == 6'd12) begin
                // 12 AM is 0 in 24-hour format
                hh_24 = 6'd0;
            end else begin
                // Hours remain unchanged for other AM times
                hh_24 = hh_12;
            end
        end
    end

endmodule

