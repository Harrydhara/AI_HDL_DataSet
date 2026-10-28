module convert_12_to_24 (
    input wire [4:0] hour_12,    // 12-hour format hour (1-12)
    input wire [5:0] minute_12,  // Minutes (0-59)
    input wire am_pm,            // 0 = AM, 1 = PM
    output reg [4:0] hour_24,    // 24-hour format hour (0-23)
    output reg [5:0] minute_24   // Minutes remain the same
);

    always @(*) begin
        // Preserve minutes
        minute_24 = minute_12;

        // Optimized AM/PM conversion using ternary operators
        hour_24 = (hour_12 == 5'd12) ? (am_pm ? 5'd12 : 5'd0) : (am_pm ? hour_12 + 5'd12 : hour_12);
    end

endmodule