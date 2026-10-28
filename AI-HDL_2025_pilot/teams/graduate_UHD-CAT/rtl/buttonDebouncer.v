module buttonDebouncer #(
    parameter integer CLK_FREQ = 1_000,  // Clock frequency in Hz
    parameter integer DEBOUNCE_TIME = 10  // Debounce time in milliseconds
) (
    input  wire clk,        // Clock input signal
    input  wire rst,        // Active-high reset signal to initialize the debouncer
    input  wire button_in,  // Raw input from the button
    output reg  button_out  // Single-pulse output with debounce and edge detection
);

  // Calculate the number of clock cycles for debounce time
  localparam integer DEBOUNCE_CYCLES = (CLK_FREQ / 1000) * DEBOUNCE_TIME;

  // State variables
  reg [$clog2(DEBOUNCE_CYCLES):0] counter;  // Counter for debounce timing
  reg button_stable;  // Stable button signal
  reg button_stable_prev;  // Previous stable button signal (for edge detection)

  // Debouncing logic
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      counter <= 0;
      button_stable <= 0;
      button_stable_prev <= 0;
      button_out <= 0;
    end else begin
      // Debounce logic
      if (button_in == button_stable) begin
        counter <= 0;  // Reset counter if input matches stable state
      end else begin
        if (counter < DEBOUNCE_CYCLES) begin
          counter <= counter + 1;  // Increment counter if input is unstable
        end else begin
          button_stable <= button_in;  // Update stable state
          counter <= 0;  // Reset counter
        end
      end

      // Edge detection logic
      button_stable_prev <= button_stable;
      button_out <= button_stable & ~button_stable_prev;  // Single pulse on rising edge
    end
  end
  
endmodule
