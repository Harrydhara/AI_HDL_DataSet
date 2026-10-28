`timescale 1ns / 1ps

module testbench_STATE_set_btns;

    // Clock and reset
    reg clk_100MHz;  // 100 MHz clock
    reg rst;         // Reset signal

    // Button inputs
    reg BTN_U;       // Up button
    reg BTN_D;       // Down button
    reg BTN_C;       // Center button for STATE change
    reg BTN_L;       // Left button increase CLOCK and ALARM set Hours
    reg BTN_R;       // Right button increase CLOCK and ALARM set Minutes

    // Switch inputs
    reg SW_0;        // Alarm ON_OFF select switch
    reg SW_2;        // Mode select for 12-hour/24-hour
    reg SW_4;        // Mode selector for multiplexer input and STATE selection
    reg SW_8;        // Mode selector for multiplexer input and STATE selection
    wire state_mode_enable_alarm;
    reg debug_clock; // New for the accellerated testing of the clock alarm funct

    // Outputs
    wire [6:0] IO_SSEG;       // 7-segment display segments
    wire [3:0] IO_SSEG_SEL;   // 7-segment digit selector
    wire LD0, LD1, LD2, LD3;  // ✅ Declare LED outputs as wires

    // Instantiate the top_level module
    top_level uut (
        .clk(clk_100MHz),
        .rst(rst),
        .BTN_U(BTN_U),
        .BTN_D(BTN_D),
        .BTN_C(BTN_C),
        .BTN_L(BTN_L),
        .BTN_R(BTN_R),
        .SW_0(SW_0),  // Alarm ON_OFF select switch
        .SW_2(SW_2),  // Mode select for 12-hour/24-hour
        .SW_4(SW_4),  // Mode selector for multiplexer input and STATE selection
        .SW_8(SW_8),  // Mode selector for multiplexer input and STATE selection
        .debug_clock(debug_clock),  // ✅ Connect debug_clock here
        .IO_SSEG(IO_SSEG),
        .IO_SSEG_SEL(IO_SSEG_SEL),
        .LD0(LD0),  // ✅ ALARM Mode Active LED
        .LD1(LD1),  // ✅ Alarm Trigger Flash LED
        .LD2(LD2),  // ✅ AM/PM Indicator LED
        .LD3(LD3)   // ✅ Seconds Indicator LED
    );

    // Clock generation (100 MHz)
    initial clk_100MHz = 0;
    always #5 clk_100MHz = ~clk_100MHz; // Toggle every 5 ns (100 MHz clock)

    // Test sequence
    initial begin
        // Initialize inputs
        rst = 1;
        BTN_U = 0;
        BTN_D = 0;
        BTN_C = 0;
        BTN_L = 0;
        BTN_R = 0;
        SW_0 = 0; // Alarm ON_OFF select switch always start at ALARM OFF
        SW_2 = 0; // Mode select for 12-hour/24-hour always start at 24 hour mode
        SW_4 = 0; // high equals stopwatch always start at CLOCK STATE
        SW_8 = 0; // high equals alarm mode always start at CLOCK STATE
        debug_clock = 0;  // ✅ Ensure it starts at a known state

        // Apply reset
        #100 rst = 0;
        //pretest pause that refreshes
        #30000000;
        #30000000;

        $display("===========================================");
        $display("  Pima Community College Team Testbench");
        $display("  FPGA Clock & Timezone Management System");
        $display("===========================================");
        $display("  Project: Basys3 FPGA Clock with Timezone Adjustments");
        $display("  Developed by: Pima Community College FPGA Team");
        $display("  Features:");
        $display("    ✅ Real-time clock with 1Hz updates");
        $display("    ✅ Manual time setting modes for CLOCK and ALARM");
        $display("    ✅ Adjustable timezone offsets (-12 to +12)");
        $display("    ✅ Long-press button detection for Clock&Alarm set minutes - awsome AF");
        $display("    ✅ Debounced button and switch inputs for reliable toggling");
        $display("    ✅ On board LED indicators for seconds, Alarm Trigger and 24_12 mode");
        $display("    ✅ Debug_clock for accellerated Alarm Trigger Test");
        $display("-------------------------------------------");
        $display("  Running Automated Testbench...please fasten seat belts");
        $display("===========================================");
        
        // Step 1: Enter CLOCK STATE Mode (Toggle BTN_C)
        // attention one assertions of BTN_C changes state with SW_8 and SW_4
        // BUT it also configures for CLOCK set mode
        #30000000 BTN_C = 1; #30000000 BTN_C = 0;// cycles into state 0 allows incr clock
        #30000000;// slight pause
        $display("Step 1: Current state should be CLOCK (00)"); // Display the current state
        $display("Step 1: Current state is %b", uut.current_state); // Display the current state
        $display("Step 1: Current set_time_mode_signal is %b", uut.set_time_mode_signal); // Display the clock_set_mode
        // Step 2: Clock set sub-mode  Increment CLOCK Hour by count of 13 helps verify 24 to 12
        #30000000 BTN_L = 1; #30000000 BTN_L = 0;
        #30000000 BTN_L = 1; #30000000 BTN_L = 0;
        #30000000 BTN_L = 1; #30000000 BTN_L = 0;
        #30000000 BTN_L = 1; #30000000 BTN_L = 0;
        #30000000 BTN_L = 1; #30000000 BTN_L = 0;
        #30000000 BTN_L = 1; #30000000 BTN_L = 0;
        #30000000 BTN_L = 1; #30000000 BTN_L = 0;
        #30000000 BTN_L = 1; #30000000 BTN_L = 0;
        #30000000 BTN_L = 1; #30000000 BTN_L = 0;
        #30000000 BTN_L = 1; #30000000 BTN_L = 0;
        #30000000 BTN_L = 1; #30000000 BTN_L = 0;
        #30000000 BTN_L = 1; #30000000 BTN_L = 0;
        #30000000 BTN_L = 1; #30000000 BTN_L = 0;
        #30000000;// slight pause
        
        // Step 3: Increment CLOCK Minute X5(Toggle BTN_R)
        #30000000 BTN_R = 1; #30000000 BTN_R = 0;
        //#30000000;// slight pause
        #30000000 BTN_R = 1; #30000000 BTN_R = 0;
        //#30000000;// slight pause
        #30000000 BTN_R = 1; #30000000 BTN_R = 0;
        //#30000000;// slight pause        
        #30000000 BTN_R = 1; #30000000 BTN_R = 0;
        //#30000000;// slight pause        
        #30000000 BTN_R = 1; #30000000 BTN_R = 0;
        #30000000;// slight pause        
        #30000000;// slight pause       

        // Step 4 Clock set sub-mode  EXIT CLOCK set mode  (Toggle BTN_C)
        $display("Step 4: EXITING CLOCK SET MODE VIA BTN_C", uut.set_time_mode_signal); // Display the clock_set_mode
        $display("Step 4: Current set_time_mode_signal is %b", uut.set_time_mode_signal); // Display the clock_set_mode
        #30000000 BTN_C = 1; #30000000 BTN_C = 0;
        $display("Step 4: Current set_time_mode_signal is %b", uut.set_time_mode_signal); // Display the clock_set_mode        
        // this is a good point to change mode from 24 to 12 mode to verify the change of format works    
        #30000000;// slight pause        
        #30000000;// slight pause       
        $display("Step 5: Changing 24HR mode to 12HR mode for 250 milliseconds", uut.current_state); // Display the current state       
        $display("Step 5: Current mux_hour is %d", uut.mux_hour); // Display the current mux_hour
        #30000000 SW_2 = 1; #250000000 SW_2 = 0;// this should go to 12 hour mode and change 13 hours to 01 hours shortly
        #30000000;// slight pause        
        #30000000;// slight pause       
        $display("Step 5: Current mux_hour is %d", uut.mux_hour); // Display the current mux_hour
        // Step 5: Prepare Transition to ALARM State
        $display("Step 5: Current state is %b", uut.current_state); // Display the current state       
        #250000000;// slight pause quarter second
        $display("Step 5: Current mux_hour is %d", uut.mux_hour); // Display the current mux_hour  
        $display("Step 5: Current mux_minute is %d", uut.mux_minute); // Display the current mux_minute  
        // Step 6: Prepare Transition to ALARM State
        $display("Step 6: Asserting SW_8 and SW_4 to change to ALARM state (prearms Alarm_set_time)", uut.current_state);
        SW_8 = 1;
        SW_4 = 0;
        //#500000000;// slight pause half second
        //Step 7 ALARM set sub-mode  (Toggling BTN_C) Additional BTN_C toggle exits ALARM SET TIME MODE
        $display("Step 6: Current state is %b", uut.current_state); // Display the current state       
        $display("Step 6: Asserting BTN_C to change to ALARM state (prearms Alarm_set_time)", uut.current_state); // Display the current state 
        #30000000 BTN_C = 1; #30000000 BTN_C = 0;

        $display("Step 7: Current state is %b", uut.current_state); // Display the current state       
        $display("Step 7: Current state should be ALARM (10)"); // Display the current state
        $display("Step 7: Current mux_hour is %d", uut.mux_hour); // Display the current mux_hour  
        $display("Step 7: Current mux_minute is %d", uut.mux_minute); // Display the current mux_minute          
        
        // Step 8: Enter Alarm Set sub-mode (Toggle BTN_D) toggle again to exit sub-mode
        $display("Step 8: Enter Alarm Set sub-mode (Toggles BTN_D) toggle again to exit sub-mode");
        #30000000 BTN_D = 1; #30000000 BTN_D = 0;
        #30000000;// slight pause
        #30000000;// slight pause

        // Step 9: Increment Alarm Hour 13X to match clock setting(Toggle BTN_L)
        $display("Step 9: Incrementing Alarm Hour 13X to match real-time clock setting(Toggle BTN_L)");
        #30000000 BTN_L = 1; #30000000 BTN_L = 0;
        #30000000 BTN_L = 1; #30000000 BTN_L = 0;
        #30000000 BTN_L = 1; #30000000 BTN_L = 0;
        #30000000 BTN_L = 1; #30000000 BTN_L = 0;
        #30000000 BTN_L = 1; #30000000 BTN_L = 0;
        #30000000 BTN_L = 1; #30000000 BTN_L = 0;
        #30000000 BTN_L = 1; #30000000 BTN_L = 0;
        #30000000 BTN_L = 1; #30000000 BTN_L = 0;
        #30000000 BTN_L = 1; #30000000 BTN_L = 0;
        #30000000 BTN_L = 1; #30000000 BTN_L = 0;
        #30000000 BTN_L = 1; #30000000 BTN_L = 0;
        #30000000 BTN_L = 1; #30000000 BTN_L = 0;
        #30000000 BTN_L = 1; #30000000 BTN_L = 0;
        #30000000;// slight pause
        #30000000;// slight pause
        // Step 10: Increment Alarm Minute 6X one count larger than clock for alarm test(Toggle BTN_R)
        $display("Step 10: Incrementing Alarm Minute 6X one count larger than clock for alarm test(Toggle BTN_R)");
        #30000000 BTN_R = 1; #30000000 BTN_R = 0;
        #30000000 BTN_R = 1; #30000000 BTN_R = 0;
        #30000000 BTN_R = 1; #30000000 BTN_R = 0;
        #30000000 BTN_R = 1; #30000000 BTN_R = 0;
        #30000000 BTN_R = 1; #30000000 BTN_R = 0;
        #30000000 BTN_R = 1; #30000000 BTN_R = 0;
        #30000000;// slight pause
        #30000000;// slight pause
        // Step 11: Exit Alarm time Set Mode (Toggle BTN_D)
        $display("Step 11: EXIT Alarm Set sub-mode (Toggles BTN_D)to exit sub-mode");
        #30000000 BTN_D = 1; #30000000 BTN_D = 0;

        // Step 12: Prepare to Exit Alarm set time mode (Toggles BTN_C)
        $display("Step 12: Prepare to Exit Alarm set time mode (Toggles BTN_C)");
        #30000000 BTN_C = 1; #30000000 BTN_C = 0;
        #30000000;// slight pause
        #30000000;// slight pause

        
        $display("Step 12: Current mux_hour is %d", uut.mux_hour); // Display the current mux_hour  
        $display("Step 12: Current mux_minute is %d", uut.mux_minute); // Display the current mux_minute          
        $display("Step 12: Current state is %b", uut.current_state); // Display the current state       
        $display("Step 12: Current state should be ALARM"); // Display the current state

        // Step 13: Prepare Transition to Clock State at exit of ALARM
        $display("Step 13: Configuring SW_8 and SW_4 for STATE transition"); 
        SW_8 = 0;
        SW_4 = 0;

        // Step 14: Pause before Transition 60 milliseconds
        $display("Step 14: Current state is %b", uut.current_state); // Display the current state 
        #30000000;
        #30000000;// slight pause
        //#30000000;// slight pause

        // Step 15: Enter back into Clock State (Toggle BTN_C) two toggles for state change
        #30000000 BTN_C = 1; #30000000 BTN_C = 0;
        #30000000 BTN_C = 1; #30000000 BTN_C = 0;
        #30000000;// slight pause
        #30000000;// slight pause

        //#500000000;// slight pause half second
        $display("Step 15: Current state is %b", uut.current_state); // Display the current state       
        $display("Step 15: Current state should be CLOCK (00)"); // Display the current state
        $display("Step 15: Current mux_hour is %d", uut.mux_hour); // Display the current mux_hour  
        $display("Step 15: Current mux_minute is %d", uut.mux_minute); // Display the current mux_minute          

        // Step 16: Toggle the ALARM to ON position in preparation for debug clock
        $display("Step 16: ALERT - ALARM ARM AND TRIGGER TEST EMMINENT"); 
        $display("Step 16A: Toggling the ALARM to ON position"); // Display the current mux_minute
        // Set ALARM ON Switch high
        #30000000 SW_0 = 1;
        #30000000;// slight pause
        #30000000;// slight pause
        $display("Step 16B: Current debounced_SW_0 is %b", uut.debounced_SW_0); // debounced_SW_0
        // Step 16C: Assert debug clock
        $display("Step 16C: Assert debug clock to ON position"); // Display the current mux_minute
        debug_clock = 1;
        // Step 16B: Wait for 500 milliseconds
        $display("Step 16D: Waiting for 1500 milliseconds"); // Display the current mux_minute
        #500000000;// Wait for 500 milliseconds
        #500000000;// Wait for 500 milliseconds
        #500000000;// Wait for 500 milliseconds
        // Step 16C: verify allarm triggers
        $display("Step 16E: verify allarm triggers"); // Display the current mux_minute
        // Step 16A: De-Assert debug clock        
        $display("Step 16F: De-Assert debug clock"); // Display the current mux_minute
        debug_clock = 0;
        #30000000;// slight pause
        #30000000;// slight pause

        // Step 16A: Toggling the ALARM to OFF position
        $display("Step 16G: Toggling the ALARM to OFF position"); // Display the current mux_minute
        // Set ALARM ON Switch low
        #30000000 SW_0 = 0;
        $display("Step 16H: Slight delay post ALARM TRIGGER TEST"); // Display the current mux_minute
        #30000000;// slight pause
        #30000000;// slight pause
        #30000000;// slight pause
        #30000000;// slight pause
        $display("Step 16I: Current ALARM TRIGGERED LED is %b", uut.LD1); // debounced_SW_0
        $display("Step 16J: Toggling the ALARM LED to OFF position via BTN_D"); // Time to wake up an go to work
        #30000000 BTN_D = 1; #30000000 BTN_D = 0;
        #30000000;// slight pause
        #30000000;// slight pause
        $display("Step 16K: Current ALARM TRIGGERED LED is %b", uut.LD1); // debounced_SW_0

        $display("Step 17A: Transition to CLOCK State SW_8 = 0 SW_4 = 0(00)");
        SW_8 = 0;
        SW_4 = 0;
        #30000000;// slight pause
        // Step 21: Return to Clock State (Toggle BTN_C 2X)
        #30000000 BTN_C = 1; #30000000 BTN_C = 0;
        #30000000 BTN_C = 1; #30000000 BTN_C = 0;
        #30000000;
        $display("Step 17A: Current state is %b", uut.current_state); // Display the current state       
        $display("Step 17A: Current state should be CLOCK (00)"); // Display the current state
        $display("Step 17A: Current mux_hour is %d", uut.mux_hour); // Display the current mux_hour  
        $display("Step 17A: Current mux_minute is %d", uut.mux_minute); // Display the current mux_minute                  

        $display("Asserting BTN_U in CLOCK STATE to ADJUST TIMEZONE");
        // ENTER Timezone Set Mode (Toggle BTN_U)
        #30000000 BTN_U = 1; #30000000 BTN_U = 0; // ✅ Enable timezone setting
        #30000000; // slight pause
        $display("Entered Timezone Set Mode. timezone_set_mode = %b", uut.timezone_set_mode);
        //first increment timzone 2X then decriment timezone 2X
        $display("Step 18: Current mux_hour is %d", uut.mux_hour);
        $display("Step 18: Current mux_minute is %d", uut.mux_minute);
        $display("Step 18:increment timzone 2X then decriment timezone 2X");
        // Step 17A: Increment Timezone Offset (BTN_L)
        $display("Step 18:Increment Timezone. timezone_offset = %d", uut.timezone_offset);
        #30000000 BTN_R = 1; #30000000 BTN_R = 0;
        #30000000;
        $display("Step 18: Current mux_hour is %d", uut.mux_hour);
        $display("Step 18: Current mux_minute is %d", uut.mux_minute);
        $display("Step 18:Increment Timezone. timezone_offset = %d", uut.timezone_offset);
        // Step 18: Increment Timezone Offset (BTN_R)
        #30000000 BTN_R = 1; #30000000 BTN_R = 0;
        #30000000;
        $display("Step 18: Current mux_hour is %d", uut.mux_hour);
        $display("Step 18: Current mux_minute is %d", uut.mux_minute);

        $display("Step 19:Pre-Decrement Timezone. timezone_offset = %d", uut.timezone_offset);
        // Step 19: Decrement Timezone Offset (BTN_L)
        #30000000 BTN_L = 1; #30000000 BTN_L = 0;
        #30000000;
        $display("Step 19:Decrement Timezone. timezone_offset = %d", uut.timezone_offset);
        $display("Step 19: Current mux_hour is %d", uut.mux_hour);
        $display("Step 19: Current mux_minute is %d", uut.mux_minute);
        #30000000 BTN_L = 1; #30000000 BTN_L = 0;
        #30000000;        
        $display("Step 19:Decrement Timezone. timezone_offset = %d", uut.timezone_offset);
        $display("Step 19: Current mux_hour is %d", uut.mux_hour);
        $display("Step 19: Current mux_minute is %d", uut.mux_minute);
        // Step 19: Exit Timezone Set Mode (Toggle BTN_U)
        #30000000 BTN_U = 1; #30000000 BTN_U = 0;
        #30000000;
        $display("Step 20: Exiting Timezone Set Mode. timezone_set_mode = %b", uut.timezone_set_mode);

        // Step 20: Ensure Timezone Adjustments Reflect in Displayed Time
        #30000000;
        $display("Time After Timezone Change: mux_hour = %d, mux_minute = %d", uut.mux_hour, uut.mux_minute);
        $display("Asserting BTN_U in CLOCK STATE to DISABLE TIMEZONE SET MODE");
        #250000000;// slight pause quarter second pre-state transition and insure in clock mode
        $display("Step 20: Transition to CLOCK State SW_8 = 0 SW_4 = 0(00)");
        SW_8 = 0;
        SW_4 = 0;
        #30000000;// slight pause
        // Step 21: Return to Clock State (Toggle BTN_C 2X)
        #30000000 BTN_C = 1; #30000000 BTN_C = 0;
        #30000000 BTN_C = 1; #30000000 BTN_C = 0;
        #30000000;
        $display("Step 20: Current state is %b", uut.current_state); // Display the current state       
        $display("Step 20: Current state should be CLOCK (00)"); // Display the current state
        $display("Step 20: Current mux_hour is %d", uut.mux_hour); // Display the current mux_hour  
        $display("Step 20: Current mux_minute is %d", uut.mux_minute); // Display the current mux_minute                  

        $display("Step 21: Transition to Stopwatch State (10)");
        // Step 21: Transition to Stopwatch State
        $display("Step 21: Transition to Stopwatch State SW_8 = 0 SW_4 = 1(10)");
        SW_8 = 0;
        SW_4 = 1;
        #30000000;// slight pause

        // Step 21: Enter STOPWATCH State (Toggle BTN_C) two toggles for state change
        #30000000 BTN_C = 1; #30000000 BTN_C = 0;
        #30000000 BTN_C = 1; #30000000 BTN_C = 0;
        #30000000;// slight pause
        #30000000;// slight pause

        // Step 22: Pause before Stopwatch Exercise
        $display("Step 22: Current state is %b", uut.current_state);
        $display("Step 22: Current state should be STOPWATCH (10)");
        $display("Step 22: Current mux_hour is %d", uut.mux_hour);
        $display("Step 22: Current mux_minute is %d", uut.mux_minute);
        $display("Step 22: Pretest - Clear Stopwatch with BTN_U");
        #30000000 BTN_U = 1; #30000000 BTN_U = 0; // Reset Stopwatch

        // Add these lines to monitor the stopwatch signals
        //$monitor("Step 23: Stopwatch running = %b, counter = %d, mux_minute = %d, seconds = %d", 
                //uut.stopwatch_inst.running, uut.stopwatch_inst.counter, 
                //uut.stopwatch_inst.stopwatch_minutes, uut.stopwatch_inst.stopwatch_seconds);
        #30000000 BTN_C = 1; #30000000 BTN_C = 0; // Start/Stop Stopwatch
        //Wait for a two and a half seconds to insure increment on the stopwatch
        #500000000; // slight pause half second
        #500000000; // slight pause half second
        #500000000; // slight pause half second
        #500000000; // slight pause half second
        #500000000; // slight pause half second
        $display("Step 23: Current mux_hour is %d", uut.mux_hour);
        $display("Step 23: Current mux_minute is %d", uut.mux_minute);
        //Wait for 3 second to insure increment on the stopwatch
        #500000000;// slight pause half second
        #500000000;// slight pause half second
        #500000000;// slight pause half second
        #500000000;// slight pause half second
        #500000000;// slight pause half second
        #500000000;// slight pause half second
        $display("Step 23: Current mux_hour is %d", uut.mux_hour);
        $display("Step 23: Current mux_minute is %d", uut.mux_minute);

        // Step 24: Exercise Stopwatch Functionality
        $display("Step 24: Post test - HALT Stopwatch with BTN_C");
        #30000000 BTN_C = 1; #30000000 BTN_C = 0; // Start/Stop Stopwatch
        #500000000;// slight pause half second
        #500000000;// slight pause half second
        $display("Step 24: Current mux_hour is %d", uut.mux_hour);
        $display("Step 24: Current mux_minute is %d", uut.mux_minute);
        $display("Step 24: Post test - Clear Stopwatch with BTN_U");
        #30000000 BTN_U = 1; #30000000 BTN_U = 0; // Reset-clear Stopwatch
        $display("Step 24: Current mux_hour is %d", uut.mux_hour);
        $display("Step 24: Current mux_minute is %d", uut.mux_minute);

        // Finish simulation
        $finish;
    end

endmodule
