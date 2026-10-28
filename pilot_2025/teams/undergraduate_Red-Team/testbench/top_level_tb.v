`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/17/2024 08:32:47 PM
// Design Name: 
// Module Name: top_level_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


// Testbench for Top-Level Design

`timescale 1ns / 1ps

module top_level_tb;

    // Testbench signals
    reg clk_100mhz;
    reg reset;
    reg button0;
    reg button1;
    wire [6:0] seg;
    wire [3:0] an;

    // Instance of top-level module
    top_level uut (
        .clk_100mhz(clk_100mhz),
        .reset(reset),
        .button0(button0),
        .button1(button1),
        .seg(seg),
        .an(an)
    );

    // Clock generation
    initial begin
        clk_100mhz = 0;
        forever #5 clk_100mhz = ~clk_100mhz; // 100 MHz clock (10 ns period)
    end

    // Stimulus generation
    initial begin
        // Initialize inputs
        reset = 1;
        button0 = 0;
        button1 = 0;

        // Wait for global reset
        #3000;
        reset = 0;

        // Test: Start the stopwatch
        #3000;
        button0 = 1; // Press start/stop button
        #3000;
        button0 = 0; // Release button

        // Let the stopwatch run for some time
        #10000;

        // Test: Pause the stopwatch
        button0 = 1; // Press start/stop button
        #3000;
        button0 = 0; // Release button

        // Wait while paused
        #3000;

        // Test: Reset the stopwatch
        button1 = 1; // Press reset button
        #3000;
        button1 = 0; // Release button

        // Wait for a short period
        #500;

        // End simulation
        $finish;
    end

    // Monitor outputs
    initial begin
        $monitor($time, " clk=%b reset=%b button0=%b button1=%b seg=%b an=%b",
                 clk_100mhz, reset, button0, button1, seg, an);
    end

endmodule
