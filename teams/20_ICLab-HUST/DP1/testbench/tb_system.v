/* System-level testbench: tt_um_tt_tinyQV + flash_model
 *
 * SPI pin mapping inside project.v:
 *   uio_out[0]   = spi_flash_select  (active-low CS)
 *   uio_out[1]   = spi_data_out[0]
 *   uio_out[2]   = spi_data_out[1]
 *   uio_out[3]   = spi_clk_out
 *   uio_out[4]   = spi_data_out[2]
 *   uio_out[5]   = spi_data_out[3]
 *   uio_in[1]    = spi_data_in[0]
 *   uio_in[2]    = spi_data_in[1]
 *   uio_in[4]    = spi_data_in[2]
 *   uio_in[5]    = spi_data_in[3]
 *
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none
`timescale 1ns / 1ps

module tb_system ();

    // ------------------------------------------------------------------ //
    // Dump
    // ------------------------------------------------------------------ //
    initial begin
        $dumpfile("tb_system.vcd");
        $dumpvars(0, tb_system);
        #1;
    end

    // ------------------------------------------------------------------ //
    // DUT signals
    // ------------------------------------------------------------------ //
    reg        clk;
    reg        rst_n;
    reg        ena;
    reg  [7:0] ui_in;
    reg  [7:0] uio_in;

    wire [7:0] uo_out;
    wire [7:0] uio_out;
    wire [7:0] uio_oe;

    // ------------------------------------------------------------------ //
    // DUT: full TinyQV SoC
    // ------------------------------------------------------------------ //
    tt_um_tt_tinyQV i_dut (
        .ui_in  (ui_in),
        .uo_out (uo_out),
        .uio_in (uio_in),
        .uio_out(uio_out),
        .uio_oe (uio_oe),
        .ena    (ena),
        .clk    (clk),
        .rst_n  (rst_n)
    );

    // ------------------------------------------------------------------ //
    // SPI signal extraction
    // ------------------------------------------------------------------ //
    wire spi_clk         = uio_out[3];
    wire spi_flash_cs_n  = uio_out[0];       // active low
    wire [3:0] spi_data_from_cpu = {uio_out[5], uio_out[4],
                                     uio_out[2], uio_out[1]};

    wire [3:0] spi_data_from_flash;
    wire       flash_oe;

    // Feed flash output back into CPU's spi_data_in
    // uio_in[5:4] = spi_data_in[3:2], uio_in[2:1] = spi_data_in[1:0]
    always @(*) begin
        uio_in = 8'h00;
        if (flash_oe) begin
            uio_in[1] = spi_data_from_flash[0];
            uio_in[2] = spi_data_from_flash[1];
            uio_in[4] = spi_data_from_flash[2];
            uio_in[5] = spi_data_from_flash[3];
        end
    end

    // ------------------------------------------------------------------ //
    // Flash model
    // ------------------------------------------------------------------ //
    flash_model i_flash (
        .spi_clk     (spi_clk),
        .spi_cs_n    (spi_flash_cs_n),
        .spi_data_in (spi_data_from_cpu),
        .spi_data_out(spi_data_from_flash),
        .spi_data_oe (flash_oe)
    );

    // ------------------------------------------------------------------ //
    // Default signal values
    // ------------------------------------------------------------------ //
    initial begin
        clk   = 0;
        rst_n = 0;
        ena   = 1;
        ui_in = 8'h00;
    end

endmodule
