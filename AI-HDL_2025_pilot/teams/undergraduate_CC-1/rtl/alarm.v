`timescale 1ns / 1ps

module alarm(
    input wire clk_1kHz,            // 1 kHz clock signal from clock_divider.v module
    input wire rst,                 // Active-high rst signal
    input wire set_hour,            // Debounced BTN_L for setting alarm hour
    input wire set_minute,          // Debounced BTN_R for setting alarm minute
    input wire toggle_alarm,        // Button or switch to enable/disable the alarm
    input wire debounced_BTN_D,     // Debounced button to toggle enable_set_alarm_latch
    input wire state_mode_enable_alarm, // Signal from state machine to enable alarm set mode
    input wire [5:0] current_hour,  // Current hour from the digital clock
    input wire [5:0] current_minute,// Current minute from the digital clock
    output reg alarm_trigger,       // Signal to indicate alarm is active
    output reg alarm_latch,         // Latched signal to indicate alarm state
    output reg [5:0] alarm_hour,    // Alarm hour setting
    output reg [5:0] alarm_minute,  // Alarm minute setting
    //input wire am_pm_mode,          // AM/PM indicator from convert_24_to_12 intended for alarm
    input wire [1:0] current_digit, // ✅ New input for synchronization
    output reg long_press_active_alarm // Changed from long_press_active
);

    reg alarm_enabled;              // Flag indicating if the alarm is enabled
    reg enable_set_alarm_latch;     // Latch to toggle enable_set_alarm functionality
    reg prev_BTN_D;                 // Previous state of debounced_BTN_D for edge detection
    reg [15:0] hold_counter_hour;   // Counter for hour button hold duration
    reg [15:0] hold_counter_minute; // Counter for minute button hold duration

    always @(posedge clk_1kHz or posedge rst) begin
        if (rst) begin
            // Reset all values to defaults
            alarm_hour <= 6'd0;
            alarm_minute <= 6'd0;
            alarm_enabled <= 1'b0;
            enable_set_alarm_latch <= 1'b0;
            prev_BTN_D <= 1'b0;
            long_press_active_alarm <= 1'b0;  // Initialize here in the reset block
            hold_counter_hour <= 16'd0;
            hold_counter_minute <= 16'd0;
        end else begin
            if (state_mode_enable_alarm) begin
                if (debounced_BTN_D && !prev_BTN_D) begin
                    enable_set_alarm_latch <= ~enable_set_alarm_latch;
                end
            end
            prev_BTN_D <= debounced_BTN_D;

            if (enable_set_alarm_latch) begin
                if (set_hour) begin
                    hold_counter_hour <= hold_counter_hour + 16'd1;
                    if (hold_counter_hour == 16'd1) begin  
                        alarm_hour <= (alarm_hour == 6'd23) ? 6'd0 : alarm_hour + 6'd1;
                    end else if (hold_counter_hour >= 16'd1000) begin  
                        long_press_active_alarm <= 1'b1;  
                        if ((hold_counter_hour % 16'd50 == 0) && (current_digit == 2'b00)) begin  
                            alarm_hour <= (alarm_hour == 6'd23) ? 6'd0 : alarm_hour + 6'd1;
                        end
                    end
                end else begin
                    hold_counter_hour <= 16'd0;  
                    long_press_active_alarm <= 1'b0;  
                end

                if (set_minute) begin
                    hold_counter_minute <= hold_counter_minute + 16'd1;
                    if (hold_counter_minute == 16'd1) begin  
                        alarm_minute <= (alarm_minute == 6'd59) ? 6'd0 : alarm_minute + 6'd1;
                    end else if (hold_counter_minute >= 16'd1000) begin  
                        long_press_active_alarm <= 1'b1;  
                        if ((hold_counter_minute % 16'd50 == 0) && (current_digit == 2'b00)) begin  
                            alarm_minute <= (alarm_minute == 6'd59) ? 6'd0 : alarm_minute + 6'd1;
                        end
                    end
                end else begin
                    hold_counter_minute <= 16'd0;
                    long_press_active_alarm <= 1'b0;
                end
            end

            if (toggle_alarm) begin
                alarm_enabled <= ~alarm_enabled;
            end
        end
    end

    always @(posedge clk_1kHz or posedge rst) begin
        if (rst) begin
            alarm_latch <= 1'b0;
            alarm_trigger <= 1'b0;
        end else begin
            if (alarm_enabled && (alarm_hour == current_hour) && (alarm_minute == current_minute)) begin
                alarm_latch <= 1'b1;  
            end
            if (alarm_latch) begin
                alarm_trigger <= 1'b1;
            end
            if (debounced_BTN_D) begin
                alarm_latch <= 1'b0;  
                alarm_trigger <= 1'b0;
            end
        end
    end
endmodule
