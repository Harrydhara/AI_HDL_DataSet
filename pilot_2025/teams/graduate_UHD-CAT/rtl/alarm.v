module alarm(
    input clk,
    input reset,
    input select_btn,           // Button to select hour, minute, or second
    input increment_btn,        // Button to increment selected unit of alarm time
    input toggle_alarm_btn,     // Button to toggle alarm on/off
    input [5:0] current_hours,   // Current hour (0 to 23)
    input [5:0] current_minutes, // Current minute (0 to 59)
    input [5:0] current_seconds, // Current second (0 to 59)
    output reg alarm_led        // Blinking LED for alarm
);
    // Internal registers for alarm time
    reg [5:0] alarm_hours;    // Alarm hour (0 to 23)
    reg [5:0] alarm_minutes;  // Alarm minute (0 to 59)
    reg [5:0] alarm_seconds;  // Alarm second (0 to 59)

    // Internal state for alarm toggling and selection
    reg alarm_on;            // Flag to indicate if alarm is on or off
    reg [1:0] select_state;  // State to select hour, minute, or second (0 = hour, 1 = minute, 2 = second)
    
    // Blinking LED
    reg [31:0] blink_counter;  // Counter for LED blinking
    reg led_state;             // LED on/off state
    reg alarm_triggered;       // Tracks alarm activation

    // Parameters for blinking frequency (example: 1 Hz blink)
    parameter BLINK_FREQ = 50000000;  // Assuming a 50 MHz clock, this gives 1Hz blinking

    // Fast increment
    reg [15:0] hold_counter;
    reg increment_fast;
    
    // Logic to toggle alarm state (on/off)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            alarm_on <= 1'b0;
        end else if (toggle_alarm_btn) begin
            alarm_on <= ~alarm_on;  // Toggle alarm on/off
        end
    end

    // Logic to select which part of the alarm time (hour, minute, second) to increment
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            select_state <= 2'b00;  // Start with hour selection
        end else if (select_btn) begin
            // Cycle through hour (00), minute (01), and second (10) selection
            case (select_state)
                2'b00: select_state <= 2'b01; // From hour to minute
                2'b01: select_state <= 2'b10; // From minute to second
                2'b10: select_state <= 2'b00; // From second back to hour
                default: select_state <= 2'b00; // Default back to hour
            endcase
        end
    end
    
    // Logic to increment the selected alarm time unit (hour, minute, second)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            alarm_hours   <= 6'd0;
            alarm_minutes <= 6'd0;
            alarm_seconds <= 6'd0;
        end else if (increment_btn) begin
            case (select_state)
                2'b00: begin  // Hour selected
                    if (alarm_hours < 23)
                        alarm_hours <= alarm_hours + 1;
                    else
                        alarm_hours <= 6'd0;  // Wrap around to 0 after 23
                end
                2'b01: begin  // Minute selected
                    if (alarm_minutes < 59)
                        alarm_minutes <= alarm_minutes + 1;
                    else
                        alarm_minutes <= 6'd0;  // Wrap around to 0 after 59
                end
                2'b10: begin  // Second selected
                    if (alarm_seconds < 59)
                        alarm_seconds <= alarm_seconds + 1;
                    else
                        alarm_seconds <= 6'd0;  // Wrap around to 0 after 59
                end
            endcase
        end
    end

always @(posedge clk or posedge reset) begin
    if (reset) begin
        hold_counter <= 0;
        increment_fast <= 0;
    end else if (increment_btn) begin
        if (hold_counter >= 500) begin // 500 ms hold threshold
            increment_fast <= 1; // Enable fast increment
        end else begin
            hold_counter <= hold_counter + 1;
        end
    end else begin
        hold_counter <= 0;
        increment_fast <= 0;
    end
end
    
    always @(posedge clk) begin
        if (increment_fast) begin
            case (select_state)
                2'b00: alarm_hours <= (alarm_hours == 6'd23) ? 6'd0 : alarm_hours + 1;
                2'b01: alarm_minutes <= (alarm_minutes == 6'd59) ? 6'd0 : alarm_minutes + 1;
                2'b10: alarm_seconds <= (alarm_seconds == 6'd59) ? 6'd0 : alarm_seconds + 1;
            endcase
        end
    end

    // Logic to increment the selected alarm time unit (hour, minute, second)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            blink_counter <= 32'd0;
            led_state <= 1'b0;
            alarm_led <= 1'b0;
            alarm_triggered <= 1'b0; // Tracks whether alarm condition has been met
        end else if (alarm_on) begin
            // Check if current time matches alarm time
            if (current_hours == alarm_hours && current_minutes == alarm_minutes && current_seconds == alarm_seconds) begin
                alarm_triggered <= 1'b1; // Latch the alarm triggered state
            end
    
            // If the alarm is triggered, handle LED blinking
            if (alarm_triggered) begin
                blink_counter <= blink_counter + 1;
                
                // Toggle LED state every BLINK_FREQ cycles
                if (blink_counter >= BLINK_FREQ) begin
                    blink_counter <= 32'd0;
                    led_state <= ~led_state;
                end
    
                alarm_led <= led_state;
            end else begin
                alarm_led <= 1'b0;  // No match, LED off
            end
        end else begin
            blink_counter <= 32'd0;
            led_state <= 1'b0;
            alarm_led <= 1'b0;
            alarm_triggered <= 1'b0; // Reset alarm triggered state
        end
    end

endmodule
