module four_digit_7seg_display (
    input wire clk_1khz,        // 1kHz Clock
    input wire reset,
    input wire [15:0] bcd_in,
    output reg [6:0] seg,
    output reg [3:0] an
);

    reg [1:0] digit_select = 0;
    reg [3:0] bcd_digit;
    reg [7:0] refresh_counter = 0; // Adjusted for a reasonable refresh rate

    localparam REFRESH_RATE = 4;  // 250Hz refresh rate (Each digit updates every 4ms)

    // Function-based 7-Segment Decoder to optimize area usage
    function [6:0] get_7seg_pattern(input [3:0] digit);
        case (digit)
            4'd0: get_7seg_pattern = 7'b1000000;
            4'd1: get_7seg_pattern = 7'b1111001;
            4'd2: get_7seg_pattern = 7'b0100100;
            4'd3: get_7seg_pattern = 7'b0110000;
            4'd4: get_7seg_pattern = 7'b0011001;
            4'd5: get_7seg_pattern = 7'b0010010;
            4'd6: get_7seg_pattern = 7'b0000010;
            4'd7: get_7seg_pattern = 7'b1111000;
            4'd8: get_7seg_pattern = 7'b0000000;
            4'd9: get_7seg_pattern = 7'b0010000;
            default: get_7seg_pattern = 7'b1111111;
        endcase
    endfunction

    always @(*) begin
        seg = get_7seg_pattern(bcd_digit);
    end

    always @(posedge clk_1khz) begin
        if (reset) begin
            refresh_counter <= 0;
            digit_select <= 0;
        end else if (refresh_counter >= REFRESH_RATE) begin
            refresh_counter <= 0;
            digit_select <= digit_select + 1;
        end else begin
            refresh_counter <= refresh_counter + 1;
        end
    end

    always @(*) begin
        case (digit_select)
            2'b00: begin
                bcd_digit = bcd_in[3:0];
                an = 4'b1110;
            end
            2'b01: begin
                bcd_digit = bcd_in[7:4];
                an = 4'b1101;
            end
            2'b10: begin
                bcd_digit = bcd_in[11:8];
                an = 4'b1011;
            end
            2'b11: begin
                bcd_digit = bcd_in[15:12];
                an = 4'b0111;
            end
            default: begin
                bcd_digit = 4'd0;
                an = 4'b1111;
            end
        endcase
    end

endmodule
