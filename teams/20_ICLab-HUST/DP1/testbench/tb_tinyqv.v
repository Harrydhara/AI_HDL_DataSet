/* Testbench wrapper for tinyQV (CPU + memory controller).
 *
 * The peripheral bus (data_addr, data_write_n, data_read_n, data_in/out)
 * is left open to cocotb — the test can drive data_ready and data_in to
 * simulate peripheral responses, or simply tie data_ready=1 and data_in=0
 * for instruction-only tests.
 *
 * The SPI flash is modelled by flash_model.v using test_program.hex.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none
`timescale 1ns / 1ps

module tb_tinyqv (
    input         clk,
    input         rstn,

    // Peripheral bus (driven by cocotb)
    input         data_ready,
    input  [31:0] data_in,
    input   [3:0] interrupt_req,
    input         timer_interrupt,

    // Peripheral bus outputs (observed by cocotb)
    output [27:0] data_addr,
    output  [1:0] data_write_n,
    output  [1:0] data_read_n,
    output        data_read_complete,
    output [31:0] data_out,

    // Debug signals
    output        debug_instr_complete,
    output        debug_instr_ready,
    output        debug_instr_valid,
    output        debug_fetch_restart,
    output        debug_data_ready,
    output        debug_interrupt_pending,
    output        debug_branch,
    output        debug_early_branch,
    output        debug_ret,
    output        debug_reg_wen,
    output        debug_counter_0,
    output        debug_data_continue,
    output        debug_stall_txn,
    output        debug_stop_txn,
    output  [3:0] debug_rd
);

`ifdef COCOTB_SIM
initial begin
    $dumpfile("tinyqv.vcd");
    $dumpvars(0, tb_tinyqv);
    #1;
end
`endif

    // ------------------------------------------------------------------ //
    // SPI wires between tinyQV and flash model
    // ------------------------------------------------------------------ //
    wire [3:0] spi_data_out;
    wire [3:0] spi_data_oe;
    wire       spi_clk_out;
    wire       spi_flash_select;
    wire       spi_ram_a_select;
    wire       spi_ram_b_select;

    wire [3:0] spi_data_from_flash;
    wire       flash_oe;

    // spi_data_in: flash drives when flash is selected and OE is low from CPU
    wire [3:0] spi_data_in = (flash_oe && !spi_flash_select) ?
                              spi_data_from_flash : 4'hF;

    // ------------------------------------------------------------------ //
    // DUT
    // ------------------------------------------------------------------ //
    tinyQV dut (
        .clk                  (clk),
        .rstn                 (rstn),

        .data_addr            (data_addr),
        .data_write_n         (data_write_n),
        .data_read_n          (data_read_n),
        .data_read_complete   (data_read_complete),
        .data_out             (data_out),

        .data_ready           (data_ready),
        .data_in              (data_in),

        .interrupt_req        (interrupt_req),
        .timer_interrupt      (timer_interrupt),

        .spi_data_in          (spi_data_in),
        .spi_data_out         (spi_data_out),
        .spi_data_oe          (spi_data_oe),
        .spi_clk_out          (spi_clk_out),

        .spi_flash_select     (spi_flash_select),
        .spi_ram_a_select     (spi_ram_a_select),
        .spi_ram_b_select     (spi_ram_b_select),

        .debug_instr_complete (debug_instr_complete),
        .debug_instr_ready    (debug_instr_ready),
        .debug_instr_valid    (debug_instr_valid),
        .debug_fetch_restart  (debug_fetch_restart),
        .debug_data_ready     (debug_data_ready),
        .debug_interrupt_pending(debug_interrupt_pending),
        .debug_branch         (debug_branch),
        .debug_early_branch   (debug_early_branch),
        .debug_ret            (debug_ret),
        .debug_reg_wen        (debug_reg_wen),
        .debug_counter_0      (debug_counter_0),
        .debug_data_continue  (debug_data_continue),
        .debug_stall_txn      (debug_stall_txn),
        .debug_stop_txn       (debug_stop_txn),
        .debug_rd             (debug_rd)
    );

    // ------------------------------------------------------------------ //
    // Flash model
    // ------------------------------------------------------------------ //
    flash_model i_flash (
        .spi_clk     (spi_clk_out),
        .spi_cs_n    (spi_flash_select),          // active-low
        .spi_data_in (spi_data_out),              // CPU drives to flash
        .spi_data_out(spi_data_from_flash),
        .spi_data_oe (flash_oe)
    );

endmodule
