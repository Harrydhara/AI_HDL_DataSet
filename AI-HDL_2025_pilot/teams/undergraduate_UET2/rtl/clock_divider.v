module clock_divider(
    input wire clk_in,     // 100 MHz clock input
    input wire reset,      // Synchronous reset
    output reg clk_out     // Divided clock output (1 Hz)
);

    reg [26:0] counter;    // 27-bit counter to divide by 100 million (1 Hz)

    always @(posedge clk_in or posedge reset) begin
        if (reset) begin
            counter <= 27'b0;
            clk_out <= 0;
        end else begin
            if (counter == 27'd50) begin // need to = 50_000_000, modulated to 5000 to run faster
                counter <= 27'b0;
                clk_out <= ~clk_out;  // Toggle output every 1 second
            end else begin
                counter <= counter + 1;
            end
        end
    end

endmodule
