module seven_segment_display(
    input wire clk,                  // Clock input (e.g., 1kHz for multiplexing)
    input wire reset,                // Asynchronous reset
    input wire [15:0] data_in,       // 16-bit input data to display (4 digits)
    output reg [3:0] anodes,         // Anode control signals for the 4 SSDs
    output reg [6:0] segments        // Segment control signals (a-g)
);
    // Digit select counter
    reg [1:0] digit_select = 0;

    // Binary to seven-segment decoder
    function [6:0] bcd_to_segments;
        input [3:0] bcd;
        case (bcd)
            4'b0000: bcd_to_segments = 7'b1000000; // 0
            4'b0001: bcd_to_segments = 7'b1111001; // 1
            4'b0010: bcd_to_segments = 7'b0100100; // 2
            4'b0011: bcd_to_segments = 7'b0110000; // 3
            4'b0100: bcd_to_segments = 7'b0011001; // 4
            4'b0101: bcd_to_segments = 7'b0010010; // 5
            4'b0110: bcd_to_segments = 7'b0000010; // 6
            4'b0111: bcd_to_segments = 7'b1111000; // 7
            4'b1000: bcd_to_segments = 7'b0000000; // 8
            4'b1001: bcd_to_segments = 7'b0010000; // 9
            default: bcd_to_segments = 7'b1111111; // Blank
        endcase
    endfunction

    // Clock-driven process
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            digit_select <= 0;
            anodes <= 4'b1111;      // Turn off all displays
            segments <= 7'b1111111; // Blank all segments
        end else begin
            // Select which digit to display
            digit_select <= digit_select + 1;

            case (digit_select)
                2'b00: begin
                    anodes <= 4'b1110;                     // Enable digit 0
                    segments <= bcd_to_segments(data_in[3:0]); // Display lower 4 bits
                end
                2'b01: begin
                    anodes <= 4'b1101;                     // Enable digit 1
                    segments <= bcd_to_segments(data_in[7:4]); // Display bits [7:4]
                end
                2'b10: begin
                    anodes <= 4'b1011;                     // Enable digit 2
                    segments <= bcd_to_segments(data_in[11:8]); // Display bits [11:8]
                end
                2'b11: begin
                    anodes <= 4'b0111;                     // Enable digit 3
                    segments <= bcd_to_segments(data_in[15:12]); // Display bits [15:12]
                end
            endcase
        end
    end
endmodule
