`timescale 1ns/1ps
module stopwatch_tb;
  // Testbench信号定义
  reg clk_100MHz;
  reg start_stop;  // 启动/停止按键
  reg reset;       // 复位按键

  // 来自stopwatch模块的输出
  wire [3:0] an;
  wire [6:0] seg;

  // ------------------------------
  // 实例化待测模块：可通过参数覆盖DIV_VALUE（此处与stopwatch.v中保持一致）
  // ------------------------------
  stopwatch #(.DIV_VALUE(500_000 - 1)) uut (
    .clk(clk_100MHz),
    .start_stop(start_stop),
    .reset(reset),
    .an(an),
    .seg(seg)
  );

  // ------------------------------
  // 产生 100MHz 时钟：周期为10ns
  // ------------------------------
  initial begin
    clk_100MHz = 1'b0;
    forever #5 clk_100MHz = ~clk_100MHz;
  end

  // ------------------------------
  // 测试激励
  // ------------------------------
  initial begin
    // 初始状态
    start_stop = 1'b0;
    reset      = 1'b0;

    // 等待系统上电稳定
    #100;

    // 施加复位：保持20ms后释放
    reset = 1'b1;
    #20_000_000;  // 20ms
    reset = 1'b0;

    // 等待20ms后继续操作
    #20_000_000;

    // 启动秒表：给一个持续15ms的start_stop脉冲（确保上升沿能被检测到）
    start_stop = 1'b1;
    #15_000_000;  // 15ms
    start_stop = 1'b0;

    // 运行50ms，观察计数器递增
    #50_000_000;  // 50ms

    // 停止秒表：再次给一个15ms的脉冲
    start_stop = 1'b1;
    #15_000_000;
    start_stop = 1'b0;

    // 等待20ms
    #20_000_000;

    // 再次启动秒表
    start_stop = 1'b1;
    #15_000_000;
    start_stop = 1'b0;

    // 运行50ms
    #50_000_000;

    // 最后复位
    reset = 1'b1;
    #15_000_000;
    reset = 1'b0;

    // 再等待20ms后结束仿真
    #20_000_000;
    $stop;
  end
endmodule
