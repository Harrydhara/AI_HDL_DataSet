module clock_divider #(
    parameter FREQ_TARGET = 1_000
)(
    input wire clk_in,
    input wire reset,
    output reg clk_out
);

    // Compute divisor only once to save power and resources
    localparam integer DIVISOR = (100_000_000 / (2 * FREQ_TARGET)); 
    
    reg [$clog2(DIVISOR)-1:0] counter = 0; // Optimize counter bit-width

    always @(posedge clk_in or posedge reset) begin
        if (reset) begin
            counter <= 0;
            clk_out <= 0;
        end else if (counter == DIVISOR - 1) begin
            counter <= 0;
            clk_out <= ~clk_out;  // Toggle the output clock
        end else begin
            counter <= counter + 1;
        end
    end

endmodule
