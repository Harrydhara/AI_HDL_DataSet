module button_debouncer (
    input wire clk,
    input wire reset,
    input wire btn_in,
    output reg btn_clean
);
    reg [15:0] counter = 0;  // Reduced counter size for faster debounce
    reg btn_sync_0, btn_sync_1;
    
    always @(posedge clk) begin
        btn_sync_0 <= btn_in;
        btn_sync_1 <= btn_sync_0;
    end
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            counter <= 0;
            btn_clean <= 0;
        end else if (btn_sync_1 != btn_clean) begin
            counter <= counter + 1;
            if (counter > 5000) btn_clean <= btn_sync_1; // Adjust debounce time
        end else begin
            counter <= 0;
        end
    end
endmodule
