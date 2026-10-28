// Simple testbench for tqvp_gpio - compiles and runs basic stimulus
`timescale 1ns/1ps

module tb_gpio;
    reg clk;
    reg rst_n;
    reg [5:0] address;
    reg [31:0] data_in;
    reg data_write_n;
    reg data_read_n;
    wire [31:0] data_out;
    wire data_ready;
    wire user_interrupt;
    reg [7:0] ui_in;
    wire [7:0] uo_out;

    // Instantiate DUT
    tqvp_gpio dut (
        .clk(clk),
        .rst_n(rst_n),
        .address(address),
        .data_in(data_in),
        .data_write_n(data_write_n),
        .data_read_n(data_read_n),
        .data_out(data_out),
        .data_ready(data_ready),
        .user_interrupt(user_interrupt),
        .ui_in(ui_in),
        .uo_out(uo_out)
    );

    // Clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        // initialize
        rst_n = 0;
        address = 6'd0;
        data_in = 32'd0;
        data_write_n = 1;
        data_read_n = 1;
        ui_in = 8'h00;
        #20;
        rst_n = 1; // release reset
        #20;

        $display("STARTING tb_gpio - basic stimulus");

        // Write DIRECTION_REG (addr 0x01) - set all outputs
        @(posedge clk);
        address = 6'd1; // 0x01
        data_in = 32'hFF;
        data_write_n = 0; // active low write
        @(posedge clk);
        data_write_n = 1;
        @(posedge clk);

        // Write OUTPUT_REG (addr 0x00)
        address = 6'd0; // 0x00
        data_in = 32'hAA;
        @(posedge clk);
        data_write_n = 0;
        @(posedge clk);
        data_write_n = 1;
        @(posedge clk);

        $display("After writes: uo_out = %02x", uo_out);

        // Switch to input mode (all inputs)
        address = 6'd1;
        data_in = 32'h00; // all inputs
        @(posedge clk);
        data_write_n = 0;
        @(posedge clk);
        data_write_n = 1;
        @(posedge clk);

        // Drive ui_in and read INPUT_REG (addr 0x02)
        ui_in = 8'h5A;
        address = 6'd2;
        @(posedge clk);
        data_read_n = 0; // active low read
        @(posedge clk);
        data_read_n = 1;
        @(posedge clk);

        $display("ui_in=%02x data_out=%08x", ui_in, data_out);

        $display("TEST COMPLETE");
        $finish;
    end

endmodule
