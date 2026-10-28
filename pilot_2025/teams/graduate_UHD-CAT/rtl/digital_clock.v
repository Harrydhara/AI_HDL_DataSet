module digital_clock (
    input wire clk_div,                // 1 Hz clock signal 
    input wire reset,                  // Reset signal
    input wire set_time_enable,        // Enable for setting time
    input wire [5:0] set_hours,        // Input for setting hours (0-23)
    input wire [5:0] set_minutes,      // Input for setting minutes (0-59)
    input wire [5:0] set_seconds,      // Input for setting seconds (0-59)
    input wire [4:0] timezone_select,  // Timezone selection (index-based)
    output reg [5:0] hours,            // Current hour output (0-23)
    output reg [5:0] minutes,          // Current minute output (0-59)
    output reg [5:0] seconds,          // Current second output (0-59)
    output reg [5:0] adjusted_hours,    // Adjusted hour output based on timezone
    output reg is_pm                    // Indicates PM (1 for PM, 0 for AM)
);

    // Function to get timezone offset based on selection
    function integer get_timezone_offset;
        input [4:0] tz_select;
        begin
            case (tz_select)
                5'd0:  get_timezone_offset = 0;    // UTC
                5'd1:  get_timezone_offset = 1;    // GMT+1
                5'd2:  get_timezone_offset = 2;    // GMT+2
                5'd3:  get_timezone_offset = 3;    // GMT+3
                5'd4:  get_timezone_offset = 4;    // GMT+4
                5'd5:  get_timezone_offset = 5;    // GMT+5
                5'd6:  get_timezone_offset = 6;    // GMT+6
                5'd7:  get_timezone_offset = 7;    // GMT+7
                5'd8:  get_timezone_offset = 8;    // GMT+8
                5'd9:  get_timezone_offset = 9;    // GMT+9
                5'd10: get_timezone_offset = 10;   // GMT+10
                5'd11: get_timezone_offset = 11;   // GMT+11
                5'd12: get_timezone_offset = 12;   // GMT+12
                5'd13: get_timezone_offset = -1;   // GMT-1
                5'd14: get_timezone_offset = -2;   // GMT-2
                5'd15: get_timezone_offset = -3;   // GMT-3
                default: get_timezone_offset = 0;  // Default to UTC
            endcase
        end
    endfunction

    // Wire to hold the timezone offset
    wire signed [5:0] timezone_offset;
    assign timezone_offset = get_timezone_offset(timezone_select);
    
    reg set_time_sync;
    always @(posedge clk_div) begin
        set_time_sync <= set_time_enable;
    end
    
    // Main Clocking Logic
    always @(posedge clk_div or posedge reset) begin 
        if (reset) begin
            // Reset time to zero
            hours <= 6'd0;
            minutes <= 6'd0;
            seconds <= 6'd0;
        end else if (set_time_enable) begin
            // Set time when enabled
            hours <= set_hours;
            minutes <= set_minutes;
            seconds <= set_seconds;
        end else begin
            // Increment time
            seconds <= seconds + 6'd1;
    
            // Handle seconds overflow
            if (seconds >= 6'd59) begin
                seconds <= 6'd0;
                minutes <= minutes + 6'd1;
    
                // Handle minutes overflow
                if (minutes >= 6'd59) begin
                    minutes <= 6'd0;
                    hours <= hours + 6'd1;
    
                    // Handle hours overflow
                    if (hours >= 6'd23) begin
                        hours <= 6'd0;
                    end
                end
            end
        end
    end
    
    // Adjust hours to 12-hour format and determine AM/PM
    always @(*) begin
        // Adjust hours for timezone
        adjusted_hours = (hours + timezone_offset) % 24; 
        if (adjusted_hours < 0) begin
            adjusted_hours = adjusted_hours + 24; 
        end
    
        // Convert to 12-hour format
        if (adjusted_hours == 0) begin
            adjusted_hours = 6'd12;   // Midnight
            is_pm = 1'b0;
        end else if (adjusted_hours < 12) begin
            is_pm = 1'b0;             // AM
        end else if (adjusted_hours == 12) begin
            is_pm = 1'b1;             // Noon
        end else begin
            adjusted_hours = adjusted_hours - 12; // PM hours
            is_pm = 1'b1;
        end
    end
        
endmodule
