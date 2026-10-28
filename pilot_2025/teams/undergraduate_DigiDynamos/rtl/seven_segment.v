module seven_segment_display (
    input wire clk,               // Clock signal
    input wire rst,               // Reset signal
    input wire [15:0] number,     // 4-digit BCD input (each 4 bits for each digit)
    output reg [6:0] seg,         // 7-segment display output (a-g)
    output reg [3:0] an           // Anodes for the 4 digits
);

    // Refresh rate control
    reg [1:0] refresh_counter = 0; // 2-bit counter for 4 digits (00, 01, 10, 11)
    reg [3:0] current_digit;       // Current digit to display
    wire [3:0] digit[3:0];         // Array to hold each BCD digit

    // Split input number into four BCD digits
    assign digit[0] = number[3:0];
    assign digit[1] = number[7:4];
    assign digit[2] = number[11:8];
    assign digit[3] = number[15:12];

    // Refreshing each digit
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            refresh_counter <= 0;
            an <= 4'b1111;          // Turn off all digits initially
        end else begin
            refresh_counter <= refresh_counter + 1;
            case (refresh_counter)
                2'b00: begin
                    an <= 4'b1110;  // Enable the rightmost digit
                    current_digit <= digit[0];
                end
                2'b01: begin
                    an <= 4'b1101;  // Enable the next digit
                    current_digit <= digit[1];
                end
                2'b10: begin
                    an <= 4'b1011;  // Enable the next digit
                    current_digit <= digit[2];
                end
                2'b11: begin
                    an <= 4'b0111;  // Enable the leftmost digit
                    current_digit <= digit[3];
                end
            endcase
        end
    end

    // Segment display for each BCD digit (0-9 only)
    always @(*) begin
        case (current_digit)
            4'd0: seg = 7'b1000000;
            4'd1: seg = 7'b1111001;
            4'd2: seg = 7'b0100100;
            4'd3: seg = 7'b0110000;
            4'd4: seg = 7'b0011001;
            4'd5: seg = 7'b0010010;
            4'd6: seg = 7'b0000010;
            4'd7: seg = 7'b1111000;
            4'd8: seg = 7'b0000000;
            4'd9: seg = 7'b0010000;
            default: seg = 7'b1111111; // Blank display for undefined values
        endcase
    end

endmodule