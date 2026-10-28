`timescale 1ns/1ps
`default_nettype none

module tb_systolic;

    reg clk;
    reg rst_n;

    // A matrix
    reg [31:0] a00, a01, a10, a11;

    // B matrix
    reg [31:0] b00, b01, b10, b11;

    // Outputs
    wire [31:0] c00, c01, c10, c11;

    // DUT
    systolic_2x2 dut (
        .clk(clk),
        .rst_n(rst_n),
        .a00(a00), .a01(a01),
        .a10(a10), .a11(a11),
        .b00(b00), .b01(b01),
        .b10(b10), .b11(b11),
        .c00(c00), .c01(c01),
        .c10(c10), .c11(c11)
    );

    // Clock
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        rst_n = 0;
        a00 = 0; a01 = 0; a10 = 0; a11 = 0;
        b00 = 0; b01 = 0; b10 = 0; b11 = 0;

        repeat (5) @(posedge clk);
        rst_n = 1;

        // --------------------------
        // Test: A = [[1,2],[3,4]]
        //       B = [[5,6],[7,8]]
        // --------------------------
        a00 = 1; a01 = 2;
        a10 = 3; a11 = 4;

        b00 = 5; b01 = 6;
        b10 = 7; b11 = 8;

        // Wait for systolic pipeline
        repeat (10) @(posedge clk);

        $display("C00 = %0d", c00);
        $display("C01 = %0d", c01);
        $display("C10 = %0d", c10);
        $display("C11 = %0d", c11);

        $finish;
    end

endmodule
