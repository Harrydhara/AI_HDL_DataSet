module clock_divider #(parameter DIVISOR = 50000000) (
    input wire clk_in,
    input wire reset,
    output reg clk_out
);
    reg [31:0] counter = 0;
    always @(posedge clk_in or posedge reset) begin
        if (reset) begin
            counter <= 0;
            clk_out <= 0;
        end else if (clk_in) begin // Only toggle if enabled
            if (counter == (DIVISOR - 1)) begin
                counter <= 0;
                clk_out <= ~clk_out;
            end else begin
                counter <= counter + 1;
            end
        end
    end
endmodule
