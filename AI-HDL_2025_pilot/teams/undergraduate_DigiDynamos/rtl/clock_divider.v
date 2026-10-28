module clock_divider (
    input wire clk_in,          // 100 MHz clock input
    input wire reset,           // Synchronous reset
    output reg clk_out        // Divided clock output
);
    parameter TARGET_FREQ = 1000;
    // Calculate the division value based on the target frequency
    localparam integer DIV_VALUE = 100000000 / (2 * TARGET_FREQ);
    reg [31:0] counter = 0;     // Fixed 32-bit counter

    always @(posedge clk_in or posedge reset) begin
        if (reset) begin
            counter <= 0;
            clk_out <= 0;
        end else if (counter == DIV_VALUE - 1) begin
            counter <= 0;
            clk_out <= ~clk_out;  // Toggle clk_out every half period
        end else begin
            counter <= counter + 1;
        end
    end
endmodule