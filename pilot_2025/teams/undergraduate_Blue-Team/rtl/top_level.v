module top_level(
    input  wire clk_100MHz,
    input  wire button1,   // start/stop
    input  wire button2,   // reset
    output wire [3:0] an,
    output wire [6:0] seg
);

    // 1) 对启动/停止做消抖
    wire start_stop_db;
    button_debouncer #(.WIDTH(10)) u_db_start_stop (
        .clk(clk_100MHz),
        .rst(1'b0),
        .btn_in(button1),
        .btn_out(start_stop_db)
    );

    // 2) 直接把复位按键接给秒表，不走消抖
    wire reset_db;
    assign reset_db = button2;

    // 3) 实例化秒表
    stopwatch u_stopwatch (
        .clk(clk_100MHz),
        .start_stop(start_stop_db),
        .reset(reset_db),
        .an(an),
        .seg(seg)
    );

endmodule
