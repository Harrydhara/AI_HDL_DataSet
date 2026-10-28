`timescale 1ns/1ps

module top_level_tb;

    // Testbench signals
    reg         clk;          // 100 MHz clock
    reg         rst;          // Reset signal
    reg         button0;      // Start/Stop Stopwatch & Dismiss Alarm
    reg         button1;      // Reset & Increment Alarm Hour
    reg         button2;      // Set Time / Set Alarm & Increment Alarm Minute
    reg         button3;      // Mode Change

    // Instead of set_time[15:0], we have:
    reg  [7:0]  set_time_data; // 8-bit BCD data
    reg         set_time_phase; // 0 => minutes, 1 => hours

    reg         enable_alarm; // Enable/Disable alarm
    
    wire        alarm_led;     // Alarm LED
    wire [15:0] display_value;
    wire [1:0]  state;
    wire        clk_slow;
    
    // Instantiate top_level (with set_time_data, set_time_phase)
    top_level uut (
        .clk            (clk),
        .rst            (rst),
        .button0        (button0),
        .button1        (button1),
        .button2        (button2),
        .button3        (button3),
        .set_time_data  (set_time_data),
        .set_time_phase (set_time_phase),
        .enable_alarm   (enable_alarm),
        .alarm_led      (alarm_led),
        .display_value  (display_value),
        .state          (state),
        .clk_slow       (clk_slow)
    );
    
    // 100 MHz clock => 10 ns period
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Main test stimulus with additional test cases
    initial begin
        // -------------------------------
        // Initialization & Reset
        // -------------------------------
        rst             = 1;
        button0         = 0;
        button1         = 0;
        button2         = 0;
        button3         = 0;
        set_time_data   = 8'h00;
        set_time_phase  = 1'b0;
        enable_alarm    = 0;
        #100000;  // 100,000 ns (100 µs)
        rst = 0;        
        #1000;    // 1,000 ns delay
        
        // -------------------------------
        // Test Case 1: Wrong Password Sequence
        // (Expected: auth_valid should remain LOW)
        // -------------------------------
        $display("Test Case 1: Wrong password sequence");
        // Simulate incorrect sequence: instead of 3-2-3-0, we do: 2-3-0-3
        button2 = 1; #50000; button2 = 0;  // Press button2 -> "2"
        #10000;
        button3 = 1; #50000; button3 = 0;  // Press button3 -> "3"
        #10000;
        button0 = 1; #50000; button0 = 0;  // Press button0 -> "0"
        #10000;
        button3 = 1; #50000; button3 = 0;  // Press button3 -> "3"
        #10000;
        $display("Authorization (should be 0): auth_valid = %b", uut.auth_valid);
        
        #10000;
        
        // -------------------------------
        // Test Case 2: Correct Password Sequence
        // (Expected: auth_valid should become HIGH)
        // -------------------------------
        $display("Test Case 2: Correct password sequence");
        button3 = 1; #50000; button3 = 0;  // Press button3 -> "3"
        #10000;
        button2 = 1; #50000; button2 = 0;  // Press button2 -> "2"
        #10000;
        button3 = 1; #50000; button3 = 0;  // Press button3 -> "3"
        #10000;
        button0 = 1; #50000; button0 = 0;  // Press button0 -> "0"
        #10000;
        $display("Authorization (should be 1): auth_valid = %b", uut.auth_valid);
        
        // -------------------------------
        // Test Case 3: Let the clock run (Clock Mode)
        // -------------------------------
        #2000000; // 2,000,000 ns (2 ms) simulating a day
        
        // -------------------------------
        // Test Case 4: Stopwatch Mode
        // -------------------------------
        $display("Test Case 4: Stopwatch mode");
        button3 = 1; #15000; button3 = 0; // Switch to Stopwatch Mode
        #10000;
        // Start stopwatch
        button0 = 1; #15000; button0 = 0;
        // Simulate running for 10 minutes (delay scaled in simulation)
        #1000000;
        // Stop stopwatch
        button0 = 1; #15000; button0 = 0;
        
        // -------------------------------
        // Test Case 5: Convert Mode (12h/24h)
        // -------------------------------
        $display("Test Case 5: Convert mode");
        #100000; // Delay 100,000 ns
        button3 = 1; #15000; button3 = 0; // Switch to Convert Mode
        #10000;
        // Toggle convert: press button2, delay, then press button2 again
        button2 = 1; #15000; button2 = 0;
        #1000000;
        button2 = 1; #15000; button2 = 0;
        #1000000;
        
        // -------------------------------
        // Test Case 6: Alarm Mode & Alarm LED Activation
        // -------------------------------
        $display("Test Case 6: Alarm mode with alarm LED activation");
        #100000; // Delay 100,000 ns
        button3 = 1; #15000; button3 = 0; // Switch to Alarm Mode
        #5000;
        // Set alarm hour (press button1)
        button1 = 1; #15000; button1 = 0;
        #5000;
        // Set alarm minute (press button2)
        button2 = 1; #15000; button2 = 0;
        #5000;
        // Enable alarm
        enable_alarm = 1;
        // Simulate alarm condition being met
        #5000000;
        $display("Alarm LED (should be ON): %b", alarm_led);
        // Dismiss alarm
        button0 = 1; #150000; button0 = 0;
        #5000;
        $display("Alarm LED (should be OFF): %b", alarm_led);
        
        // -------------------------------
        // Additional code: Switch back to Clock Mode after setting alarm
        // -------------------------------
        $display("Switching back to Clock Mode after setting alarm");
        // State cycle: CLOCK_MODE (00) -> STOPWATCH_MODE (01) -> CONVERT_MODE (10) -> ALARM_MODE (11) -> CLOCK_MODE (00)
        // // If in ALARM_MODE, one press of button3 switches back to CLOCK_MODE.
        button3 = 1; #15000; button3 = 0;
        #100000;
        $display("State (should be CLOCK_MODE): %b", state);
        
        $stop;
    end

endmodule
