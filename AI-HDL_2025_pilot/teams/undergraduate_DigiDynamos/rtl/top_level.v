module top_level(  
    input wire clk,               // 100 MHz clock input from Basys 3 board  
    input wire rst,               // Reset signal  
    input wire button1,           // Button to increment hours/minutes or alarm hours/minutes or start/stop stopwatch  
    input wire button2,           // Button to decrement hours/minutes or alarm hours/minutes or reset stopwatch  
    input wire button3,           // Button to confirm the time or alarm time  
    input wire button4,           // Button to change mode  
//    input wire button5,           // Button to reset  
    output wire [6:0] seg,        // 7-segment display segments (a-g)  
    output wire [3:0] an,         // 7-segment display anodes (digits)  
    output reg am_pm_led,         // AM/PM LED indication  
    output wire alarm_led,        // Alarm LED indication  
    output reg set_time_led,      // LED to indicate time-setting mode  
    output reg stop_watch_led,    // LED to indicate stopwatch mode  
    output reg clock_led,         // LED to indicate normal clock display mode  
    output reg convert_12_led,    // LED to indicate 12-hour mode  
    output reg alarm_state_led,   // LED to indicate alarm setting mode  
    output reg timezone_led,      // LED to indicate timezone adjustment mode  
    output wire [4:0] current_hours,   // Current hours output  
    output wire [5:0] current_minutes  // Current minutes output  
);  

    // **Internal Signals**  
    wire clk_1kHz;                     // 1 kHz clock signal  
    wire debounced_button1;            // Debounced signal for button1  
    wire debounced_button2;            // Debounced signal for button2  
    wire debounced_button3;            // Debounced signal for button3  
    wire debounced_button4;            // Debounced signal for button4 (mode change)  
 //   wire debounced_button5;            // Debounced signal for button5 (reset)  
    wire [15:0] digital_number;        // BCD number from the digital clock  
    wire [15:0] convert_number;        // BCD number from the 24-to-12-hour converter  
    wire [15:0] alarm_number;          // BCD number from the alarm module  
    wire [15:0] time_zone_number;      // BCD number from the timezone module  
    wire [15:0] stopwatch_time;        // BCD number from the stopwatch module  
    reg [15:0] display_number;         // BCD number currently being displayed  

    // **State Machine States**  
    parameter STATE_SET_TIME        = 3'b000;  
    parameter STATE_CLOCK           = 3'b001;  
    parameter STATE_ALARM           = 3'b010;  
    parameter STATE_TIME_ZONE       = 3'b011;  
    parameter STATE_STOPWATCH       = 3'b100;  
    parameter STATE_CONVERT_24_TO_12 = 3'b101;  

    reg [2:0] current_state, next_state;  // Current and next state of the FSM  

    // **Clock Divider: Generate 1 kHz clock**  
    clock_divider #(.TARGET_FREQ(1000)) clk_div_1kHz (  
        .clk_in(clk),  
        .reset(rst),  
        .clk_out(clk_1kHz)  
    );  

    // **Debouncing Modules for Buttons**  
    buttonDebouncer button_debouncer1 (.clk(clk_1kHz), .reset(rst), .button_in(button1), .button_out(debounced_button1));  
    buttonDebouncer button_debouncer2 (.clk(clk_1kHz), .reset(rst), .button_in(button2), .button_out(debounced_button2));  
    buttonDebouncer button_debouncer3 (.clk(clk_1kHz), .reset(rst), .button_in(button3), .button_out(debounced_button3));  
    buttonDebouncer button_debouncer4 (.clk(clk_1kHz), .reset(rst), .button_in(button4), .button_out(debounced_button4));  
 //   buttonDebouncer button_debouncer5 (.clk(clk_1kHz), .reset(rst), .button_in(button5), .button_out(debounced_button5));  

    // **Digital Clock Module**  
    digital_clock clock_inst (  
        .clk(clk_1kHz),  
        .reset(rst),  
        .button1((current_state == STATE_SET_TIME) ? debounced_button1 : 1'b0),  
        .button2((current_state == STATE_SET_TIME) ? debounced_button2 : 1'b0),  
        .button_confirm_hour((current_state == STATE_SET_TIME) ? debounced_button3 : 1'b0),  
        .button_confirm_minute((current_state == STATE_SET_TIME) ? debounced_button4 : 1'b0),  
        .hours(current_hours),  
        .minutes(current_minutes),  
        .bcd_number(digital_number)  
    );  

    // **24-to-12 Hour Conversion Module**  
    convert_24_to_12 convert_inst (  
        .clk(clk_1kHz),  
        .reset(rst),  
        .hours_24(current_hours),  
        .minutes_24(current_minutes),  
        .bcd_number(convert_number),  
        .am_pm_reg() // Assuming this signal is required by your design but not used explicitly here  
    );  

    // **Alarm Module**  
    alarm alarm_inst (  
        .clk(clk_1kHz),  
        .reset(rst),  
        .button1((current_state == STATE_ALARM) ? debounced_button1 : 1'b0),  
        .button2((current_state == STATE_ALARM) ? debounced_button2 : 1'b0),  
        .button_confirm_hour((current_state == STATE_ALARM) ? debounced_button3 : 1'b0),  
        .button_confirm_minute((current_state == STATE_ALARM) ? debounced_button4 : 1'b0),  
        .current_hours(current_hours),  
        .current_minutes(current_minutes),  
        .bcd_number(alarm_number),  
        .alarm_led(alarm_led)  
    );  

    // **Time Zone Module**  
    time_zone tz_inst (  
        .clk(clk_1kHz),  
        .reset(rst),  
        .button_tz1((current_state == STATE_TIME_ZONE) ? debounced_button1 : 1'b0),  
        .button_tz2((current_state == STATE_TIME_ZONE) ? debounced_button2 : 1'b0),  
        .button_tz3((current_state == STATE_TIME_ZONE) ? debounced_button3 : 1'b0),  
        .current_hours(current_hours),  
        .current_minutes(current_minutes),  
        .bcd_number(time_zone_number)  
    );  

    // **Stopwatch Module**  
    
    stopwatch stopwatch_inst (  
        .clk(clk_1kHz),  
        .rst(rst),  
        .start_stop((current_state == STATE_STOPWATCH) ? debounced_button1 : 1'b0),  
        .reset_button((current_state == STATE_STOPWATCH) ? debounced_button2 : 1'b0),  
        .number1((current_state == STATE_STOPWATCH) ? debounced_button1 : 1'b0),  
        .number2((current_state == STATE_STOPWATCH) ? debounced_button2 : 1'b0),  
        .number3((current_state == STATE_STOPWATCH) ? debounced_button3 : 1'b0),  
        .time_out(stopwatch_time)  
    );  

    // **State Machine: State Transitions**  
    always @(posedge clk_1kHz or posedge rst) begin  
        if (rst)  
            current_state <= STATE_SET_TIME;  
        else if (debounced_button4)  
            current_state <= next_state;  
    end  

    always @(*) begin  
        case (current_state)  
            STATE_SET_TIME:        next_state = STATE_CLOCK;  
            STATE_CLOCK:           next_state = STATE_ALARM;  
            STATE_ALARM:           next_state = STATE_TIME_ZONE;  
            STATE_TIME_ZONE:       next_state = STATE_STOPWATCH;  
            STATE_STOPWATCH:       next_state = STATE_CONVERT_24_TO_12;  
            STATE_CONVERT_24_TO_12: next_state = STATE_SET_TIME;  
            default:               next_state = STATE_SET_TIME;  
        endcase  
    end  

    // **LED and Display Control**  
    always @(*) begin  
        // Default: Turn off all LEDs and use clock display  
        set_time_led = 1'b0;  
        clock_led = 1'b0;  
        alarm_state_led = 1'b0;  
        timezone_led = 1'b0;  
        convert_12_led = 1'b0;  
        display_number = digital_number;  

        // State-specific actions  
        case (current_state)  
            STATE_SET_TIME: begin  
                display_number[15:12] = clock_inst.set_hours / 10;  // Tens place of hours  
                display_number[11:8]  = clock_inst.set_hours % 10;  // Units place of hours  
                display_number[7:4]   = clock_inst.set_minutes / 10; // Tens place of minutes  
                display_number[3:0]   = clock_inst.set_minutes % 10; // Units place of minutes  
                set_time_led = 1'b1;  
            end  
            STATE_CLOCK: begin  
                clock_led = 1'b1;  
            end  
            STATE_ALARM: begin  
                display_number = alarm_number;  
                alarm_state_led = 1'b1;  
            end  
            STATE_TIME_ZONE: begin  
                display_number = time_zone_number;  
                timezone_led = 1'b1;  
            end  
            STATE_STOPWATCH: begin  
                display_number = stopwatch_time;  
                stop_watch_led = 1'b1; // Ensure this updates for the stopwatch state  
            end  
            STATE_CONVERT_24_TO_12: begin  
                display_number = convert_number;  
                convert_12_led = 1'b1;  
            end  
        endcase  
    end  

    // **AM/PM LED Control**  
    always @(*) begin  
        am_pm_led = (current_state == STATE_CONVERT_24_TO_12) ? convert_inst.am_pm_reg : 1'b0;  
    end  

    // **7-Segment Display Control**  
    seven_segment_display display_inst (  
        .clk(clk_1kHz),  
        .rst(rst),  
        .number(display_number),  
        .seg(seg),  
        .an(an)  
    );  

endmodule  