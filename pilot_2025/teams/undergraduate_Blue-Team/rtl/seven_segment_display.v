module seven_segment_display(
    input  wire clk,          // 100MHz
    input  wire rst,
    input  wire [3:0] digit0,
    input  wire [3:0] digit1,
    input  wire [3:0] digit2,
    input  wire [3:0] digit3,
    output reg  [3:0] an,
    output reg  [6:0] seg
);
    // 扫描计数器：决定哪个数码管被激活
    reg [17:0] scan_count;
    always @(posedge clk or posedge rst) begin
        if (rst)
            scan_count <= 0;
        else
            scan_count <= scan_count + 1;
    end

    // 取 scan_count 的高 2 位作为当前激活的数码管
    wire [1:0] digit_sel = scan_count[17:16];

    // 根据 digit_sel 选择当前要显示的 BCD
    reg [3:0] current_digit;
    always @(*) begin
        case(digit_sel)
            2'b00: current_digit = digit0;
            2'b01: current_digit = digit1;
            2'b10: current_digit = digit2;
            2'b11: current_digit = digit3;
            default: current_digit = 4'd0;
        endcase
    end

    // BCD -> 7 段译码 (共阳极，低电平点亮)
    reg [6:0] seg_temp;
    always @(*) begin
        case (current_digit)
            4'd0: seg_temp = 7'b1000000;
            4'd1: seg_temp = 7'b1111001;
            4'd2: seg_temp = 7'b0100100;
            4'd3: seg_temp = 7'b0110000;
            4'd4: seg_temp = 7'b0011001;
            4'd5: seg_temp = 7'b0010010;
            4'd6: seg_temp = 7'b0000010;
            4'd7: seg_temp = 7'b1111000;
            4'd8: seg_temp = 7'b0000000;
            4'd9: seg_temp = 7'b0010000;
            default: seg_temp = 7'b1111111;
        endcase
    end

    // 输出段选和位选
    always @(*) begin
        seg = seg_temp;
        case(digit_sel)
            2'b00: an = 4'b1110; // 右侧数码管激活
            2'b01: an = 4'b1101;
            2'b10: an = 4'b1011;
            2'b11: an = 4'b0111; // 左侧数码管激活
            default: an = 4'b1111;
        endcase
    end

endmodule
