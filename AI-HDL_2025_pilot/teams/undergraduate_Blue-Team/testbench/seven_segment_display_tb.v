`timescale 1ns/1ps

module seven_segment_display_tb;

  reg clk;
  reg rst;
  reg [3:0] digit0;
  reg [3:0] digit1;
  reg [3:0] digit2;
  reg [3:0] digit3;
  
  wire [3:0] an;
  wire [6:0] seg;
  
  // 实例化 seven_segment_display 模块
  seven_segment_display uut (
    .clk(clk),
    .rst(rst),
    .digit0(digit0),
    .digit1(digit1),
    .digit2(digit2),
    .digit3(digit3),
    .an(an),
    .seg(seg)
  );
  
  // 产生 100MHz 时钟 (周期 10ns)
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end
  
  // Testbench 激励
  initial begin
    // 初始复位，给定固定数字
    rst = 1;
    digit0 = 4'd0;  // 右侧数码管显示 0
    digit1 = 4'd1;  // 第二位显示 1
    digit2 = 4'd2;  // 第三位显示 2
    digit3 = 4'd3;  // 左侧数码管显示 3
    
    // 保持复位 100ns 后释放
    #100;
    rst = 0;
    
    // 观察 1ms 后结束仿真
    #1_000_000;  // 1ms
    $stop;
  end

endmodule
