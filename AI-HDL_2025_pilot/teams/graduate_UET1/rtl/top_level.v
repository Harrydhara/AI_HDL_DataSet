module top_level (
    input wire clk,               // System clock
    input wire reset,             // Reset signal
    input wire [4:0] set_hour,    // Set hour input (0-23 or 12-hour format)
    input wire [5:0] set_min,     // Set minute input (0-59)
    input wire [3:0] tz_select,   // Timezone selection
    input wire mode_btn,          // Button to switch modes

    input wire btn_0,
    input wire btn_1,
    input wire btn_2,

    output wire alarm_led,        // Alarm LED output
    output wire [6:0] seg,        // 7-segment display output
    output wire [3:0] an          // 7-segment anode control
);

    // State Encoding
    parameter CLOCK = 2'b00, STOPWATCH = 2'b01, ALARM = 2'b10, CONVERTER = 2'b11;
    reg [1:0] current_state, next_state;

    // Internal Signals
    wire [15:0] bcd_time_clock;
    wire [15:0] bcd_time_alarm;
    wire [15:0] bcd_time_convert;
    wire [4:0] hour_12, hour_24, alarm_hour, tz_hour_24;
    wire [5:0] minute_12, minute_24, alarm_minute;
    wire [15:0] bcd_out;
    wire clk_1kHz;
    wire mode_btn_debounced, set_time_debounced, am_pm_debounced;
    wire start_stop_debounced, reset_stopwatch_debounced;
    wire alarm_set_debounced, alarm_inc_debounced, alarm_toggle_debounced;

    //-------------button for DEMUX btn input----------------
    wire alarm_set_btn;     // Button to cycle through alarm settings (HH/MM/SS)
    wire alarm_inc_btn;     // Button to increment alarm time value
    wire alarm_toggle_btn;  // Button to enable/disable alarm
    
    wire start_stop_btn;    // Stopwatch start/stop button
    wire reset_stopwatch;   // Stopwatch reset button
    
    wire set_time;          // Set time signal
    
    wire am_pm;             // AM/PM indicator (1 = PM, 0 = AM)
    //-------------------------------------------
    
    assign bcd_time_clock = { (hour_12 / 10) << 12 | (hour_12 % 10) << 8 | (minute_12 / 10) << 4 | (minute_12 % 10) };
    assign bcd_time_alarm = { (alarm_hour / 10) << 12 | (alarm_hour % 10) << 8 | (alarm_minute / 10) << 4 | (alarm_minute % 10) };
    assign bcd_time_convert = { (hour_24 / 10) << 12 | (hour_24 % 10) << 8 | (minute_24 / 10) << 4 | (minute_24 % 10) };
    
    
    assign set_time = current_state == CLOCK ? btn_0 : 0;
    
    assign start_stop_btn = current_state == STOPWATCH ? btn_0 : 0;
    assign reset_stopwatch = current_state == STOPWATCH ? btn_1 : 0;
    
    assign alarm_set_btn = current_state == ALARM ? btn_0 : 0;
    assign alarm_inc_btn = current_state == ALARM ? btn_1 : 0;
    assign alarm_toggle_btn = current_state == ALARM ? btn_2 : 0;
    
    assign am_pm = current_state == CONVERTER ? btn_0 : 0;
    
    // Clock Divider
    clock_divider #(.FREQ_TARGET(1_000)) clk_div_inst (
        .clk_in(clk),
        .reset(reset),
        .clk_out(clk_1kHz)
    );

    // Button Debouncing
    button_debouncer mode_btn_debounce_inst (
        .clk(clk_1kHz),
        .reset(reset),
        .button_in(mode_btn),
        .button_out(mode_btn_debounced)
    );

    button_debouncer set_time_debounce_inst (
        .clk(clk_1kHz),
        .reset(reset),
        .button_in(set_time),
        .button_out(set_time_debounced)
    );

    button_debouncer am_pm_debounce_inst (
        .clk(clk_1kHz),
        .reset(reset),
        .button_in(am_pm),
        .button_out(am_pm_debounced)
    );

    button_debouncer start_stop_debounce_inst (
        .clk(clk_1kHz),
        .reset(reset),
        .button_in(start_stop_btn),
        .button_out(start_stop_debounced)
    );

    button_debouncer reset_debounce_inst (
        .clk(clk_1kHz),
        .reset(reset),
        .button_in(reset_stopwatch),
        .button_out(reset_stopwatch_debounced)
    );

    button_debouncer alarm_set_debounce_inst (
        .clk(clk_1kHz),
        .reset(reset),
        .button_in(alarm_set_btn),
        .button_out(alarm_set_debounced)
    );

    button_debouncer alarm_inc_debounce_inst (
        .clk(clk_1kHz),
        .reset(reset),
        .button_in(alarm_inc_btn),
        .button_out(alarm_inc_debounced)
    );

    button_debouncer alarm_toggle_debounce_inst (
        .clk(clk_1kHz),
        .reset(reset),
        .button_in(alarm_toggle_btn),
        .button_out(alarm_toggle_debounced)
    );

    // Digital Clock
    digital_clock clock_module (
        .clk_1khz(clk_1kHz),
        .reset(reset),
        .set_time(set_time_debounced),
        .set_hour(set_hour),
        .set_min(set_min),
        .tz_select(tz_select),
        .hours(hour_12),
        .minutes(minute_12),
        .tz_hours(tz_hour_24)
    );

    // 12 to 24 Hour Converter
    convert_12_to_24 convert_inst (
        .hour_12(hour_12),
        .minute_12(minute_12),
        .am_pm(am_pm_debounced),
        .hour_24(hour_24),
        .minute_24(minute_24)
    );

    // Alarm Module
    alarm_module alarm_inst (
        .clk_1khz(clk_1kHz),
        .reset(reset),
        .current_hour(hour_24),
        .current_minute(minute_24),
        .btn_0(alarm_set_debounced),
        .btn_1(alarm_inc_debounced),
        .btn_2(alarm_toggle_debounced),
        .alarm_hour(alarm_hour),    // Alarm hour (0-23)
        .alarm_minute(alarm_minute),  // Alarm minute (0-59)
        .alarm_led(alarm_led)
    );

    // Stopwatch Module
    stopwatch stopwatch_inst (
        .clk_1khz(clk_1kHz),
        .reset(reset),
        .stop_start(start_stop_debounced),
        .reset_counter(reset_stopwatch_debounced),
        .bcd_out(bcd_out)
    );

    // 7-Segment Display Driver
    four_digit_7seg_display display_inst (
        .clk_1khz(clk_1kHz),
        .reset(reset),
        .bcd_in(
            (current_state == STOPWATCH) ? bcd_out :
            (current_state == CLOCK) ? bcd_time_clock :
            (current_state == ALARM) ? bcd_time_alarm :
            bcd_time_convert // CONVERTER (12-hour format)
        ),
        .seg(seg),
        .an(an)
    );


    // State Machine
    always @(posedge clk_1kHz or posedge reset) begin
        if (reset)
            current_state <= CLOCK;
        else
            current_state <= next_state;
    end

    always @(*) begin
        case (current_state)
            CLOCK: begin
                if (mode_btn_debounced) next_state = STOPWATCH;
                else next_state = CLOCK;
            end
            STOPWATCH: begin
                if (mode_btn_debounced) next_state = ALARM;
                else next_state = STOPWATCH;
            end
            ALARM: begin
                if (mode_btn_debounced) next_state = CONVERTER;
                else next_state = ALARM;
            end
            CONVERTER: begin
                if (mode_btn_debounced) next_state = CLOCK;
                else next_state = CONVERTER;
            end
            default: next_state = CLOCK;
        endcase
    end

endmodule
