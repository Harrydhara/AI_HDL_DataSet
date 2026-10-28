// seven_segment_display.v - 4-digit seven-segment display controller
module seven_segment_display #(
    parameter REFRESH_DIV = 18  // number of bits for refresh counter (controls multiplex speed)
)(
    input  wire clk,
    input  wire reset,
    input  wire [3:0] digit0, digit1, digit2, digit3,  // BCD or 0-9 values for each digit
    input  wire       dp0, dp1, dp2, dp3,             // decimal point for each digit (1=on, assuming active-low LED)
    output reg  [3:0] an,     // digit enable (active low)
    output reg        a, b, c, d, e, f, g, dp         // segment outputs (active low)
);
    // Refresh counter to generate multiplexing timing
    reg [REFRESH_DIV-1:0] refresh_counter = 0;
    always @(posedge clk or posedge reset) begin
        if (reset)
            refresh_counter <= 0;
        else
            refresh_counter <= refresh_counter + 1;
    end

    // The two MSBs of refresh_counter will be used to select the digit (for 4 digits).
    wire [1:0] mux_sel = refresh_counter[REFRESH_DIV-1:REFRESH_DIV-2];

    reg [3:0] current_digit;
    reg       current_dp;
    always @(*) begin
        case(mux_sel)
            2'b00: begin  // Select digit0 (e.g., rightmost digit)
                an = 4'b1110;         // enable lowest digit (active low)
                current_digit = digit0;
                current_dp    = dp0;
            end
            2'b01: begin  // Select digit1
                an = 4'b1101;         // enable next digit
                current_digit = digit1;
                current_dp    = dp1;
            end
            2'b10: begin  // Select digit2
                an = 4'b1011;
                current_digit = digit2;
                current_dp    = dp2;
            end
            2'b11: begin  // Select digit3 (e.g., leftmost digit)
                an = 4'b0111;
                current_digit = digit3;
                current_dp    = dp3;
            end
        endcase
    end

    // 7-segment decoding (active low segments)
    reg [7:0] segments;  // 7 bits for segments + 1 bit for dp
    always @(*) begin
        case (current_digit)
            4'd0: segments[6:0] = 7'b1000000;  // 0 -> a,b,c,d,e,f = ON, g = OFF
            4'd1: segments[6:0] = 7'b1111001;  // 1 -> b,c = ON (segments b,c on => 0 in pattern)
            4'd2: segments[6:0] = 7'b0100100;  // 2
            4'd3: segments[6:0] = 7'b0110000;  // 3
            4'd4: segments[6:0] = 7'b0011001;  // 4
            4'd5: segments[6:0] = 7'b0010010;  // 5
            4'd6: segments[6:0] = 7'b0000010;  // 6
            4'd7: segments[6:0] = 7'b1111000;  // 7
            4'd8: segments[6:0] = 7'b0000000;  // 8
            4'd9: segments[6:0] = 7'b0010000;  // 9
            default: segments[6:0] = 7'b1111111; // blank (all segments off)
        endcase
        // Decimal point: if current_dp=1 (on request), drive it low (active low)
        segments[7] = (current_dp) ? 1'b0 : 1'b1;
    end

    // Assign decoded segments to output (mapping {g,f,e,d,c,b,a,dp})
    always @(*) begin
        {g, f, e, d, c, b, a, dp} = segments;
    end
endmodule
