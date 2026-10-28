/*
 * Copyright (c) 2025 Sujith Kani
 * SPDX-License-Identifier: Apache-2.0
 */
`default_nettype none
module tqvp_pwm_sujith(
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [3:0] address,
    input  wire       data_write,
    input  wire [7:0] data_in,
    output wire [7:0] data_out);
    // PWM duty cycle register
    reg [7:0] duty;
    // 8-bit free-running counter
    reg [7:0] counter;
    // Write duty cycle at address 0
    always @(posedge clk) begin
        if (!rst_n)
            duty <= 8'd0;
        else if (data_write && address == 4'h0)
            duty <= data_in;
    end
    // Free-running counter
    always @(posedge clk) begin
        if (!rst_n)
            counter <= 8'd0;
        else
            counter <= counter + 8'd1;
    end
    // Read-back interface
    assign data_out=(address == 4'h0) ? duty : 8'd0;
    // Output counter (7 bits) and PWM (LSB)
    assign uo_out={
        counter[7:1],
        (duty == 8'd0) ? 1'b0 :
        (duty == 8'd255) ? 1'b1 :
        (counter < duty)
    };
endmodule
