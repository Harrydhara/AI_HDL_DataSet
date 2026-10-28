module convert_12_to_24 (
    input [5:0] hours_12,    // Input hours in 12-hour format (0-12)
    input [5:0] minutes_12,  // Input minutes in 12-hour format (0-59)
    input is_pm,             // 1 for PM, 0 for AM
    output reg [5:0] hours_24, // Output hours in 24-hour format (0-23)
    output reg [5:0] minutes_24 // Output minutes in 24-hour format (0-59)
);

    // Conversion logic
    always @(*) begin
        // Pass the minutes directly
        minutes_24 = minutes_12;

        // Convert hours based on AM/PM
        if (hours_12 == 6'd12) begin
            // Special case for 12 AM and 12 PM
            if (is_pm == 1'b0) begin
                // 12 AM should convert to 00 (midnight)
                hours_24 = 6'd0;
            end else begin
                // 12 PM should stay 12 (noon)
                hours_24 = 6'd12;
            end
        end else begin
            // For all other hours, add 12 if PM
            if (is_pm == 1'b1) begin
                hours_24 = hours_12 + 6'd12;
            end else begin
                hours_24 = hours_12;
            end
        end
    end
endmodule
