module digital_clock (
    input wire clk,                // Clock signal (1 Hz or slower from a clock divider)
    input wire reset,              // Reset signal
    input wire button1,            // Button to increment/decrement hours
    input wire button2,            // Button to increment/decrement minutes
    input wire button_confirm_hour,// Button to confirm hours
    input wire button_confirm_minute, // Button to confirm minutes
    output reg [4:0] hours,        // Current hours (0-23)
    output reg [5:0] minutes,      // Current minutes (0-59)
    output reg [15:0] bcd_number   // BCD number for seven-segment display
);

    // **Internal Registers**
    reg [4:0] set_hours;           // Temporary storage for setting hours
    reg [5:0] set_minutes;         // Temporary storage for setting minutes
    reg running;                   // Flag to indicate if the clock is running
    reg state;                     // State for setting hours or minutes
    reg [15:0] timeout_counter;    // Counter for time increment
    localparam TIMEOUT_LIMIT = 16'd60000; // Limit for 1-minute intervals (assuming 1 kHz clock)

    // **State Definitions**
    localparam SET_HOUR = 1'b0, SET_MINUTE = 1'b1;

    // **State Transition Logic**
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= SET_HOUR;  // Start with hour-setting state
        end else begin
            case (state)
                SET_HOUR: if (button_confirm_hour) state <= SET_MINUTE;
                SET_MINUTE: if (button_confirm_minute) state <= SET_HOUR;
            endcase
        end
    end

    // **Main Clock Logic**
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset all registers
            hours <= 5'd0;
            minutes <= 6'd0;
            set_hours <= 5'd0;
            set_minutes <= 6'd0;
            timeout_counter <= 16'd0;
            bcd_number <= 16'd0;
            running <= 1'b0;
        end else begin
            case (state)
                // **SET_HOUR State**
                SET_HOUR: begin
                    if (button1) set_hours <= (set_hours < 23) ? set_hours + 1 : 0;
                    if (button2) set_hours <= (set_hours == 0) ? 23 : set_hours - 1;
                end
                // **SET_MINUTE State**
                SET_MINUTE: begin
                    if (button1) set_minutes <= (set_minutes < 59) ? set_minutes + 1 : 0;
                    if (button2) set_minutes <= (set_minutes == 0) ? 59 : set_minutes - 1;
                end
            endcase

            // **Confirm Time Setting**
            if (button_confirm_minute) begin
                hours <= set_hours;
                minutes <= set_minutes;
                running <= 1'b1;  // Start clock
            end

            // **Clock Running Logic**
            if (running) begin
                if (timeout_counter >= TIMEOUT_LIMIT) begin
                    timeout_counter <= 0; // Reset the timeout counter
                    // Increment time
                    if (minutes == 59) begin
                        minutes <= 0;
                        hours <= (hours == 23) ? 0 : hours + 1; // Wrap-around hours
                    end else begin
                        minutes <= minutes + 1;
                    end
                end else begin
                    timeout_counter <= timeout_counter + 1;
                end
            end

            // **Update BCD Output for Display**
            bcd_number[15:12] <= hours / 10;   // Tens place of hours
            bcd_number[11:8]  <= hours % 10;   // Ones place of hours
            bcd_number[7:4]   <= minutes / 10; // Tens place of minutes
            bcd_number[3:0]   <= minutes % 10; // Ones place of minutes
        end
    end
endmodule
