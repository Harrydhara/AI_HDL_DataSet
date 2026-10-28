`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/17/2024 08:18:58 PM
// Design Name: 
// Module Name: top_level
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Updated with state machine and integrated clock, convert_12_to_24,
// and alarm modules while retaining stopwatch functionality.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.02 - File Updated
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module top_level(
    input wire clk_100mhz,  // 100 MHz clock input
    input wire reset,       // Active-high reset
    input wire button0,     // Button 0 input for state control
    input wire button1,     // Button 1 input
    input wire button2,     // Button 2 input
    input wire button3,     // Button 3 input
    output wire [6:0] seg,  // Seven-segment display output (a-g)
    output wire [3:0] an,   // Seven-segment anode control
    output wire alarm_led   // Alarm LED output
);

    // Internal signals
    wire slow_clk;            // Slow clock for debouncing and display multiplexing
    wire debounced_button0;   // Debounced signal for button 0
    wire debounced_button1;   // Debounced signal for button 1
    wire debounced_button2;   // Debounced signal for button 2
    wire debounced_button3;   // Debounced signal for button 3
    wire [15:0] display_data; // Data to display on the seven-segment display
    wire [5:0] current_hh, current_mm, current_ss; // Current time signals
    wire [5:0] alarm_hh, alarm_mm, alarm_ss;       // Alarm time signals
    wire [5:0] hh_24, mm_24;                       // 24-hour format time signals
    wire alarm_active;                             // Alarm active signal

    // State machine states
    localparam STATE_CLOCK    = 2'b00;
    localparam STATE_STOPWATCH = 2'b01;
    localparam STATE_ALARM    = 2'b10;

    reg [1:0] current_state, next_state;

    // Clock Divider Instance
    clock_divider #( 
        .DIV_FACTOR(100000)   // Adjust for a 1 kHz clock
    ) clk_div (
        .clk_in(clk_100mhz),
        .reset(reset),
        .clk_out(slow_clk)
    );

    // Button Debouncer Instances
    buttonDebouncer db0 (
        .clk(slow_clk),
        .reset(reset),
        .button_in(button0),
        .button_out(debounced_button0)
    );

    buttonDebouncer db1 (
        .clk(slow_clk),
        .reset(reset),
        .button_in(button1),
        .button_out(debounced_button1)
    );

    buttonDebouncer db2 (
        .clk(slow_clk),
        .reset(reset),
        .button_in(button2),
        .button_out(debounced_button2)
    );

    buttonDebouncer db3 (
        .clk(slow_clk),
        .reset(reset),
        .button_in(button3),
        .button_out(debounced_button3)
    );

    // Clock Module Instance
    clock_timezone clock_inst (
        .clk(slow_clk),
        .reset(reset),
        .hh(current_hh),
        .mm(current_mm),
        .ss(current_ss)
    );
    
    seven_segment_display ssd (
        .clk(slow_clk),
        .reset(reset),
        .data(display_data),
        .seg(seg),
        .an(an)
    );

    // Convert 12-hour to 24-hour Module Instance
    convert_12_to_24 convert_inst (
        .hh_12(current_hh),
        .mm_12(current_mm),
        .is_pm(1'b0),  // Placeholder: Add PM/AM control logic if needed
        .hh_24(hh_24),
        .mm_24(mm_24)
    );

    // Alarm Module Instance
    alarm alarm_inst (
        .clk(slow_clk),
        .reset(reset),
        .current_hh(hh_24),
        .current_mm(mm_24),
        .current_ss(current_ss),
        .btn_inc_hh(debounced_button1),
        .btn_inc_mm(debounced_button2),
        .btn_inc_ss(debounced_button3),
        .alarm_enable(1'b1),  // Placeholder: Add alarm enable control if needed
        .alarm_active(alarm_active),
        .alarm_led(alarm_led)
    );

    // Stopwatch Module Instance
    stopwatch sw (
        .clk(slow_clk),
        .reset(reset),
        .start_stop(debounced_button0),
        .reset_time(debounced_button1),
        .time_data(display_data)
    );

    // State Machine Logic
    always @(posedge slow_clk or posedge reset) begin
        if (reset) begin
            current_state <= STATE_CLOCK;
        end else begin
            current_state <= next_state;
        end
    end

    always @(*) begin
        case (current_state)
            STATE_CLOCK: begin
                if (debounced_button0) next_state = STATE_STOPWATCH;
                else next_state = STATE_CLOCK;
            end

            STATE_STOPWATCH: begin
                if (debounced_button0) next_state = STATE_ALARM;
                else next_state = STATE_STOPWATCH;
            end

            STATE_ALARM: begin
                if (debounced_button0) next_state = STATE_CLOCK;
                else next_state = STATE_ALARM;
            end

            default: next_state = STATE_CLOCK;
        endcase
    end

endmodule

