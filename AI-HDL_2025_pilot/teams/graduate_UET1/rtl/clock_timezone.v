module digital_clock (
    input wire clk_1khz,           // 1kHz Clock
    input wire reset,              // Reset the entire module
    input wire set_time,           // Signal to set time
    input wire [4:0] set_hour,     // Set hour input (0-23)
    input wire [5:0] set_min,      // Set minute input (0-59)
    input wire [3:0] tz_select,    // Select timezone
    output reg [4:0] hours,        // UTC hour output
    output reg [5:0] minutes,      // Minute output
    output reg [4:0] tz_hours      // Adjusted hour for selected timezone
);
    reg [5:0] seconds;
    reg [9:0] counter = 0;         // Counter for 1Hz enable signal from 1kHz
    reg one_hz_enable = 0;         // 1Hz clock enable signal
    
    // Use LUT-based timezone offsets for area efficiency
    reg signed [5:0] timezone_offsets [0:9];

    initial begin
        timezone_offsets[0] = 0;
        timezone_offsets[1] = -8;
        timezone_offsets[2] = -12;
        timezone_offsets[3] = 1;
        timezone_offsets[4] = 5;
        timezone_offsets[5] = 7;
        timezone_offsets[6] = 8;
        timezone_offsets[7] = 9;
        timezone_offsets[8] = 12;
        timezone_offsets[9] = -5;
    end
    
    // Clock divider from 1kHz to 1Hz with clock gating for power efficiency
    always @(posedge clk_1khz or posedge reset) begin
        if (reset) begin
            counter <= 0;
            one_hz_enable <= 0;
        end else if (counter == 999) begin
            counter <= 0;
            one_hz_enable <= 1; // Enable every second
        end else begin
            counter <= counter + 1;
            one_hz_enable <= 0;
        end
    end

    // Timekeeping logic (HH:MM:SS) with optimized clock enable signal
    always @(posedge clk_1khz or posedge reset) begin
        if (reset) begin
            hours   <= 5'd0;
            minutes <= 6'd0;
            seconds <= 0;
        end else if (set_time) begin
            hours   <= set_hour;
            minutes <= set_min;
        end else if (one_hz_enable) begin
            if (seconds == 6'd59) begin
                seconds <= 0;
                if (minutes == 6'd59) begin
                    minutes <= 0;
                    hours <= (hours == 5'd23) ? 0 : hours + 1;
                end else begin
                    minutes <= minutes + 1;
                end
            end else begin
                seconds <= seconds + 1;
            end
        end
    end

    // Adjust the hour based on the selected timezone
    always @(*) begin
        if (tz_select < 10) begin
            tz_hours = (hours + timezone_offsets[tz_select]) % 24;
            if (tz_hours < 0) tz_hours = tz_hours + 24;
        end else begin
            tz_hours = hours; // Default case for safety
        end
    end

endmodule
