module digital_clock (
    input wire clk,             // System clock (e.g., 50 MHz)
    input wire reset,           // Asynchronous reset
    input wire set_time,        // Signal to set a new time
    input wire [5:0] set_hours, // Input hours (0-23)
    input wire [5:0] set_minutes, // Input minutes (0-59)
    input wire [5:0] set_seconds, // Input seconds (0-59)
    input wire [3:0] time_zone_select, // Time zone selection signal (4-bit)
    output reg [5:0] display_hours, // Output hours adjusted for time zone
    output reg [5:0] display_minutes, // Output minutes
    output reg [5:0] display_seconds // Output seconds
);

    reg [5:0] hours, minutes, seconds;
    reg [31:0] counter;
    reg clk_1hz;
    reg signed [5:0] time_zone_offset; // Time zone offset in hours

    // Time Zone Lookup Table (Offset in Hours)
    always @(*) begin
        case (time_zone_select)
            4'd0: time_zone_offset = 0;   // UTC
            4'd1: time_zone_offset = -5;  // EST (Eastern Standard Time, UTC-5)
            4'd2: time_zone_offset = -8;  // PST (Pacific Standard Time, UTC-8)
            4'd3: time_zone_offset = 1;   // CET (Central European Time, UTC+1)
            4'd4: time_zone_offset = 5;   // IST (Indian Standard Time, UTC+5)
            4'd5: time_zone_offset = 9;   // JST (Japan Standard Time, UTC+9)
            4'd6: time_zone_offset = 10;  // AEST (Australia Eastern Standard Time, UTC+10)
            4'd7: time_zone_offset = -3;  // BRT (Brazil Time, UTC-3)
            default: time_zone_offset = 0; // Default to UTC
        endcase
    end

    // Clock Divider to Generate 1 Hz Clock
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            counter <= 0;
            clk_1hz <= 0;
        end else if (counter >= 50000000 - 1) begin
            counter <= 0;
            clk_1hz <= ~clk_1hz; // Toggle the 1 Hz clock
        end else begin
            counter <= counter + 1;
        end
    end

    // Main Clock Logic
    always @(posedge clk_1hz or posedge reset) begin
        if (reset) begin
            hours <= 0;
            minutes <= 0;
            seconds <= 0;
        end else if (set_time) begin
            // Set time manually
            hours <= set_hours;
            minutes <= set_minutes;
            seconds <= set_seconds;
        end else begin
            // Increment time
            if (seconds < 59) begin
                seconds <= seconds + 1;
            end else begin
                seconds <= 0;
                if (minutes < 59) begin
                    minutes <= minutes + 1;
                end else begin
                    minutes <= 0;
                    if (hours < 23) begin
                        hours <= hours + 1;
                    end else begin
                        hours <= 0;
                    end
                end
            end
        end
    end

    // Time Zone Adjustment
    always @(*) begin
        reg signed [6:0] temp_hours; // Temporary storage for hour adjustments
        temp_hours = hours + time_zone_offset;

        if (temp_hours < 0) begin
            display_hours = temp_hours + 24; // Wrap around for negative values
        end else if (temp_hours > 23) begin
            display_hours = temp_hours - 24; // Wrap around for values > 23
        end else begin
            display_hours = temp_hours;
        end

        display_minutes = minutes;
        display_seconds = seconds;
    end

endmodule
