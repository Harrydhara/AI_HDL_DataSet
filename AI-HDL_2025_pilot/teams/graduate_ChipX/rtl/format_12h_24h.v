// format_12h_24h.v - Toggle between 12-hour and 24-hour display format
module format_12h_24h(
    input  wire [4:0] hour_24,   // 0-23 hour input
    input  wire       mode12,    // 1 = 12-hour mode, 0 = 24-hour mode
    output reg  [4:0] hour_out,  // hour for display (0-23 or 1-12 depending on mode)
    output reg        pm         // PM indicator (valid in 12h mode)
);
    always @(*) begin
        if (mode12) begin
            // 12-hour mode conversion
            if (hour_24 == 5'd0) begin
                hour_out = 5'd12;   // 0 -> 12 AM
                pm = 0;
            end else if (hour_24 < 5'd12) begin
                hour_out = hour_24; // 1-11 AM
                pm = 1'b0;
            end else if (hour_24 == 5'd12) begin
                hour_out = 5'd12;   // 12 -> 12 PM (noon)
                pm = 1'b1;
            end else begin
                hour_out = hour_24 - 5'd12; // 13-23 -> 1-11 PM
                pm = 1'b1;
            end
        end else begin
            // 24-hour mode
            hour_out = hour_24;
            pm = 1'b0;  // PM indicator not used in 24h mode
        end
    end
endmodule
