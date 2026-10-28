// timezone_adjust.v - Adjust hours for selected time zone
module timezone_adjust(
    input  wire [4:0] base_hours,   // base time hours (0-23)
    input  wire [1:0] zone_select,  // select code for time zone
    output reg  [4:0] tz_hours      // adjusted hours (0-23)
);
    // Define hour offsets for each zone select code
    // Using blocking assign in always for combinational logic
    always @(*) begin
        case(zone_select)
            2'b00: tz_hours = base_hours + 5'd0;   // No offset (local or base zone)
            2'b01: tz_hours = base_hours + 5'd1;   // Zone1: +1 hour
            2'b10: tz_hours = base_hours + 5'd23;  // Zone2: -1 hour (add 23 mod 24)
            2'b11: tz_hours = base_hours + 5'd5;   // Zone3: +5 hours
        endcase
        // Wrap around to 0-23 range (mod 24)
        if (tz_hours >= 24)
            tz_hours = tz_hours - 5'd24;
    end
endmodule
