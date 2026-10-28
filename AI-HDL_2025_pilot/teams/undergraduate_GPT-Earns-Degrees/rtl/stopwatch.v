module stopwatch(
    input wire clk,                  // Clock input (1Hz for counting)
    input wire reset_btn,            // Reset button input
    input wire start_stop_btn,       // Start/Stop button input
    output wire [3:0] anodes,        // Anodes for seven-segment display
    output wire [6:0] segments       // Segments for seven-segment display
);
    reg [3:0] digit_0 = 0;           // Seconds (units)
    reg [3:0] digit_1 = 0;           // Seconds (tens)
    reg [3:0] digit_2 = 0;           // Minutes (units)
    reg [3:0] digit_3 = 0;           // Minutes (tens)
    reg running = 0;                 // State: running or stopped

    // Debounce modules for buttons
    wire start_stop_debounced;
    wire reset_debounced;

    button_debouncer db_start_stop (
        .clk(clk),
        .reset(1'b0),
        .button_in(start_stop_btn),
        .button_out(start_stop_debounced)
    );

    button_debouncer db_reset (
        .clk(clk),
        .reset(1'b0),
        .button_in(reset_btn),
        .button_out(reset_debounced)
    );

    // Control logic
    always @(posedge clk) begin
        if (reset_debounced) begin
            // Reset the stopwatch
            digit_0 <= 0;
            digit_1 <= 0;
            digit_2 <= 0;
            digit_3 <= 0;
            running <= 0;
        end else if (start_stop_debounced) begin
            // Toggle running state
            running <= ~running;
        end

        if (running) begin
            // Increment time
            if (digit_0 == 9) begin
                digit_0 <= 0;
                if (digit_1 == 5) begin
                    digit_1 <= 0;
                    if (digit_2 == 9) begin
                        digit_2 <= 0;
                        if (digit_3 == 5) begin
                            digit_3 <= 0; // Roll over at 59:59
                        end else begin
                            digit_3 <= digit_3 + 1;
                        end
                    end else begin
                        digit_2 <= digit_2 + 1;
                    end
                end else begin
                    digit_1 <= digit_1 + 1;
                end
            end else begin
                digit_0 <= digit_0 + 1;
            end
        end
    end

    // Instantiate the seven-segment display driver
    seven_segment_display ssd_driver (
        .clk(clk),
        .reset(1'b0),
        .data_in({digit_3, digit_2, digit_1, digit_0}),
        .anodes(anodes),
        .segments(segments)
    );
endmodule
