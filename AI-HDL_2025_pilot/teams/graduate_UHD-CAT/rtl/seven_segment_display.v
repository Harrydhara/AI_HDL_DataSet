module seven_segment_display #(
    parameter integer CLK_FREQ = 1_000_000,  // Input clock frequency (in Hz)
    parameter integer REFRESH_RATE = 240    // Total refresh rate (in Hz)
) (
    input wire clk,                // Clock signal
    input wire rst,                // Reset signal
    input wire [15:0] number,      // 4-digit BCD input (each 4 bits for each digit)
    output reg [6:0] seg,          // 7-segment display output (a-g)
    output reg [3:0] an            // Anodes for the 4 digits
);

    // Calculate refresh counter max value
    localparam integer DIGIT_PERIOD = CLK_FREQ / REFRESH_RATE;

    // Internal registers
    reg [$clog2(DIGIT_PERIOD):0] refresh_counter = 0;  // Counter for refresh timing
    reg [1:0] current_digit = 0;                      // Current digit (0-3)

    // 7-segment encoding for BCD digits (common cathode)
    function [6:0] bcd_to_7seg;
        input [3:0] bcd;
        begin
            case (bcd)
                4'd0: bcd_to_7seg = 7'b1111110;
                4'd1: bcd_to_7seg = 7'b0110000;
                4'd2: bcd_to_7seg = 7'b1101101;
                4'd3: bcd_to_7seg = 7'b1111001;
                4'd4: bcd_to_7seg = 7'b0110011;
                4'd5: bcd_to_7seg = 7'b1011011;
                4'd6: bcd_to_7seg = 7'b1011111;
                4'd7: bcd_to_7seg = 7'b1110000;
                4'd8: bcd_to_7seg = 7'b1111111;
                4'd9: bcd_to_7seg = 7'b1111011;
                default: bcd_to_7seg = 7'b0000000;  // Blank for invalid BCD
            endcase
        end
    endfunction

    // Refresh counter and digit selection
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            refresh_counter <= 0;
            current_digit <= 0;
        end else begin
            if (refresh_counter >= DIGIT_PERIOD - 1) begin
                refresh_counter <= 0;
                current_digit <= current_digit + 1;
            end else begin
                refresh_counter <= refresh_counter + 1;
            end
        end
    end

    // Anode control and segment selection
    always @(*) begin
        case (current_digit)
            2'd0: begin
                an = 4'b1110;                  // Activate digit 0
                seg = bcd_to_7seg(number[3:0]); // BCD for digit 0
            end
            2'd1: begin
                an = 4'b1101;                  // Activate digit 1
                seg = bcd_to_7seg(number[7:4]); // BCD for digit 1
            end
            2'd2: begin
                an = 4'b1011;                  // Activate digit 2
                seg = bcd_to_7seg(number[11:8]); // BCD for digit 2
            end
            2'd3: begin
                an = 4'b0111;                  // Activate digit 3
                seg = bcd_to_7seg(number[15:12]); // BCD for digit 3
            end
            default: begin
                an = 4'b1111;  // All digits off (shouldn't happen)
                seg = 7'b0000000; // Blank
            end
        endcase
    end

endmodule
