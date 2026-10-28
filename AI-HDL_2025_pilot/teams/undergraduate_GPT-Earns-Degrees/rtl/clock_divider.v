module clock_divider(
    input wire clk_in,         // 100MHz clock input
    input wire reset,          // Asynchronous reset
    output reg clk_out         // Divided clock output
);
    parameter DIV_FACTOR = 50000000; // Divide by 50,000,000 for 1Hz output (100MHz / 50,000,000)
    reg [31:0] counter = 0;

    always @(posedge clk_in or posedge reset) begin
        if (reset) begin
            counter <= 0;
            clk_out <= 0;
        end else begin
            if (counter == DIV_FACTOR - 1) begin
                counter <= 0;
                clk_out <= ~clk_out; // Toggle the output clock
            end else begin
                counter <= counter + 1;
            end
        end
    end
endmodule
