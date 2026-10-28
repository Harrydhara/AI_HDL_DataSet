module buttonDebouncer (
    input wire clk,           // Clock input (from external clock divider, e.g., 1 kHz)
    input wire reset,         // Active-high reset signal
    input wire button_in,     // Raw input from the button
    output reg button_out     // Debounced button output (with edge detection)
);

    parameter DEBOUNCE_DELAY = 5; // Delay parameter to control debounce time

    reg [15:0] counter;            // Counter for debounce delay
    reg button_stable;             // Stable button state after debouncing
    reg button_sync_0, button_sync_1; // Synchronize button input

    // Synchronize the button signal to avoid metastability
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            button_sync_0 <= 0;
            button_sync_1 <= 0;
        end else begin
            button_sync_0 <= button_in;
            button_sync_1 <= button_sync_0;
        end
    end

    // Debouncing logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            counter <= 0;
            button_stable <= 0;
        end else if (button_sync_1 == button_stable) begin
            // Reset counter if button state is stable
            counter <= 0;
        end else begin
            // Increment counter when state is changing
            counter <= counter + 1;
            if (counter >= DEBOUNCE_DELAY) begin
                button_stable <= button_sync_1; // Update stable state after delay
                counter <= 0;
            end
        end
    end

    // Edge detection for button output
    reg button_stable_prev;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            button_out <= 0;
            button_stable_prev <= 0;
        end else begin
            button_out <= button_stable & ~button_stable_prev; // Output pulse on rising edge
            button_stable_prev <= button_stable;
        end
    end

endmodule