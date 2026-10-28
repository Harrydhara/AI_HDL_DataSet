module clock_divider #(
    parameter SIMULATION = 1  // 1=仿真模式，0=实际硬件模式
)(
    input  wire clk_in,   // 100MHz 时钟输入
    input  wire rst,      // 异步复位，高电平有效
    output reg  clk_out   // 分频输出
);
    // 根据模式选择分频系数
    // -----------------------------------------------------------
    // - 若在硬件上跑1Hz: 需要在0.5s翻转一次 => 50,000,000 - 1
    // - 若在仿真里跑10Hz: 只需在(100MHz/20)=5,000,000 - 1时翻转
    //   (即0.05s翻转一次，总周期0.1s =>10Hz)
    // -----------------------------------------------------------
    localparam DIV_VALUE_REAL = 50_000_000 - 1;  // 实际硬件
    localparam DIV_VALUE_SIM  = 5_000_000  - 1;  // 仿真用（10Hz）
    
    // 选择当前的分频上限
    localparam DIV_VALUE = (SIMULATION == 1) ? DIV_VALUE_SIM : DIV_VALUE_REAL;
    
    reg [31:0] count_reg = 0;
    
    always @(posedge clk_in or posedge rst) begin
        if (rst) begin
            count_reg <= 0;
            clk_out   <= 0;
        end else begin
            if (count_reg == DIV_VALUE) begin
                count_reg <= 0;
                clk_out   <= ~clk_out;  // 在计满时翻转输出
            end else begin
                count_reg <= count_reg + 1;
            end
        end
    end
endmodule
