`timescale 1ns/1ps
module top_level_tb;

  reg clk_100MHz;
  reg button1;  // start/stop
  reg button2;  // reset
  
  wire [3:0] an;
  wire [6:0] seg;
  
  // 实例化顶层模块
  top_level uut (
      .clk_100MHz(clk_100MHz),
      .button1(button1),
      .button2(button2),
      .an(an),
      .seg(seg)
  );
  
  // 产生 100MHz 时钟 (周期 10ns)
  initial begin
    clk_100MHz = 1'b0;
    forever #5 clk_100MHz = ~clk_100MHz;
  end
  
  // 修改后的仿真激励：延长复位脉冲宽度
  initial begin
    // 初始化按键信号
    button1 = 1'b0;
    button2 = 1'b0;

    // 等待 10us 让系统上电稳定
    #10_000;  // 10us

    // 模拟复位：按下 button2，保持 50us 脉冲
    button2 = 1'b1;
    #50_000; // 50us 脉冲，足够让消抖器捕捉
    button2 = 1'b0;

    // 等待 50us 让复位信号传递完毕
    #50_000;
    
    // 模拟启动秒表：按下 button1，保持 20us 脉冲
    button1 = 1'b1;
    #20_000;  // 20us
    button1 = 1'b0;
    
    // 等待足够时间，让秒表开始计数（例如 20ms）
    #20_000_000;  // 20ms

    // （可选）模拟停止秒表
    button1 = 1'b1;
    #20_000;
    button1 = 1'b0;
    
    // 等待一段时间
    #20_000_000;

    // 再次启动秒表
    button1 = 1'b1;
    #20_000;
    button1 = 1'b0;
    
    // 最后再次复位
    button2 = 1'b1;
    #50_000;
    button2 = 1'b0;
    
    // 再等 20ms 后结束仿真
    #20_000_000;
    $stop;
  end

endmodule
