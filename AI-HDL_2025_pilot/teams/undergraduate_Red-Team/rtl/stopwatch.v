`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Stopwatch Module with Power, Area, and Security Optimizations
module stopwatch(
    input wire clk,            // Slow clock (e.g., 1 Hz or 1 kHz for counting)
    input wire reset,          // Active-high reset
    input wire start_stop,     // Button for starting/stopping the stopwatch
    input wire reset_time,     // Button for resetting the stopwatch
    input wire key_input_bit,  // Single-bit key input for authentication
    input wire key_enter,      // Signal to check authentication
    output reg [15:0] time_data // 4-digit BCD time data for seven-segment display
);

    // Security Key (Predefined)
    reg [3:0] security_key = 4'b1010;  
    reg [3:0] key_input = 4'b0000;      // Stores user-entered key
    reg authenticated = 0;              // Flag to indicate successful authentication

    // Internal states
    reg running;               // Stopwatch running state
    reg [13:0] counter;        // Reduced from 16-bit to 14-bit counter
    wire gated_clk;            // Gated clock signal for power saving

    // Parameters
    localparam MAX_COUNT = 9999; // Maximum count for 4-digit display

    // Clock gating logic: Disable clock when stopwatch is not running
    assign gated_clk = running ? clk : 1'b0;

    // **Secure Authentication Logic**
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            key_input <= 4'b0000;
            authenticated <= 0;
        end else if (key_enter) begin
            if (key_input == security_key) begin
                authenticated <= 1; // Authentication success
            end else begin
                key_input <= 4'b0000; // Reset on incorrect entry
                authenticated <= 0;
            end
        end else begin
            key_input <= {key_input[2:0], key_input_bit}; // Shift in key input
        end
    end

    // **FSM-Based Start/Stop Control with Authentication**
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            running <= 0;
        end else if (start_stop && authenticated) begin
            running <= ~running; // Toggle running only if authenticated
        end
    end

    // Counter logic only updates when stopwatch is running
    always @(posedge gated_clk) begin
        if (running && counter < MAX_COUNT) begin
            counter <= counter + 1;
        end else if (reset_time && authenticated) begin
            counter <= 0; // Reset time only if authenticated
        end
    end

    // **Optimized BCD Calculation (No extra registers)**
    always @(*) begin
        time_data[15:12] = (counter / 1000) % 10; // Thousands
        time_data[11:8]  = (counter / 100) % 10;  // Hundreds
        time_data[7:4]   = (counter / 10) % 10;   // Tens
        time_data[3:0]   = counter % 10;          // Ones
    end

endmodule
