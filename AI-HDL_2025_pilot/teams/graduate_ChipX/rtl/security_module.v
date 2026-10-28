// security_module.v - Simple lock/unlock via code
module security_module #(
    parameter SECRET_CODE = 4'b1010  // default secret code
)(
    input  wire clk,
    input  wire reset,
    input  wire [3:0] code_input,
    input  wire unlock_pulse,
    output reg  unlocked
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            unlocked <= 1'b0;
        end else begin
            if (unlock_pulse) begin
                if (code_input == SECRET_CODE)
                    unlocked <= 1'b1;
                // If wrong code, we could keep it locked (perhaps add a penalty or LED blink, omitted for simplicity)
            end
        end
    end
endmodule
