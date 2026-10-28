`timescale 1ns / 1ps

module stopwatch (
    input wire clk_1kHz,       // 1 kHz clock
    input wire rst,            // Reset signal
    input wire start_stop,     // Start/Stop button input
    input wire reset_button,   // Reset button input
    input wire enable_stopwatch, // New control signal to enable stopwatch only in STOPWATCH mode
    output reg [5:0] stopwatch_minutes, // Binary minutes output
    output reg [5:0] stopwatch_seconds  // Binary seconds output
);

    // Internal signals
    reg [9:0] clk_divider = 0;     // Clock divider counter
    reg clk_transition_rising = 0; // Rising edge signal every 1000 ms
    reg running = 0;               // Stopwatch running state
    reg start_stop_prev = 0;       // Previous state of start/stop button
    reg [15:0] counter = 0;        // Time counter in seconds

    // Parameters
    parameter MAX_SECONDS = 3599;  // Maximum seconds (59 minutes, 59 seconds)

    // Clock Divider with Rising Edge Detection
    always @(posedge clk_1kHz or posedge rst) begin
        if (rst) begin
            clk_divider <= 0;
            clk_transition_rising <= 0;
        end else if (running && enable_stopwatch) begin // Only count when enabled
            if (clk_divider == 999) begin // Generate rising edge every 1000 cycles
                clk_divider <= 0;
                clk_transition_rising <= 1;
            end else begin
                clk_divider <= clk_divider + 1;
                clk_transition_rising <= 0; // Clear rising edge signal
            end
        end else begin
            clk_divider <= 0;              // Reset divider when not running
            clk_transition_rising <= 0;    // Clear rising edge signal
        end
    end

    // Start/Stop Control Logic
    always @(posedge clk_1kHz or posedge rst) begin
        if (rst) begin
            running <= 0;
            start_stop_prev <= 0;
        end else begin
            if (start_stop && !start_stop_prev && enable_stopwatch) begin // Only toggle if enabled
                running <= ~running; // Toggle running state on button press
            end
            start_stop_prev <= start_stop;
        end
    end

    // Counter Logic
    always @(posedge clk_transition_rising or posedge rst or posedge reset_button) begin
        if (rst || reset_button) begin
            counter <= 0; // Reset counter
        end else if (running && enable_stopwatch) begin // Only count if enabled
            if (counter == MAX_SECONDS) begin
                counter <= 0; // Reset to 0 after 59:59
            end else begin
                counter <= counter + 1;
            end
        end
    end

    // Convert counter to binary minutes and seconds
    always @(*) begin
        if (rst || reset_button) begin
            stopwatch_minutes = 6'b0; // Reset to 00
            stopwatch_seconds = 6'b0; // Reset to 00
        end else begin
            stopwatch_minutes = counter / 60; // Extract minutes in binary
            stopwatch_seconds = counter % 60; // Extract seconds in binary
        end
    end

endmodule
