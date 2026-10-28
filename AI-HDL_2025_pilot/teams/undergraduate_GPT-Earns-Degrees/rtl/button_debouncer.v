module button_debouncer(
    input wire clk,            // Slow clock input (e.g., 1kHz or 10kHz)
    input wire reset,          // Asynchronous reset
    input wire button_in,      // Raw button input (noisy signal)
    output reg button_out      // Debounced button output
);
    reg [2:0] shift_reg = 3'b000; // 3-bit shift register to filter noise

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            shift_reg <= 3'b000;
            button_out <= 1'b0;
        end else begin
            // Shift the button input into the shift register
            shift_reg <= {shift_reg[1:0], button_in};
            
            // Set output high only if all bits in the shift register are high
            if (shift_reg == 3'b111) 
                button_out <= 1'b1;
            // Set output low only if all bits in the shift register are low
            else if (shift_reg == 3'b000) 
                button_out <= 1'b0;
        end
    end
endmodule
