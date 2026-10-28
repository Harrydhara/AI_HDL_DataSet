// `timescale 1ns / 1ps

module tb_tinyqv_system_top;

    // 1. Declare signals to drive the inputs
    reg clk;
    reg rst_n;
    reg [7:0] vga_ui_in_reg; // Rename this to avoid confusion

    // 2. Continuous assignment to a wire if the simulator is strict
    wire [7:0] vga_ui_in_wire = vga_ui_in_reg;

    // Outputs from the DUT
    wire [7:0] vga_uo_out;
    wire [3:0] spi_data_out, spi_data_oe;
    wire spi_clk_out, spi_flash_select, spi_ram_a_select, spi_ram_b_select;

    // 3. Instantiate the Integrated System
    tinyqv_system_top dut (
        .clk(clk),
        .rst_n(rst_n),
        .spi_data_in(4'b0),
        .spi_data_out(spi_data_out),
        .spi_data_oe(spi_data_oe),
        .spi_clk_out(spi_clk_out),
        .spi_flash_select(spi_flash_select),
        .spi_ram_a_select(spi_ram_a_select),
        .spi_ram_b_select(spi_ram_b_select),
        .vga_uo_out(vga_uo_out),
        .vga_ui_in(vga_ui_in_wire) // Connect to the wire
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 0;
        vga_ui_in_reg = 8'h00; // Drive the reg

        #20 rst_n = 1;
        #100;
        
        vga_ui_in_reg = 8'hAA; // Test changing the input
        #1000;
        
        $finish;
    end

endmodule