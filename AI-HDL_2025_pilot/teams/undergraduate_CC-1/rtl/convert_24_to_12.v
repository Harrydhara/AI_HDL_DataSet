`timescale 1ns / 1ps

module convert_24_to_12(
    input wire [5:0] hours_24,      // 24-hour format hours (0-23)
    input wire [5:0] minutes_24,    // 24-hour format minutes (0-59)
    input wire mode_12hr_select,    // Mode select: 1 for 12-hour mode, 0 for 24-hour mode
    output reg [5:0] hours_12,      // 12-hour format hours (1-12)
    output reg [5:0] minutes_12,    // 12-hour format minutes (0-59)
    output reg am_pm,               // AM/PM indicator: 0 for AM, 1 for PM routed to sevseg for LED
    output reg [5:0] buffer_hours,  // Buffered hours routed to other modules
    output reg [5:0] buffer_minutes,// Buffered minutes routed to other modules
    output reg am_pm_mode           // AM/PM signal routed to alarm module
);

    always @(*) begin
        if (mode_12hr_select) begin
            // Convert 24-hour format to 12-hour format
            minutes_12 = minutes_24; // Minutes remain the same

            // Determine AM/PM and convert hours
            if (hours_24 == 6'd0) begin
                // Midnight case
                hours_12 = 6'd12; // 12:00 AM
                am_pm = 1'b0;    // AM
            end else if (hours_24 == 6'd12) begin
                // Noon case
                hours_12 = 6'd12; // 12:00 PM
                am_pm = 1'b1;    // PM
            end else if (hours_24 > 6'd12) begin
                // PM case
                hours_12 = hours_24 - 6'd12;
                am_pm = 1'b1;    // PM
            end else begin
                // AM case
                hours_12 = hours_24;
                am_pm = 1'b0;    // AM
            end

            // Buffer the converted outputs for other modules
            buffer_hours = hours_12;
            buffer_minutes = minutes_12;
            am_pm_mode = am_pm; // Pass AM/PM signal to alarm module
        end else begin
            // 24-hour mode: Pass through original values
            hours_12 = hours_24;  
            minutes_12 = minutes_24;
            buffer_hours = hours_24;
            buffer_minutes = minutes_24;
            am_pm = 1'b0;        // Not used in 24-hour mode
            am_pm_mode = 1'b0;   // Not used in 24-hour mode
        end
    end
endmodule
