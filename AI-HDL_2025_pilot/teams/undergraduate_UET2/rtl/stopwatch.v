`timescale 1ns / 1ps

module stopwatch (
    input wire clk,               // Slow clock (1 Hz for 1-second ticks)
    input wire rst,               // Reset signal
    input wire start_stop,        // Debounced start/stop button input
    input wire reset_button,      // Debounced reset button input
    output reg [15:0] time_out    // BCD output (MM:SS)
);

    reg running;  // Indicates if the stopwatch is running
    reg prev_start_stop, prev_reset; // Previous state of buttons (for edge detection)

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset the stopwatch on external reset signal
            running <= 0;
            time_out <= 16'b0;
            prev_start_stop <= 0;
            prev_reset <= 0;
        end else begin
            // Detect edge for start/stop button
            if (start_stop && !prev_start_stop) begin
                running <= ~running; // Toggle running state
            end
            
            // Detect edge for reset button
            if (reset_button && !prev_reset) begin
                time_out <= 16'b0;
                running <= 0;
            end
            
            // Store previous button states
            prev_start_stop <= start_stop;
            prev_reset <= reset_button;

            // If the stopwatch is running, update the time every second
            if (running) begin
                if (time_out[3:0] == 4'h9) begin
                    time_out[3:0] <= 4'h0;
                    if (time_out[7:4] == 4'h5) begin
                        time_out[7:4] <= 4'h0;
                        if (time_out[11:8] == 4'h9) begin
                            time_out[11:8] <= 4'h0;
                            if (time_out[15:12] == 4'h5)
                                time_out[15:12] <= 4'h0;
                            else
                                time_out[15:12] <= time_out[15:12] + 4'h1;
                        end else
                            time_out[11:8] <= time_out[11:8] + 4'h1;
                    end else
                        time_out[7:4] <= time_out[7:4] + 4'h1;
                end else
                    time_out[3:0] <= time_out[3:0] + 4'h1;
            end
        end
    end

endmodule
