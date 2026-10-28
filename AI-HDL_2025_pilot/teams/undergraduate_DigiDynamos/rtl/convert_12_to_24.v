module convert_24_to_12 (
    input wire clk,              // Clock signal
    input wire reset,            // Reset signal
    input wire [4:0] hours_24,   // Hours in 24-hour format (0-23)
    input wire [5:0] minutes_24, // Minutes in 24-hour format (0-59)
    output reg [15:0] bcd_number,// BCD number for seven-segment display
    output reg am_pm_reg         // AM/PM indication: 0 = AM, 1 = PM
);

    // Internal registers for converted time
    reg [4:0] hours_12;           // Hours in 12-hour format (1-12)
    reg [5:0] minutes;            // Minutes (unchanged from input)

    // **Main Conversion Logic**
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset all registers to their default values
            hours_12 <= 5'd0;
            minutes <= 6'd0;
            am_pm_reg <= 1'b0; // Default to AM
            bcd_number <= 16'd0;
        end else begin
            // Copy minutes directly from input
            minutes <= minutes_24;

            // Convert hours from 24-hour to 12-hour format
            if (hours_24 == 5'd0) begin
                // Special case for midnight
                hours_12 <= 5'd12;  // 12 AM
                am_pm_reg <= 1'b0;  // AM
            end else if (hours_24 < 5'd12) begin
                // Morning hours (1 AM to 11 AM)
                hours_12 <= hours_24;
                am_pm_reg <= 1'b0;  // AM
            end else if (hours_24 == 5'd12) begin
                // Special case for noon
                hours_12 <= 5'd12;  // 12 PM
                am_pm_reg <= 1'b1;  // PM
            end else begin
                // Afternoon and evening hours (1 PM to 11 PM)
                hours_12 <= hours_24 - 5'd12;
                am_pm_reg <= 1'b1;  // PM
            end

            // Format the time as a BCD number for the seven-segment display
            bcd_number[15:12] <= hours_12 / 10; // Tens place of hours
            bcd_number[11:8]  <= hours_12 % 10; // Ones place of hours
            bcd_number[7:4]   <= minutes / 10;  // Tens place of minutes
            bcd_number[3:0]   <= minutes % 10;  // Ones place of minutes
        end
    end
endmodule
