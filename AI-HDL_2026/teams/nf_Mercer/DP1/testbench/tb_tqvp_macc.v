`timescale 1ns/1ps
`default_nettype none

module tb_tqvp_macc;

    reg         clk;
    reg         rst_n;
    reg  [7:0]  ui_in;
    wire [7:0]  uo_out;
    reg  [5:0]  address;
    reg  [31:0] data_in;
    reg  [1:0]  data_write_n;
    reg  [1:0]  data_read_n;
    wire [31:0] data_out;
    wire        data_ready;
    wire        user_interrupt;

    tqvp_example dut (
        .clk          (clk),
        .rst_n        (rst_n),
        .ui_in        (ui_in),
        .uo_out       (uo_out),
        .address      (address),
        .data_in      (data_in),
        .data_write_n (data_write_n),
        .data_read_n  (data_read_n),
        .data_out     (data_out),
        .data_ready   (data_ready),
        .user_interrupt(user_interrupt)
    );

    // clock
    initial clk = 0;
    always #5 clk = ~clk;

    task write32(input [5:0] addr, input [31:0] val);
    begin
        @(posedge clk);
        address      <= addr;
        data_in      <= val;
        data_write_n <= 2'b00; 
        data_read_n  <= 2'b11;
        @(posedge clk);
        data_write_n <= 2'b11;
    end
    endtask

    task read32(input [5:0] addr);
    begin
        @(posedge clk);
        address      <= addr;
        data_write_n <= 2'b11;
        data_read_n  <= 2'b00;
        @(posedge clk); 
    end
    endtask

    initial begin
        ui_in        = 8'd0;
        address      = 6'd0;
        data_in      = 32'd0;
        data_write_n = 2'b11;
        data_read_n  = 2'b11;

        rst_n = 0;
        repeat (5) @(posedge clk);
        rst_n = 1;

        write32(6'h14, 32'd3); // MACC_A
        write32(6'h18, 32'd4); // MACC_B

        write32(6'h20, 32'b10); 

        write32(6'h20, 32'b01); // start
        write32(6'h20, 32'b01); // start again

        // read ACC
        read32(6'h1C);
        @(posedge clk);
        $display("MACC_ACC = %0d (expected 24)", data_out);

        // read CTRL 
        read32(6'h20);
        @(posedge clk);
        $display("MACC_DONE = %0d", data_out[0]);

        #50;
        $finish;
    end

endmodule
