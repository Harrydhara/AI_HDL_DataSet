module stopwatch (
    input wire clk,               // Slow clock (e.g., 1 kHz from clock divider)
    input wire rst,               // Reset signal  
    input wire start_stop,        // Debounced start/stop button input 
    input wire reset_button,      // Debounced reset button input
    output reg [15:0] time_out    // BCD output for seven-segment display (HH:MM)  
);

    // Internal registers
    reg [9:0] ms_counter;         // Millisecond counter (0 to 999)
    reg [5:0] sec_counter;        // Second counter (0 to 59)
    reg [6:0] min_counter;        // Minute counter (0 to 99)
    reg running;                  // Stopwatch running state

    // Start/Stop toggle logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            running <= 0;         // Stop stopwatch on reset
        end else if (start_stop) begin
            running <= ~running;  // Toggle running state on button press
        end
    end

    // Main stopwatch logic
    always @(posedge clk or posedge rst) begin
        if (rst || reset_button) begin
            // Reset all counters when rst or reset_button is asserted
            ms_counter <= 0;
            sec_counter <= 0;
            min_counter <= 0;
        end else if (running) begin
            // Increment milliseconds counter
            ms_counter <= ms_counter + 1;

            // Increment seconds counter when ms_counter reaches 999
            if (ms_counter == 999) begin
                ms_counter <= 0;
                sec_counter <= sec_counter + 1;

                // Increment minutes counter when sec_counter reaches 59
                if (sec_counter == 59) begin
                    sec_counter <= 0;
                    min_counter <= min_counter + 1;

                    // Reset minutes counter after reaching 99
                    if (min_counter == 99) begin
                        min_counter <= 0;
                    end
                end
            end
        end
    end

    // Output the time in BCD format (HH:MM)
    always @(*) begin
        time_out = {min_counter[6:0], sec_counter[5:0]}; // Combine minutes and seconds
    end

endmodule
