// stopwatch_top.v - Optimized Top-level module for reduced power consumption
module stopwatch_top(
    input  wire CLK,            // system clock (e.g., 50 MHz)
    input  wire BTN_MODE,       // mode select button
    input  wire BTN_START_STOP, // stopwatch start/stop button
    input  wire BTN_RESET_SW,   // stopwatch reset button
    input  wire BTN_SET_ALARM,  // set alarm time button
    input  wire BTN_ALARM_ACK,  // acknowledge alarm button
    input  wire [4:0] SW_ALARM_H, // FIXED: alarm hour (0-23) changed to 5 bits
    input  wire [5:0] SW_ALARM_M, // alarm minute (0-59)
    input  wire [1:0] SW_ZONE,  // time zone selection
    input  wire SW_12HR,        // 12-hour mode (1) / 24-hour mode (0)
    input  wire SW_ALARM_ON,    // alarm enable (1) or disable (0)
    input  wire [3:0] SW_UNLOCK_CODE, // security code input
    input  wire BTN_UNLOCK,     // button to attempt unlock
    output wire [3:0] AN,       // seven-seg digit enable (active low)
    output wire A, B, C, D, E, F, G, DP, // segment outputs (active low)
    output wire ALARM_LED,      // alarm indicator LED
    output wire PM_LED,         // PM indicator LED
    output wire LOCKED_LED      // security locked indicator
);

    // Internal signals
    wire clk_1hz, clk_10hz;
    wire btn_mode_db, btn_start_db, btn_reset_db, btn_set_alarm_db, btn_alarm_ack_db, btn_unlock_db;
    wire unlocked;

    // **Clock Gating**: Disable clock to unused parts to save power
    wire enable_clk;
    assign enable_clk = (mode_is_stopwatch) ? CLK : 1'b0; // Only enable clock in stopwatch mode

    // Optimized clock divider with gating
    clock_divider #(.DIVISOR(50000000)) div1Hz (
        .clk_in(enable_clk), .reset(1'b0), .clk_out(clk_1hz)
    );

    clock_divider #(.DIVISOR(5000000)) div10Hz (
        .clk_in(enable_clk), .reset(1'b0), .clk_out(clk_10hz)
    );

    // Debounce button inputs (Optimized: Lower switching activity)
    button_debouncer db_mode(.clk(enable_clk), .reset(1'b0), .btn_in(BTN_MODE), .btn_clean(btn_mode_db));
    button_debouncer db_start(.clk(enable_clk), .reset(1'b0), .btn_in(BTN_START_STOP), .btn_clean(btn_start_db));
    button_debouncer db_resetsw(.clk(enable_clk), .reset(1'b0), .btn_in(BTN_RESET_SW), .btn_clean(btn_reset_db));

    // Security module (Disable checking unless unlock button is pressed)
    wire security_clk = btn_unlock_db ? enable_clk : 1'b0;
    security_module security(
        .clk(security_clk),
        .reset(1'b0),
        .code_input(SW_UNLOCK_CODE),
        .unlock_pulse(btn_unlock_db),
        .unlocked(unlocked)
    );
    assign LOCKED_LED = ~unlocked;

    // Digital clock (Disable when in stopwatch mode)
    wire [4:0] base_hours;
    wire [5:0] base_minutes, base_seconds;
    wire clock_enable = ~mode_is_stopwatch;
    
    digital_clock rtc_clock(
        .clk_sec(clk_1hz & clock_enable),
        .reset(~unlocked),
        .load(1'b0),
        .load_h(5'd0), .load_m(6'd0), .load_s(6'd0),
        .hours(base_hours), .minutes(base_minutes), .seconds(base_seconds)
    );

    // Mode selection logic
    reg mode_is_stopwatch = 0;
    always @(posedge enable_clk) begin
        if (~unlocked)
            mode_is_stopwatch <= 0;
        else if (btn_mode_db)
            mode_is_stopwatch <= ~mode_is_stopwatch;
    end

    // Display Multiplexing - Reduce toggling by updating only when needed
    reg [3:0] disp0, disp1, disp2, disp3;
    wire [3:0] sw_min, sw_sec_tens, sw_sec_ones, sw_tenths;
    always @(posedge enable_clk) begin
        if (mode_is_stopwatch) begin
            disp3 <= sw_min;
            disp2 <= sw_sec_tens;
            disp1 <= sw_sec_ones;
            disp0 <= sw_tenths;
        end else begin
            disp3 <= base_hours / 10;
            disp2 <= base_hours % 10;
            disp1 <= base_minutes / 10;
            disp0 <= base_minutes % 10;
        end
    end

endmodule
