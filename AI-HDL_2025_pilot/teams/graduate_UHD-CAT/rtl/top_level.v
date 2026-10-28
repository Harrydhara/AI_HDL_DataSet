module top_level(
    input wire clk,               // 100 MHz clock input from Basys 3 board
    input wire rst,               // Reset signal
    input wire button0,           // Button 0 input (Start/Stop or Set Time Enable)
    input wire button1,           // Button 1 input (Reset)
    input wire button2,           // Button 2 input (State Change)
    input wire button3,           // Button to select hour, minute, or second
    input wire button4,           // Button to increment selected unit of alarm time
    input toggle_alarm,             // Button to toggle alarm on/off
    input wire set_time_enable,   // Enable for setting time 
    input wire [5:0] set_hours,   // Input for setting hours (0-23)
    input wire [5:0] set_minutes, // Input for setting minutes (0-59)
    input wire [5:0] set_seconds, // Input for setting seconds (0-59)
    input wire [4:0] timezone_select, // Timezone selection (index-based)
    output wire [6:0] seg,        // 7-segment display segments (a-g)
    output wire [3:0] an,         // 7-segment display anodes (digits)
    output reg is_pm,              // Indicates PM (1 for PM, 0 for AM)
    output reg alarm_led          // blinking LED when alarm is triggered
);

    // State encoding using localparam
    localparam CLOCK_STATE    = 2'b00;
    localparam STOPWATCH_STATE = 2'b01;
    localparam ALARM_STATE    = 2'b10;
    localparam CONVERT_STATE  = 2'b11;

    // State registers
    reg [1:0] current_state, next_state;

    // Internal wires for the debounced buttons
    wire button0_debounced, button1_debounced, button2_debounced;

    // Internal wire for the clock divider output
    wire clk_div;

    // Digital clock
    wire [15:0] stopwatch_value;
    wire [5:0] hours, minutes, seconds, hours_24, minutes_24;
    wire [5:0] adjusted_hours;
    wire [5:0] hours;
    wire [5:0] minutes;
    wire [5:0] seconds;
    wire is_pm;
    
    // Inputs for alarm
    reg select_btn;
    reg increment_btn;
    reg toggle_alarm_btn;
    wire alarm_led;
    wire [15:0] alarm_time;

    // Clock divider instantiation
    clock_divider clock_div_inst (
        .clk_in(clk),
        .rst(rst),
        .clk_out(clk_div)
    );
    
    // Button debouncer instantiations
    buttonDebouncer button0_debouncer (.clk(clk_div), .rst(rst), .button_in(button0), .button_out(button0_debounced));
    buttonDebouncer button1_debouncer (.clk(clk_div), .rst(rst), .button_in(button1), .button_out(button1_debounced));
    buttonDebouncer button2_debouncer (.clk(clk_div), .rst(rst), .button_in(button2), .button_out(button2_debounced));

    // Stopwatch instantiation
    stopwatch stopwatch_inst (
        .clk(clk_div), .rst(rst), .start_stop(button0_debounced), .reset_button(button1_debounced), .time_out(stopwatch_value)
    );

    // Digital clock instantiation
    // Zero-extend set_hours (4-bit to 6-bit) and explicitly set set_seconds to 0
    digital_clock digital_clock_inst (
        .clk_div(clk_div), .reset(rst), .set_time_enable(set_time_enable),
        .set_hours({2'b00, set_hours}), .set_minutes(set_minutes), .set_seconds(6'b000000),
        .timezone_select(timezone_select), .hours(hours), .minutes(minutes), .seconds(seconds),
        .adjusted_hours(adjusted_hours), .is_pm(is_pm)
    );
     
    // 12-to-24-hour conversion
    convert_12_to_24 convert_dut (
        .hours_12(adjusted_hours), .minutes_12(minutes), .is_pm(is_pm),
        .hours_24(hours_24), .minutes_24(minutes_24)
    );

    // Alarm clock module
       alarm alarm_inst (
        .clk(clk),
        .reset(reset),
        .select_btn(select_btn),
        .increment_btn(increment_btn),
        .toggle_alarm_btn(toggle_alarm_btn),
        .current_hours(hours),
        .current_minutes(minutes),
        .current_seconds(seconds),
        .alarm_led(alarm_led)
    );

    // State machine logic
    always @(posedge clk_div or posedge rst) begin
        if (rst) begin
            current_state <= CLOCK_STATE;
        end else if (button2_debounced) begin
            current_state <= next_state;
        end
    end

    always @(*) begin
        case (current_state)
            CLOCK_STATE: next_state = STOPWATCH_STATE;
            STOPWATCH_STATE: next_state = ALARM_STATE;
            ALARM_STATE: next_state = CONVERT_STATE;
            CONVERT_STATE: next_state = CLOCK_STATE;
            default: next_state = CLOCK_STATE;
        endcase
    end

    // Multiplexer for 7-segment display input
    reg [15:0] display_value;
    always @(*) begin
        case (current_state)
            CLOCK_STATE: display_value = {hours_24, minutes_24};
            STOPWATCH_STATE: display_value = stopwatch_value;
            ALARM_STATE: display_value = alarm_time;
            CONVERT_STATE: display_value = {adjusted_hours, minutes};
            default: display_value = 16'h0000;
        endcase
    end

    // 7-segment display driver
    seven_segment_display seg_display (
        .clk(clk_div), .rst(rst), .number(display_value), .seg(seg), .an(an)
    );

endmodule

/*module top_level(
    input wire clk,               // 100 MHz clock input from Basys 3 board
    input wire rst,               // Reset signal
    input wire button0,           // Button 0 input (Start/Stop or Set Time Enable)
    input wire button1,           // Button 1 input (Reset)
    input wire set_time_enable,   // Enable for setting time
    input wire [5:0] set_hours,   // Input for setting hours (0-23)
    input wire [5:0] set_minutes, // Input for setting minutes (0-59)
    input wire [5:0] set_seconds, // Input for setting seconds (0-59)
    input wire [4:0] timezone_select, // Timezone selection (index-based)
    output wire [6:0] seg,        // 7-segment display segments (a-g)
    output wire [3:0] an,         // 7-segment display anodes (digits)
    output reg is_pm              // Indicates PM (1 for PM, 0 for AM)
);

    // Internal wires for the debounced buttons
    wire button0_debounced;
    wire button1_debounced;

    // Internal wire for the clock divider output
    wire clk_div;

    // Internal wires for the stopwatch value and time outputs
    wire [15:0] stopwatch_value;
    wire [5:0] hours, minutes, seconds,hours_24, minutes_24;
    wire [5:0] adjusted_hours;
    wire is_pm;

    // Instantiate clock divider (e.g., divide the 100 MHz clock to a 1 kHz clock for the stopwatch)
    clock_divider clock_div_inst (
        .clk_in(clk),
        .rst(rst),
        .clk_out(clk_div)
    );

    // Instantiate button debouncer for button 0 (Start/Stop or Set Time Enable button)
    buttonDebouncer button0_debouncer (
        .clk(clk_div),             // Use the divided clock for debouncing
        .rst(rst),
        .button_in(button0),
        .button_out(button0_debounced)
    );

    // Instantiate button debouncer for button 1 (Reset button)
    buttonDebouncer button1_debouncer (
        .clk(clk_div),             // Use the divided clock for debouncing
        .rst(rst),
        .button_in(button1),
        .button_out(button1_debounced)
    );

    // Instantiate the stopwatch module
    stopwatch stopwatch_inst (
        .clk(clk_div),               // Use the divided clock as input to the stopwatch
        .rst(rst),                   // Reset signal for the stopwatch
        .start_stop(button0_debounced), // Debounced start/stop button
        .reset_button(button1_debounced), // Debounced reset button
        .time_out(stopwatch_value)   // BCD output for 7-segment display
    );

    // Instantiate the digital_clock module
    digital_clock digital_clock_inst (
        .clk_div(clk_div),                // 1 Hz clock signal
        .reset(rst),                      // Debounced reset signal
        .set_time_enable(set_time_enable), // Debounced set time enable signal
        .set_hours(set_hours),            // Input for setting hours
        .set_minutes(set_minutes),        // Input for setting minutes
        .set_seconds(set_seconds),        // Input for setting seconds
        .timezone_select(timezone_select), // Timezone selection
        .hours(hours),                    // Current hour output
        .minutes(minutes),                // Current minute output
        .seconds(seconds),                // Current second output
        .adjusted_hours(adjusted_hours),  // Adjusted hour output based on timezone
        .is_pm(is_pm)                    // Indicates PM (1 for PM, 0 for AM)
    );
          
    // Instantiate the 12-to-24-hour conversion module
    convert_12_to_24 convert_dut (
        .hours_12(adjusted_hours),
        .minutes_12(minutes),
        .is_pm(is_pm),
        .hours_24(hours_24),
        .minutes_24(minutes_24)
    );

    // Instantiate the 7-segment display driver to display the time
    seven_segment_display seg_display (
        .clk(clk_div),               // Use the divided clock for display updates
        .rst(rst),                   // Reset signal
        .number(stopwatch_value),    // Display the stopwatch value
        .seg(seg),                   // 7-segment display segments (a-g)
        .an(an)                      // 7-segment display anodes (digits)
    );

endmodule*/
