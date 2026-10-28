`timescale 1ns / 1ps

module clock_divider(
    input wire clk,                // Input clock (e.g., 100 MHz)
    input wire rst,                // Reset signal
    input wire debug_clock,        // **NEW Debug Control Signal**
    output reg clk_1kHz,           // 1 kHz clock output
    output reg clk_1Hz             // 1 Hz clock output (modified)
);

    // Parameters for clock division
    parameter CLK_FREQ = 100_000_000;  // Input clock frequency (100 MHz)
    parameter CLK_1KHZ_DIV = CLK_FREQ / 1000; // Divider for 1 kHz clock
    parameter CLK_1HZ_DIV_FROM_1KHZ_NORMAL = 1000;   // **Normal 1Hz divider**
    parameter CLK_1HZ_DIV_FROM_1KHZ_DEBUG = 10;      // **Faster Debug Divider (100Hz)**

    // Internal counters
    reg [31:0] counter_1kHz; // Counter for 1 kHz clock
    reg [9:0] counter_1Hz;   // Counter for 1 Hz clock from 1 kHz clock
    reg [9:0] clk_1Hz_divider;   // Selectable divider

    // Ensuring power-up initialization (for simulation, ignored in synthesis)
    initial begin
        counter_1kHz = 0;
        clk_1kHz = 0;
    end

    // Generate 1 kHz clock from 100 MHz input
    always @(posedge clk) begin
        if (rst) begin
            counter_1kHz <= 0;
            clk_1kHz <= 0;
        end else if (counter_1kHz == CLK_1KHZ_DIV / 2 - 1) begin
            counter_1kHz <= 0;
            clk_1kHz <= ~clk_1kHz; // Toggle 1 kHz clock
        end else begin
            counter_1kHz <= counter_1kHz + 1;
        end
    end

    // Generate selectable 1 Hz clock from 1 kHz clock
always @(posedge clk_1kHz) begin
    if (rst) begin
        counter_1Hz <= 0;
        clk_1Hz <= 0;
        clk_1Hz_divider <= CLK_1HZ_DIV_FROM_1KHZ_NORMAL;
    end else begin
        // Check if debug_clock changed and immediately reset the counter
        if (debug_clock) begin
            clk_1Hz_divider <= CLK_1HZ_DIV_FROM_1KHZ_DEBUG;
            counter_1Hz <= 0;  // Reset counter to avoid transition delay
            clk_1Hz <= 0;      // ✅ Ensure clk_1Hz starts correctly in debug mode
        end else begin
            clk_1Hz_divider <= CLK_1HZ_DIV_FROM_1KHZ_NORMAL;
        end
        
        if (counter_1Hz == clk_1Hz_divider / 2 - 1) begin
            counter_1Hz <= 0;
            clk_1Hz <= ~clk_1Hz;
        end else begin
            counter_1Hz <= counter_1Hz + 1;
        end
    end
end

endmodule