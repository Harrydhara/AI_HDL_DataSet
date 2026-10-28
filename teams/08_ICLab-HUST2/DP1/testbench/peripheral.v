/*
 * Copyright (c) 2025 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

// Winograd Convolution Accelerator Peripheral
// Wrapper TinyQV peripheral bus → winograd_peripheral
module tqvp_winograd (
    input         clk,
    input         rst_n,

    input  [7:0]  ui_in,
    output [7:0]  uo_out,

    input [5:0]   address,
    input [31:0]  data_in,

    input [1:0]   data_write_n,
    input [1:0]   data_read_n,

    output [31:0] data_out,
    output        data_ready,

    output        user_interrupt
);

    wire [31:0] wino_data_out;
    wire        wino_data_ready;
    wire        wino_irq;

    winograd_peripheral #(
        .DATA_WIDTH(32),
        .FRAC_BITS (16)
    ) u_winograd (
        .clk          (clk),
        .rstn         (rst_n),
        .address      (address),       
        .data_write_n (data_write_n),
        .data_read_n  (data_read_n),
        .data_in      (data_in),
        .data_out     (wino_data_out),
        .data_ready   (wino_data_ready),
        .winograd_irq (wino_irq)
    );

    assign data_out       = wino_data_out;
    assign data_ready     = wino_data_ready;
    assign user_interrupt = wino_irq;

    assign uo_out = {7'b0, wino_irq};

    wire _unused = &{ui_in, 1'b0};

endmodule