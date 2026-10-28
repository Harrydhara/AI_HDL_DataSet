`timescale 1ns/1ps

module tb_peripheral;
    reg clk;
    reg rst_n;
    reg [7:0] ui_in;
    reg [3:0] address;
    reg data_write;
    reg [7:0] data_in;
    wire [7:0] uo_out;
    wire [7:0] data_out;

    // Instantiate your module
    zyl_vga_generator uut (
        .clk(clk),
        .rst_n(rst_n),
        .ui_in(ui_in),
        .uo_out(uo_out),
        .address(address),
        .data_write(data_write),
        .data_in(data_in),
        .data_out(data_out)
    );

    // Clock generation (64MHz ~ 15.625ns period)
    always #7.8 clk = ~clk;

    initial begin
        // Initial values
        clk = 0;
        rst_n = 0;
        ui_in = 0;
        address = 0;
        data_write = 0;
        data_in = 0;

        // Reset the system
        #100 rst_n = 1;
        #20;

        // CPU Task: Write Color (Red) to address 4'h0
        @(posedge clk);
        address = 4'h0;
        data_in = 8'b00000010; // Setting bit 1 (Red)
        data_write = 1;
        @(posedge clk);
        data_write = 0;

        // CPU Task: Enable Display at address 4'h1
        @(posedge clk);
        address = 4'h1;
        data_in = 8'h01;
        data_write = 1;
        @(posedge clk);
        data_write = 0;

        // Wait to see a few horizontal lines
        #100000;
        
        $display("Test complete. Check waveforms for hsync pulses.");
        $finish;
    end

    // Optional: Log to VCD file for GTKWave
    initial begin
        $dumpfile("tb_vga.vcd");
        $dumpvars(0, tb_zyl_vga_generator);
    end

endmodule