`timescale 1ns / 1ps

module top_level_tb;
    ///////////////////////////////////////////////////////
    // Testbench for stopwatch
    ///////////////////////////////////////////////////////
   /* reg clk;                // 100 MHz clock
    reg rst;                // Reset signal
    reg button0;            // Start/Stop button
    reg button1;            // Reset button
    wire [6:0] seg;         // 7-segment display segments
    wire [3:0] an;          // 7-segment display anodes

    // Instantiate the top-level module
    top_level uut (
        .clk(clk),
        .rst(rst),
        .button0(button0),
        .button1(button1),
        .seg(seg),
        .an(an)
    );

    // Clock generation: 100 MHz clock (10 ns period)
    always #5 clk = ~clk;

    initial begin
        // Initialize signals
        clk = 0;
        rst = 1;
        button0 = 0;
        button1 = 0;

        // Scenario 1: Reset the system and start the stopwatch
        #100;                    // Wait 100 ns for initial reset
        rst = 0;                 // Release reset
        #10_000_000;             // Wait 10 ms

        button0 = 1;             // Press Start/Stop button
        #20_000_000;             // Hold for 20 ms
        button0 = 0;             // Release Start/Stop
        repeat(1000) #100_000_000;            // Wait for 100 ms to observe counting

        // Scenario 2: Stop the stopwatch
        button0 = 1;             // Press Start/Stop button
        #20_000_000;             // Hold for 20 ms
        button0 = 0;             // Release Start/Stop
        #100_000_000;            // Wait for 100 ms to observe stopped state

        // Scenario 3: Reset the stopwatch while stopped
        button1 = 1;             // Press Reset button
        #20_000_000;             // Hold for 20 ms
        button1 = 0;             // Release Reset
        #100_000_000;            // Wait for 100 ms to observe reset state

        // Scenario 4: Start the stopwatch again
        button0 = 1;             // Press Start/Stop button
        #20_000_000;             // Hold for 20 ms
        button0 = 0;             // Release Start/Stop
        #200_000_000;            // Wait for 200 ms to observe counting

        // Scenario 5: Stop and Reset in sequence
        button0 = 1;             // Press Start/Stop button (stop)
        #20_000_000;             // Hold for 20 ms
        button0 = 0;             // Release Start/Stop
        #50_000_000;             // Wait for 50 ms

        button1 = 1;             // Press Reset button
        #20_000_000;             // Hold for 20 ms
        button1 = 0;             // Release Reset
        #50_000_000;             // Wait for 50 ms to observe reset state

        // Scenario 6: Rapid pressing of Start/Stop
        button0 = 1;             // Press Start/Stop button
        #10_000_000;             // Hold for 10 ms
        button0 = 0;             // Release Start/Stop
        #20_000_000;             // Wait for 20 ms

        button0 = 1;             // Press Start/Stop again
        #10_000_000;             // Hold for 10 ms
        button0 = 0;             // Release Start/Stop
        #50_000_000;             // Observe behavior with rapid presses

        // Finish simulation
        #200_000_000;
        $finish;
    end*/
    

    ///////////////////////////////////////////////////////
    // Testbench for digital clock
    ///////////////////////////////////////////////////////
    // Inputs
/*    reg clk;
    reg rst;
    reg button0;
    reg button1;
    reg set_time_enable;
    reg [5:0] set_hours;
    reg [5:0] set_minutes;
    reg [5:0] set_seconds;
    reg [4:0] timezone_select;
    
    // Outputs
    wire [6:0] seg;
    wire [3:0] an;
    wire is_pm;
    
    // Instantiate the Device Under Test (DUT)
    top_level dut (
        .clk(clk),
        .rst(rst),
        .button0(button0),
        .button1(button1),
        .set_time_enable(set_time_enable),
        .set_hours(set_hours),
        .set_minutes(set_minutes),
        .set_seconds(set_seconds),
        .timezone_select(timezone_select),
        .seg(seg),
        .an(an),
        .is_pm(is_pm)
    );
        
    // Clock generation: 100 MHz clock (10 ns period)
    always #5 clk = ~clk;
    
    // Testbench variables
    initial begin
        // Initialize inputs
        clk = 0;
        rst = 0;
        button0 = 0;
        button1 = 0;
        set_time_enable = 0;
        set_hours = 0;
        set_minutes = 0;
        set_seconds = 0;
        timezone_select = 0;
    
        // Apply Reset
        rst = 1; // Activate reset
        #20000000;  // Hold reset for 20 ms
        rst = 0; // Deactivate reset
    
        // Test case: Set hours, minutes, and seconds
        #10000000; // Wait for 10 ms
        set_hours = 6'd12;      // Set 12 hours
        set_minutes = 6'd59;    // Set 34 minutes
        set_seconds = 6'd59;    // Set 56 seconds
        set_time_enable = 1;
        #10000000; // Hold for 10 ms to simulate button press
        set_time_enable = 0;
           
        // Test case: Change timezone selection
        #20000000; // Wait for 20 ms
        timezone_select = 5'd3; // Select timezone index 3
        #20000000; // Hold for 20 ms
        timezone_select = 5'd7; // Select timezone index 7
        #20000000; // Hold for 20 ms
        
        // Test case: Check all timezone selections (from 0 to 31)
        for (timezone_select = 5'd0; timezone_select <= 5'd12; timezone_select = timezone_select + 1) begin
            #20000000; // Wait for 10 ms to allow the system to react
            $display("Testing timezone: %d", timezone_select);
        end
    
        // Test case: Simulate start/stop functionality
        #10000000;
        button0 = 1; // Simulate start
        #10000000; // Hold for 10 ms to simulate button press
        button0 = 0;
    
        // Test case: Reset via button1
        #10000000;
        button1 = 1; // Simulate reset
        #10000000; // Hold for 10 ms to simulate button press
        button1 = 0;
    
        // End simulation
        #100000000;
        $finish;
    end
    
    // Monitor outputs for debugging
    initial begin
        $monitor("Time: %0t | rst: %b | set_time_enable: %b | set_hours: %d | set_minutes: %d | set_seconds: %d | timezone_select: %d | seg: %b | an: %b",
                 $time, rst, set_time_enable, set_hours, set_minutes, set_seconds, timezone_select, seg, an);
    end*/
    
    ///////////////////////////////////////////////////////
    // Testbench for integrated top-level module
    ///////////////////////////////////////////////////////
    // Inputs

    reg clk;
    reg rst;
    reg button0;
    reg button1;
    reg button2;
    reg select_btn; // Button to select hour, minute, or second
    reg increment_btn; // Button to increment selected unit of alarm time
    reg toggle_alarm; // Button to toggle alarm on/off
    reg set_time_enable;
    reg [5:0] set_hours;
    reg [5:0] set_minutes;
    reg [5:0] set_seconds;
    reg [4:0] timezone_select;

    // Outputs
    wire [6:0] seg;
    wire [3:0] an;
    wire is_pm;
    wire alarm_led;

    // Instantiate the Device Under Test (DUT)
    top_level dut (
        .clk(clk),
        .rst(rst),
        .button0(button0),
        .button1(button1),
        .button2(button2),
        .set_time_enable(set_time_enable),
        .set_hours(set_hours),
        .set_minutes(set_minutes),
        .set_seconds(set_seconds),
        .timezone_select(timezone_select),
        .seg(seg),
        .an(an),
        .is_pm(is_pm),
        .alarm_led(alarm_led)
    );

    // Clock generation: 100 MHz clock (10 ns period)
    always #5 clk = ~clk;

    // Testbench variables
    initial begin
        // Initialize inputs
        clk = 0;
        rst = 0;
        button0 = 0;
        button1 = 0;
        button2 = 0;
        set_time_enable = 0;
        select_btn = 0;
        increment_btn = 0; 
        toggle_alarm = 0; 
        set_hours = 0;
        set_minutes = 0;
        set_seconds = 0;
        timezone_select = 0;

        // Apply Reset
        rst = 1; // Activate reset
        #20000000;  // Hold reset for 20 ms
        rst = 0; // Deactivate reset

        // Test case: Set hours, minutes, and seconds
        #10000000;
        set_hours = 6'd12; // Set 12 hours
        set_minutes = 6'd59;
        set_seconds = 6'd59;
        set_time_enable = 1;
        #10000000;
        set_time_enable = 0;

        // Test case: Change timezone selection
        #20000000;
        timezone_select = 5'd3;
        #20000000;
        timezone_select = 5'd7;
        #20000000;

        // Test case: Cycle through timezone selections
        for (timezone_select = 5'd0; timezone_select <= 5'd2; timezone_select = timezone_select + 1) begin
            #20000000;
            $display("Testing timezone: %d", timezone_select);
        end

        // Test case: Switching states using button2
        #20000000;
        $display("Switching to STOPWATCH_STATE");
        button2 = 1;
        #20000000;
        button2 = 0;
           
        // Test case: Start/Stop functionality in Stopwatch mode
        #20000000;
        button0 = 1; // Start stopwatch
        #20000000;
        button0 = 0;
 
        #20000000;  // running

        // Test case: Reset via button1
        #20000000;
        button1 = 1; // Reset stopwatch
        #20000000;
        button1 = 0;

        #20000000;   // running
        
        button0 = 1; // Stop stopwatch
        #20000000;
        button0 = 0;
        
        #20000000;
        $display("Switching to ALARM_STATE");
        button2 = 1;
        #20000000;
        button2 = 0;
        
        // Set initial time on the digital clock
        set_time_enable = 1; // Enable time setting
        set_hours = 6'd3;   // Set initial time: 12:00:00
        set_minutes = 6'd20;
        set_seconds = 6'd5;
        #1000; // Hold for 1 ms
        set_time_enable = 0; // Disable time setting

        // Test case: Set Alarm Time (Hour, Minute, Second) and Toggle Alarm
        // Step 1: Increment hours (select_btn = 0)
        repeat(3) begin // Simulate pressing increment button 3 times
            increment_btn = 1; // Press the button
            #1000; // Wait for debounce time
            increment_btn = 0; // Release the button
            #1000; // Wait before the next press
        end

        // Step 2: Increment minutes
        #1000; // Wait for 1 ms
        select_btn = 1; // Select minute for alarm
        #1000; // Wait for 1 ms
        select_btn = 0; // Stop selecting minute
        repeat(23) begin // Simulate pressing increment button 15 times
            increment_btn = 1; // Press the button
            #1000; // Wait for debounce time
            increment_btn = 0; // Release the button
            #1000; // Wait before the next press
        end

        // Step 3: Increment seconds
        #1000; // Wait for 1 ms
        select_btn = 1; // Select second for alarm
        #1000; // Wait for 1 ms
        select_btn = 0; // Stop selecting second
        repeat(45) begin // Simulate pressing increment button 45 times
            increment_btn = 1; // Press the button
            #1000; // Wait for debounce time
            increment_btn = 0; // Release the button
            #1000; // Wait before the next press
        end

        // Step 4: Finalize Alarm Setting and Toggle Alarm ON
        toggle_alarm = 1; // Turn the alarm ON
        #1000; // Wait for 1 ms
        toggle_alarm = 0; // Release toggle button

        // Step 5: Simulate time passing and check alarm state
        repeat(1000) #100000000; // Wait (simulate real-time clock updates)

        // Step 6: Toggle Alarm OFF
        toggle_alarm = 1; // Turn the alarm OFF
        #1000; // Wait for 1 ms
        toggle_alarm = 0; // Release toggle button

        repeat(5) #1000; // Simulate additional time passing
        
        #20000000;
        $display("Switching back to CLOCK_STATE");
        button2 = 1;
        #20000000;
        button2 = 0;
        
        #20000000;
        $display("Switching to CONVERT_STATE");
        button2 = 1;
        #20000000;
        button2 = 0;

        // End simulation
        #10000000;
        $finish;
    end

    // Monitor outputs for debugging
    initial begin
        $monitor("Time: %0t | rst: %b | state: %b | set_time_enable: %b | set_hours: %d | set_minutes: %d | set_seconds: %d | timezone_select: %d | seg: %b | an: %b",
                 $time, rst, dut.current_state, set_time_enable, set_hours, set_minutes, set_seconds, timezone_select, seg, an);
    end

endmodule
