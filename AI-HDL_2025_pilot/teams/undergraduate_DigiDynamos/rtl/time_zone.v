module time_zone (
    input wire clk,              // Clock signal
    input wire reset,            // Reset signal
    input wire button_tz1,       // Button to select time zone -1 (UTC-1)
    input wire button_tz2,       // Button to select time zone +2 (UTC+2)
    input wire button_tz3,       // Button to select time zone +3 (UTC+3)
    input wire [4:0] current_hours, // Current hours from digital_clock (0-23)
    input wire [5:0] current_minutes, // Current minutes from digital_clock (0-59)
    output reg [15:0] bcd_number // BCD number for seven-segment display
);

    // **Internal Registers**
    reg signed [5:0] tz_offset;     // Time zone offset in hours (-12 to +12, signed to handle negatives)
    reg [4:0] adjusted_hours;      // Adjusted hours after applying time zone offset
    reg [5:0] adjusted_minutes;    // Minutes remain unchanged

    // **Time Zone Offset Selection Logic**
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            tz_offset <= 0; // Default to no offset (UTC+0)
        end else begin
            // Update the offset based on button presses
            if (button_tz1) begin
                tz_offset <= -1; // UTC-1
            end else if (button_tz2) begin
                tz_offset <= 2;  // UTC+2
            end else if (button_tz3) begin
                tz_offset <= 3;  // UTC+3
            end
        end
    end

    // **Time Adjustment and BCD Display Update**
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            bcd_number <= 16'd0; // Reset the BCD display
        end else begin
            // **Adjust Hours Based on the Time Zone Offset**
            adjusted_hours = current_hours + tz_offset;

            // Wrap around to keep `adjusted_hours` within 0-23
            if (adjusted_hours < 0) begin
                adjusted_hours = adjusted_hours + 24; // Wrap around backward
            end else if (adjusted_hours >= 24) begin
                adjusted_hours = adjusted_hours - 24; // Wrap around forward
            end

            // **Minutes remain unchanged**
            adjusted_minutes = current_minutes;

            // **Update the BCD Number for Seven-Segment Display**
            bcd_number[15:12] <= adjusted_hours / 10; // Tens place of hours
            bcd_number[11:8]  <= adjusted_hours % 10; // Ones place of hours
            bcd_number[7:4]   <= adjusted_minutes / 10; // Tens place of minutes
            bcd_number[3:0]   <= adjusted_minutes % 10; // Ones place of minutes
        end
    end
endmodule
