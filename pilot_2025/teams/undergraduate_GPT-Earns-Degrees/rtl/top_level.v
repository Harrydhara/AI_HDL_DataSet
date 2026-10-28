module top_level(
    input wire clk_100mhz,    // 100MHz clock input
    input wire button0,       // Start/Stop button input
    input wire button1,       // Reset button input
    output wire [3:0] anodes, // Seven-segment anode outputs
    output wire [6:0] segments // Seven-segment segment outputs
);
    // Internal signals
    wire clk_1hz;                     // 1Hz clock signal
    wire debounced_start_stop;        // Debounced start/stop button signal
    wire debounced_reset;             // Debounced reset button signal

    // Clock Divider: Generate 1Hz clock from 100MHz input
    clock_divider #(.DIV_FACTOR(100000000)) clk_div_inst (
        .clk_in(clk_100mhz),
        .reset(1'b0),
        .clk_out(clk_1hz)
    );

    // Debounce for Start/Stop Button (button0)
    button_debouncer start_stop_debouncer (
        .clk(clk_1hz),                 // Use 1Hz clock for debouncing
        .reset(1'b0),                  // No reset for debouncer
        .button_in(button0),           // Noisy button0 input
        .button_out(debounced_start_stop) // Debounced start/stop signal
    );

    // Debounce for Reset Button (button1)
    button_debouncer reset_debouncer (
        .clk(clk_1hz),                 // Use 1Hz clock for debouncing
        .reset(1'b0),                  // No reset for debouncer
        .button_in(button1),           // Noisy button1 input
        .button_out(debounced_reset)   // Debounced reset signal
    );

    // Stopwatch Module
    stopwatch stopwatch_inst (
        .clk(clk_1hz),                 // 1Hz clock for time counting
        .reset_btn(debounced_reset),   // Debounced reset button
        .start_stop_btn(debounced_start_stop), // Debounced start/stop button
        .anodes(anodes),               // Anode outputs for SSD
        .segments(segments)            // Segment outputs for SSD
    );
endmodule
