module button_debouncer (
    input wire clk,         
    input wire reset,
    input wire button_in,
    output reg button_out
);
    
    reg ff1, ff2;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            ff1 <= 0;
            ff2 <= 0;
            button_out <= 0;
        end else begin
            ff1 <= button_in;
            ff2 <= ff1;
            button_out <= ff1 & ~ff2; // Optimize output assignment
        end
    end

endmodule
