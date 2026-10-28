`timescale 1ns/1ps

module stopwatch(
    input  wire clk,         // 100MHz 系统时钟
    input  wire start_stop,  // 已消抖的启动/停止按键
    input  wire reset,       // 已消抖的复位按键
    output wire [3:0] an,
    output wire [6:0] seg
);

    // ---------------------------------------------
    // 1) 实例化 clock_divider 模块
    //    将 100MHz 分频为一个较慢的时钟 (如 10Hz / 100Hz)
    //    在仿真中可设置 SIMULATION=1，以缩短分频周期
    // ---------------------------------------------
    wire clk_slow;  // 分频后的慢时钟
    clock_divider #(.SIMULATION(1)) u_clk_divider (
        .clk_in(clk),
        .rst(reset),
        .clk_out(clk_slow)
    );

    // ---------------------------------------------
    // 2) 计数逻辑 (MM:SS) 
    //    在分频时钟的上升沿工作
    // ---------------------------------------------
    reg running;
    reg [5:0] seconds;
    reg [5:0] minutes;
    
    // 用于检测 start_stop 信号的上升沿
    reg start_stop_prev;

    always @(posedge clk_slow or posedge reset) begin
        if (reset) begin
            running         <= 1'b0;
            seconds         <= 6'd0;
            minutes         <= 6'd0;
            start_stop_prev <= 1'b0;
        end else begin
            // 检测上升沿：只有在start_stop从0->1时才翻转running
            if (start_stop && !start_stop_prev) begin
                running <= ~running;
            end
            start_stop_prev <= start_stop;

            // 若处于running状态，则每个分频时钟跳一次秒
            if (running) begin
                if (seconds == 6'd59) begin
                    seconds <= 6'd0;
                    if (minutes == 6'd59) 
                        minutes <= 6'd0;
                    else
                        minutes <= minutes + 1;
                end else begin
                    seconds <= seconds + 1;
                end
            end
        end
    end

    // ---------------------------------------------
    // 3) BCD 拆分，用于数码管显示
    // ---------------------------------------------
    wire [3:0] digit0 = seconds % 10;  // 秒个位
    wire [3:0] digit1 = seconds / 10;  // 秒十位
    wire [3:0] digit2 = minutes % 10;  // 分个位
    wire [3:0] digit3 = minutes / 10;  // 分十位

    // ---------------------------------------------
    // 4) 实例化七段数码管显示模块
    //    (假设名为 seven_segment_display)
    // ---------------------------------------------
    seven_segment_display u_seg_disp (
        .clk(clk),   // 用系统时钟进行扫描
        .rst(reset),
        .digit0(digit0),
        .digit1(digit1),
        .digit2(digit2),
        .digit3(digit3),
        .an(an),
        .seg(seg)
    );

endmodule
