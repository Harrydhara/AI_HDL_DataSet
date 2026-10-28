module alarm_module (
    input wire clk_1khz,            // 1kHz Clock
    input wire reset,               // Reset the entire module
    input wire [4:0] current_hour,   // Current hour (0-23)
    input wire [5:0] current_minute, // Current minute (0-59)
    input wire btn_0,                // Select setting unit (hour, minute)
    input wire btn_1,                // Increment selected setting unit by 1
    input wire btn_2,                // Toggle alarm on/off
    output reg [4:0] alarm_hour,    // Alarm hour (0-23)
    output reg [5:0] alarm_minute,  // Alarm minute (0-59)
    output reg alarm_led             // Alarm indicator LED
);

    reg alarm_enabled;       // Alarm enabled state
    reg setting_mode;  // 0 = Hour, 1 = Minute
    reg [9:0] counter;
    reg one_hz_enable;

    // Optimized Clock divider from 1kHz to 1Hz
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

    // Reset or configure alarm settings
    always @(posedge clk_1khz or posedge reset) begin
        if (reset) begin
            alarm_hour   <= 5'd0;
            alarm_minute <= 6'd0;
            alarm_enabled <= 1'b0;
            setting_mode <= 1'b0;
        end else begin
            // Select the setting unit (Hour <-> Minute)
            if (btn_0) setting_mode <= ~setting_mode;
            
            // Increment selected setting unit
            if (btn_1) begin
                if (setting_mode)
                    alarm_hour   <= (alarm_hour == 5'd23) ? 5'd0 : alarm_hour + 1;
                else
                    alarm_minute <= (alarm_minute == 6'd59) ? 6'd0 : alarm_minute + 1;
            end
            
            // Toggle alarm on/off
            if (btn_2) alarm_enabled <= ~alarm_enabled;
        end
    end

    // Check if the current time matches the alarm time
    always @(posedge clk_1khz or posedge reset) begin
        if (reset)
            alarm_led <= 0;
        else if (one_hz_enable) 
            alarm_led <= (alarm_enabled && (current_hour == alarm_hour) && (current_minute == alarm_minute));
    end

endmodule
