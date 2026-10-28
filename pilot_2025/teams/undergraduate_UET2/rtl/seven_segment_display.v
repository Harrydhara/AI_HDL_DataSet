module seven_segment_display (
    input wire clk,
    input wire rst,
    input wire [15:0] number,
    output reg [6:0] seg,
    output reg [3:0] an
);

    reg [1:0] digit_select;
    reg [3:0] current_digit;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            digit_select <= 0;
            an <= 4'b1111; 
        end else begin
            digit_select <= digit_select + 1;
            case (digit_select)
                2'b00: an <= 4'b1110; 
                2'b01: an <= 4'b1101; 
                2'b10: an <= 4'b1011; 
                2'b11: an <= 4'b0111; 
                default: an <= 4'b1111;
            endcase
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_digit <= 4'b0;
        end else begin
            case (digit_select)
                2'b00: current_digit <= number[3:0];
                2'b01: current_digit <= number[7:4];
                2'b10: current_digit <= number[11:8];
                2'b11: current_digit <= number[15:12];
            endcase
        end
    end

    always @(*) begin
        case (current_digit)
            4'h0: seg = 7'b0111111;
            4'h1: seg = 7'b0000110;
            4'h2: seg = 7'b1011011;
            4'h3: seg = 7'b1001111;
            4'h4: seg = 7'b1100110;
            4'h5: seg = 7'b1101101;
            4'h6: seg = 7'b1111101;
            4'h7: seg = 7'b0000111;
            4'h8: seg = 7'b1111111;
            4'h9: seg = 7'b1101111;
            default: seg = 7'b0000000;
        endcase
    end

endmodule
