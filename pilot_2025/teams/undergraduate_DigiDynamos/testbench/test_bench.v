`timescale 1us / 1ns

module top_level_tb;

    // Inputs
    reg clk;
    reg rst;
    reg button1;
    reg button2;
    reg button3;
    reg button4;
 //   reg button5;

    // Outputs
    wire [6:0] seg;
    wire [3:0] an;
    wire am_pm_led;        
    wire alarm_led;        
    wire set_time_led;      
    wire stop_watch_led;    
    wire clock_led;         
    wire convert_12_led;   
    wire alarm_state_led;   
    wire timezone_led;      
    wire [4:0] current_hours;   
    wire [5:0] current_minutes;  

    // Instantiate the top_level module
    top_level uut (
        .clk(clk),
        .rst(rst),
        .button1(button1),
        .button2(button2),
        .button3(button3),
        .button4(button4),
   //     .button5(button5),
        .seg(seg),
        .an(an),
        .am_pm_led(am_pm_led),
        .alarm_led(alarm_led),
        .set_time_led(set_time_led),
        .stop_watch_led(stop_watch_led),
        .clock_led(clock_led),
        .convert_12_led(convert_12_led),
        .alarm_state_led(alarm_state_led),
        .timezone_led(timezone_led),
        .current_hours(current_hours),
        .current_minutes(current_minutes)
    );

    // Clock generation
    always #0.005 clk = ~clk; // 1 kHz clock (1ms period)

    initial begin
        // Initialize Inputs
        clk = 0;
        rst = 1;
        button1 = 0;
        button2 = 0;
        button3 = 0;
        button4 = 0;
  //      button5 = 0;

        // Wait for global reset
        #200;
        rst = 0;

        // Test sequence
        // Set time to 04:10
    //    #20000 button3 = 1; 
    //    #20000 button3 = 0; // Enter set time mode
        repeat (14) begin
            #20000 button1 = 1; 
            #20000 button1 = 0; // Increment hours to 14
        end
        repeat (1) begin
            #20000 button2 = 1; 
            #20000 button2 = 0; //decrease hours to 13
        end
        #20000 button3 = 1; 
        #20000 button3 = 0;
        repeat (15) begin
            #20000 button1 = 1; 
            #20000 button1 = 0;  // Increment minutes to 15
        end
        repeat (5) begin
            #20000 button2 = 1; 
            #20000 button2 = 0;  // decrese minutes to 10
        end
        #20000 button4 = 1; 
        #20000 button4 = 0; // Confirm time

        // Change mode to alarm
        #20000 button4 = 1; 
        #20000 button4 = 0;

        // Set alarm to 06:30
        repeat (6) begin
            #20000 button1 = 1; 
            #20000 button1 = 0; // Increment hours to 6
        end
         repeat (2) begin
            #20000 button2 = 1; 
            #20000 button2 = 0; // decrease hours to 4
        end
        #20000 button3 = 1; 
        #20000 button3 = 0;
        repeat (30) begin
            #20000 button1 = 1; 
            #20000 button1 = 0;  // Increment minutes to 30
        end
        repeat (5) begin
            #20000 button2 = 1; 
            #20000 button2 = 0;  // decrease minutes to 25
        end
        #20000 button4 = 1; 
        #20000 button4 = 0; // Confirm alarm time and Change mode to time zone
    
        // Select time zone 2 (UTC+2)
        #20000 button2 = 1; 
        #20000 button2 = 0;

        // Change mode to stopwatch
        #20000 button4 = 1; 
        #20000 button4 = 0;

        // Start stopwatch
        #20000 button1 = 1; 
        #20000 button1 = 0; // Start stopwatch

        // Wait for some time
        #2000000;
        // Stop stopwatch
        #20000 button1 = 1; 
        #20000 button1 = 0;

        // Reset stopwatch
        #20000 button2 = 1; 
        #20000 button2 = 0;

        // Change mode to convert 24 to 12
        #20000 button4 = 1; 
        #20000 button4 = 0;

        // Wait for some time
        #5000000;
        // Finish simulation
        $finish;
    end

endmodule