module alarm (
    input wire clk,                  // Clock signal
    input wire reset,                // Reset signal
    input wire button1,              // Button to increment/decrement hours
    input wire button2,              // Button to toggle increment/decrement mode
    input wire button_confirm_hour,  // Button to confirm the alarm hour
    input wire button_confirm_minute,// Button to confirm the alarm minute
    input wire [4:0] current_hours,  // Current hours from digital_clock
    input wire [5:0] current_minutes,// Current minutes from digital_clock
    output reg [15:0] bcd_number,    // BCD number for seven-segment display
    output reg alarm_led             // Alarm LED indication
);

    // **Internal Registers**
    reg [4:0] alarm_hours;           // Alarm hours (0-23)
    reg [5:0] alarm_minutes;         // Alarm minutes (0-59)
    reg [4:0] set_hours;             // Temporary storage for setting hours
    reg [5:0] set_minutes;           // Temporary storage for setting minutes
    reg alarm_active;                // Flag to indicate if the alarm is active
    reg state;                       // State for setting hours or minutes
    reg increment_mode;              // Mode for increment/decrement

    // **State Definitions**
    localparam SET_HOUR = 1'b0, SET_MINUTE = 1'b1;

    // **State Transition Logic**
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= SET_HOUR;             // Start in hour-setting state
            increment_mode <= 1'b1;        // Default to increment mode
        end else begin
            // Toggle increment/decrement mode using button2
            if (button2) increment_mode <= ~increment_mode;

            // Transition between SET_HOUR and SET_MINUTE states
            case (state)
                SET_HOUR: if (button_confirm_hour) state <= SET_MINUTE;
                SET_MINUTE: if (button_confirm_minute) state <= SET_HOUR;
            endcase
        end
    end

    // **Alarm Setting Logic**
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset all registers
            set_hours <= 5'd0;
            set_minutes <= 6'd0;
            alarm_hours <= 5'd0;
            alarm_minutes <= 6'd0;
            alarm_active <= 1'b0;
            bcd_number <= 16'd0;
        end else begin
            // Time-setting logic
            case (state)
                SET_HOUR: begin
                    if (button1) begin
                        if (increment_mode)
                            set_hours <= (set_hours < 23) ? set_hours + 1 : 5'd0; // Increment hours
                        else
                            set_hours <= (set_hours == 0) ? 5'd23 : set_hours - 1; // Decrement hours
                    end
                end
                SET_MINUTE: begin
                    if (button1) begin
                        if (increment_mode)
                            set_minutes <= (set_minutes < 59) ? set_minutes + 1 : 6'd0; // Increment minutes
                        else
                            set_minutes <= (set_minutes == 0) ? 6'd59 : set_minutes - 1; // Decrement minutes
                    end
                end
            endcase

            // Confirm alarm time
            if (button_confirm_minute) begin
                alarm_hours <= set_hours;
                alarm_minutes <= set_minutes;
                alarm_active <= 1'b1; // Activate alarm
            end

            // Update BCD output for seven-segment display
            bcd_number[15:12] <= set_hours / 10; // Tens place of hour
            bcd_number[11:8]  <= set_hours % 10; // Ones place of hour
            bcd_number[7:4]   <= set_minutes / 10; // Tens place of minute
            bcd_number[3:0]   <= set_minutes % 10; // Ones place of minute
        end
    end

    // **Alarm Trigger Logic**
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            alarm_led <= 1'b0;          // Turn off alarm LED on reset
        end else if (alarm_active && 
                    (current_hours == alarm_hours) && 
                    (current_minutes == alarm_minutes)) begin
            alarm_led <= 1'b1;          // Turn on alarm LED when time matches
        end else begin
            alarm_led <= 1'b0;          // Turn off alarm LED otherwise
        end
    end

endmodule
