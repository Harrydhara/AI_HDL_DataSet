module button_debouncer #(
    parameter WIDTH = 10
)(
    input  wire clk,
    input  wire rst,
    input  wire btn_in,
    output reg  btn_out
);

    localparam MAX_COUNT = (1 << WIDTH) - 1;

    reg [WIDTH-1:0] counter;
    reg btn_sync;

    // 同步到时钟域
    always @(posedge clk or posedge rst) begin
        if (rst)
            btn_sync <= 0;
        else
            btn_sync <= btn_in;
    end

    // 计数消抖
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= 0;
            btn_out <= 0;
        end else if (btn_sync == btn_out) begin
            counter <= 0;
        end else begin
            counter <= counter + 1;
            if (counter == MAX_COUNT) begin
                btn_out <= btn_sync;
                counter <= 0;
            end
        end
    end
endmodule
