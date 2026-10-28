`timescale 1ns/1ps

module top_level(
    input wire clk,          // 100 MHz clock input
    input wire rst,          // Reset signal

    input wire button0,      // Start/Stop Stopwatch & Dismiss Alarm
    input wire button1,      // Reset & Increment Alarm Hour
    input wire button2,      // Set Time / Set Alarm & Increment Alarm Minute
    input wire button3,      // Change Mode (Switch between modes)

    // --- Gi?m IO: 4 bit BCD + 2 bit phase ---
    input wire [3:0] set_time_data, // 4 bits BCD (0-9) cho nibble
    input wire [1:0] set_time_phase, // 00->minL, 01->minH, 10->hrL, 11->hrH

    input wire enable_alarm,  // Enable/Disable alarm
    output wire alarm_led,    // LED for alarm
    output reg [15:0] display_value, // Data to display on 7-seg (HH:MM)
    output reg [1:0] state,          // Switch mode
    output wire clk_slow,          // Divided clock
    // Outputs for Seven-Segment Display module:
    output wire [6:0] seg,         // Segment display signals
    output wire [3:0] an           // Digit enable signals
);

    // Instantiate auth_module
    wire auth_valid;

    // ----------------------------------------------------------
    // Tín hi?u trung gian
    // ----------------------------------------------------------
    wire button0_db, button1_db, button2_db, button3_db; // Debounced buttons
    wire [15:0] current_time, converted_time, time_out;
    wire [7:0] alarm_hour, alarm_minute;
    reg [15:0] set_time_reg; // Register to store HH:MM (BCD)

    wire clk_slow_auth = clk_slow && auth_valid;
    
    // ----------------------------------------------------------
    // 1) Clock Divider (generate clk_slow)
    // ----------------------------------------------------------
    clock_divider clk_div(
        .clk_in(clk),
        .reset(rst),
        .clk_out(clk_slow)
    );

    // ----------------------------------------------------------
    // 2) Button Debouncers
    // ----------------------------------------------------------
    buttonDebouncer db_start(
        .clk(clk_slow),
        .reset(rst),
        .button_in(button0),
        .button_out(button0_db)
    );

    buttonDebouncer db_reset(
        .clk(clk_slow),
        .reset(rst),
        .button_in(button1),
        .button_out(button1_db)
    );

    buttonDebouncer db_set_time(
        .clk(clk_slow),
        .reset(rst),
        .button_in(button2),
        .button_out(button2_db)
    );

    buttonDebouncer db_mode(
        .clk(clk_slow),
        .reset(rst),
        .button_in(button3),
        .button_out(button3_db)
    );

    // ----------------------------------------------------------
    // 2.1) Edge detection for button3
    // ----------------------------------------------------------
    reg button3_db_prev;
    wire button3_edge;
    
    always @(posedge clk_slow or posedge rst) begin
        if(rst)
            button3_db_prev <= 1'b0;
        else
            button3_db_prev <= button3_db;
    end
    
    // Detect rising edge: when current button3_db = 1 and previous value = 0
    assign button3_edge = button3_db & ~button3_db_prev;
    
    // ----------------------------------------------------------
    // 3) State Machine for mode switching with edge detection for button3
    // ----------------------------------------------------------
    localparam CLOCK_MODE     = 2'b00;
    localparam STOPWATCH_MODE = 2'b01;
    localparam CONVERT_MODE   = 2'b10;
    localparam ALARM_MODE     = 2'b11;
    
    always @(posedge clk_slow or posedge rst) begin
        if (rst)
            state <= CLOCK_MODE; // M?c ??nh
        else if (auth_valid) begin
            // Switch state only on rising edge of button3
            if(button3_edge) begin
                case (state)
                    CLOCK_MODE:     state <= STOPWATCH_MODE;
                    STOPWATCH_MODE: state <= CONVERT_MODE;
                    CONVERT_MODE:   state <= ALARM_MODE;
                    ALARM_MODE:     state <= CLOCK_MODE;
                    default:        state <= CLOCK_MODE;
                endcase
            end
        end
    end

    // ----------------------------------------------------------
    // 4) Write HH:MM (BCD) data to set_time_reg only in CLOCK_MODE
    // ----------------------------------------------------------
    always @(posedge button2_db or posedge rst) begin
        if (rst)
            set_time_reg <= 16'h0000;
        else if (state == CLOCK_MODE) begin
            case (set_time_phase)
                2'b00: set_time_reg[3:0]  <= set_time_data;  // low nibble of minutes
                2'b01: set_time_reg[7:4]  <= set_time_data;  // high nibble of minutes
                2'b10: set_time_reg[11:8] <= set_time_data;  // low nibble of hours
                2'b11: set_time_reg[15:12] <= set_time_data;  // high nibble of hours
                default: ;
            endcase
        end
    end

    // ----------------------------------------------------------
    // 5) Assign button signals to modules based on mode
    // ----------------------------------------------------------
    // Stopwatch operates only in STOPWATCH_MODE
    wire sw_start_stop = (state == STOPWATCH_MODE) ? button0_db : 1'b0;
    wire sw_reset      = (state == STOPWATCH_MODE) ? button1_db : 1'b0;
    
    // Clock module operates only in CLOCK_MODE
    wire clk_set_time_en = (state == CLOCK_MODE) ? button2_db : 1'b0;
    
    // Convert module operates only in CONVERT_MODE
    wire conv_convert_mode = (state == CONVERT_MODE) ? button2_db : 1'b0;
    
    // Alarm module operates only in ALARM_MODE
    wire alarm_button1 = (state == ALARM_MODE) ? button2_db : 1'b0;
    wire alarm_button2 = (state == ALARM_MODE) ? button1_db : 1'b0;
    wire alarm_dismiss = (state == ALARM_MODE) ? button0_db : 1'b0;

    // ----------------------------------------------------------
    // 6) Stopwatch Module
    // ----------------------------------------------------------
    stopwatch sw(
        .clk(clk_slow_auth),
        .rst(rst),
        .start_stop(sw_start_stop),
        .reset_button(sw_reset),
        .time_out(time_out)
    );

    // ----------------------------------------------------------
    // 7) BCD Clock Module (24h)
    // ----------------------------------------------------------
    clock_timezone clock_module(
        .clk(clk_slow_auth),
        .rst(rst),
        .set_time_en(clk_set_time_en),
        .set_time(set_time_reg), // 16-bit BCD HH:MM
        .current_time(current_time)
    );

    // ----------------------------------------------------------
    // 8) Convert 24h <-> 12h (based on request)
    // ----------------------------------------------------------
    convert_12_to_24 converter(
        .clk(clk_slow_auth),
        .rst(rst),
        .convert_mode(conv_convert_mode),
        .time_in(current_time),
        .time_out(converted_time)
    );

    // ----------------------------------------------------------
    // 9) Alarm Clock
    // ----------------------------------------------------------
    alarm_clock alarm(
        .clk(clk_slow_auth),
        .rst(rst),
        .current_time(current_time),
        .button1(alarm_button1), // Depends on your button mapping
        .button2(alarm_button2), // Depends on your button mapping
        .alarm_hour(alarm_hour),
        .alarm_minute(alarm_minute),
        .enable_alarm(enable_alarm),
        .dismiss_button(alarm_dismiss),
        .alarm_led(alarm_led)
    );

    // ----------------------------------------------------------
    // 10) Combine display data (display_value)
    // ----------------------------------------------------------
    always @(*) begin
        case (state)
            CLOCK_MODE:     display_value = current_time;
            STOPWATCH_MODE: display_value = time_out;
            CONVERT_MODE:   display_value = converted_time;
            ALARM_MODE:     display_value = {alarm_hour, alarm_minute};
            default:        display_value = 16'h0000;
        endcase
    end

    // ----------------------------------------------------------
    // 11) Seven-Segment Display
    // ----------------------------------------------------------
    seven_segment_display display(
        .clk(clk_slow_auth),
        .rst(rst),
        .number(display_value),
        .seg(seg),
        .an(an)
    );

    // ----------------------------------------------------------
    // 12) Auth Module
    // ----------------------------------------------------------
    auth_module auth (
        .clk(clk_slow),
        .rst(rst),
        .button0(button0_db),
        .button1(button1_db),
        .button2(button2_db),
        .button3(button3_db),
        .auth_valid(auth_valid)
    );  

endmodule
