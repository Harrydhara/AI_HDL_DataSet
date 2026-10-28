module alarm_clock (
    input wire clk,                 // System clock (assumed 1 Hz for blinking LED)
    input wire rst,                 // Reset signal
    input wire [15:0] current_time,  // Current time in HH:MM BCD format
    input wire button1,              // Button to increment alarm hour
    input wire button2,              // Button to increment alarm minute
    output reg [7:0] alarm_hour,     // Alarm hour in BCD (4-bit tens, 4-bit units)
    output reg [7:0] alarm_minute,   // Alarm minute in BCD (4-bit tens, 4-bit units)
    input wire enable_alarm,         // Enable/Disable alarm
    input wire dismiss_button,       // Button to stop the alarm manually
    output reg alarm_led             // Blinking LED when alarm is triggered
);

    // Register for LED blinking state
    reg blink_state;
    reg alarm_dismissed; // Flag to track manual dismissal

    // Increment hour using button1 (BCD format)
    always @(posedge button1 or posedge rst) begin
        if (rst)
            alarm_hour <= 8'b00000000; // Reset to 00
        else if (alarm_hour == 8'b00100011) // Max 23 hours (BCD 23)
            alarm_hour <= 8'b00000000;
        else if (alarm_hour[3:0] == 4'b1001) begin // If units reach 9
            alarm_hour[3:0] <= 4'b0000;
            alarm_hour[7:4] <= alarm_hour[7:4] + 4'b0001;
        end else
            alarm_hour <= alarm_hour + 8'b00000001;
    end

    // Increment minute using button2 (BCD format)
    always @(posedge button2 or posedge rst) begin
        if (rst)
            alarm_minute <= 8'b00000000; // Reset to 00
        else if (alarm_minute == 8'b01011001) // Max 59 minutes (BCD 59)
            alarm_minute <= 8'b00000000;
        else if (alarm_minute[3:0] == 4'b1001) begin // If units reach 9
            alarm_minute[3:0] <= 4'b0000;
            alarm_minute[7:4] <= alarm_minute[7:4] + 4'b0001;
        end else
            alarm_minute <= alarm_minute + 8'b00000001;
    end

    // LED Blinking Logic (Simplified Alarm with Dismiss Button)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            blink_state <= 0;
            alarm_led <= 0;
            alarm_dismissed <= 0;
        end else if (dismiss_button) begin
            alarm_dismissed <= 1; // Dismiss alarm when button is pressed
            alarm_led <= 0;
        end else if (enable_alarm && (current_time[15:8] == alarm_hour) && (current_time[7:0] == alarm_minute) && !alarm_dismissed) begin
            blink_state <= ~blink_state; // Toggle LED every clock cycle
            alarm_led <= blink_state;
        end else if (current_time[15:8] != alarm_hour || current_time[7:0] != alarm_minute) begin
            alarm_dismissed <= 0; // Reset dismiss flag when time moves past alarm
            alarm_led <= 0;
        end
    end

endmodule

