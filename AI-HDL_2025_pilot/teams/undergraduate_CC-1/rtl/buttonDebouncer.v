`timescale 1ns / 1ps
module buttonDebouncer #(
    parameter DEBOUNCE_DELAY = 20 // Debounce duration in clock cycles (default: 20 ms at 1 kHz)
) (
    input wire clk_1kHz,              // Clock input (1 kHz)
    input wire rst,              // Active-high reset signal
    input wire button_in,        // Raw pushbutton input
    output reg button_out        // Debounced pushbutton output
);

    // Internal signals
    reg [15:0] counter;          // Counter for debounce timing
    reg stable_state;            // Stable state of the input signal

    always @(posedge clk_1kHz or posedge rst) begin
        if (rst) begin
            counter <= 0;
            stable_state <= 0;
            button_out <= 0;
        end else begin
            if (button_in != stable_state) begin
                counter <= counter + 1;
                if (counter >= DEBOUNCE_DELAY) begin
                    stable_state <= button_in; // Update stable state
                    counter <= 0;
                end
            end else begin
                counter <= 0; // Reset counter if no change
            end
            button_out <= stable_state;
        end
    end

endmodule
