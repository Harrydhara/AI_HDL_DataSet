module clock_divider (
    input wire clk_in,          // 100 MHz input clock
    input wire rst,             // Reset signal
    output reg clk_out          // Divided output clock
);

    parameter CLK_IN_FREQ = 100_000_000;   // Input clock frequency (100 MHz)
    parameter TARGET_FREQ = 1000;            // Target output clock frequency (1000 Hz)
    localparam DIV_FACTOR = CLK_IN_FREQ / TARGET_FREQ; // Calculate division factor
    localparam MAX_COUNT = DIV_FACTOR / 2;            // Precompute max counter value

    reg [26:0] counter;                    // Counter size to handle large division factors

    always @(posedge clk_in or posedge rst) begin
        if (rst) begin
            counter <= 0;
            clk_out <= 0;
        end else begin
            if (counter == MAX_COUNT - 1) begin
                clk_out <= ~clk_out; // Toggle output clock
                counter <= 0;        // Reset counter
            end else begin
                counter <= counter + 1;
            end
        end
    end
endmodule
