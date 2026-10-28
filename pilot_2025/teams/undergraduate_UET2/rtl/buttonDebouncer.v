module buttonDebouncer (
    input wire clk,          // Slow clock input (1 kHz)
    input wire reset,        // Active-high reset signal
    input wire button_in,    // Raw input from the button
    output reg button_out    // Processed output with debounce
);

    reg [7:0] shift_reg;     // 3-bit shift register for filtering bounces

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            shift_reg <= 3'b000_000_00;
            button_out <= 0;
        end else begin
            shift_reg <= {shift_reg[6:0], button_in};
            if (shift_reg == 8'b011_111_11)
                button_out <= 1;
            else button_out <= 0;
        end
    end

endmodule
