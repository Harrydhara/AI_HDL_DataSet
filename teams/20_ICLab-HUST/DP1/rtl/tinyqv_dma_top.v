/*
 * TinyQV with DMA Top Wrapper
 *
 * This module wraps the TinyQV CPU components and adds DMA functionality.
 * Instead of using the tinyQV wrapper, we instantiate tinyqv_cpu and
 * tinyqv_mem_ctrl directly to properly integrate the DMA arbiter.
 *
 * Architecture:
 *   - tinyqv_cpu: CPU core with instruction/data interfaces
 *   - tinyqv_mem_ctrl: Memory controller with QSPI interface
 *   - dma_arbiter: Arbitrates memory bus between CPU and DMA
 *   - tinyqv_dma: DMA controller mapped at 0x8001000-0x800101F
 *
 * Data Flow:
 *   - Instruction fetch: CPU -> mem_ctrl (direct, no arbitration)
 *   - CPU memory access: CPU -> arbiter -> mem_ctrl
 *   - DMA memory access: DMA -> arbiter -> mem_ctrl
 *   - CPU peripheral access: CPU -> external (bypass arbiter)
 *   - CPU DMA config: CPU -> DMA controller registers
 *
 * DMA Peripheral Address Map (offset from 0x8001000):
 *   0x00: Source Address (28-bit)
 *   0x04: Destination Address (28-bit)
 *   0x08: Transfer Count (16-bit)
 *   0x0C: Control/Status Register
 *   0x10: Status (remaining count)
 *
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tinyqv_dma_top (
    input  wire        clk,
    input  wire        rstn,

    // External peripheral interface (directly exposed from CPU)
    output wire [27:0] data_addr,
    output wire [1:0]  data_write_n,
    output wire [1:0]  data_read_n,
    output wire        data_read_complete,
    output wire [31:0] data_out,

    input  wire        data_ready,
    input  wire [31:0] data_in,

    // Interrupt inputs (directly to CPU)
    input  wire [15:0] interrupt_req,
    input  wire        time_pulse,

    // External QSPI interface
    input  wire [3:0]  spi_data_in,
    output wire [3:0]  spi_data_out,
    output wire [3:0]  spi_data_oe,
    output wire        spi_clk_out,
    output wire        spi_flash_select,
    output wire        spi_ram_a_select,
    output wire        spi_ram_b_select,

    // DMA interrupt output (directly exposed for external use)
    output wire        dma_interrupt,

    // Debug signals from CPU
    output wire        debug_instr_complete,
    output wire        debug_instr_ready,
    output wire        debug_instr_valid,
    output wire        debug_fetch_restart,
    output wire        debug_data_ready,
    output wire        debug_interrupt_pending,
    output wire        debug_branch,
    output wire        debug_early_branch,
    output wire        debug_ret,
    output wire        debug_reg_wen,
    output wire        debug_counter_0,
    output wire        debug_data_continue,
    output wire        debug_stall_txn,
    output wire        debug_stop_txn,
    output wire [3:0]  debug_rd
);

    // =========================================================================
    // Parameters
    // =========================================================================

    // DMA peripheral address range check
    // DMA is at 0x8001000 - 0x800101F (peripheral space, 32 bytes)
    localparam DMA_BASE_ADDR = 28'h8001000;

    // =========================================================================
    // CPU Internal Signals
    // =========================================================================

    // Instruction interface (CPU <-> mem_ctrl, direct connection)
    wire [23:1] instr_addr;
    wire        instr_fetch_restart;
    wire        instr_fetch_stall;
    wire        instr_fetch_started;
    wire        instr_fetch_stopped;
    wire [15:0] instr_data;
    wire        instr_ready;

    // CPU data interface (directly from CPU)
    wire [27:0] cpu_data_addr;
    wire [1:0]  cpu_data_write_n;
    wire [1:0]  cpu_data_read_n;
    wire        cpu_data_read_complete;
    wire [31:0] cpu_data_out;
    wire        cpu_data_continue;
    wire        cpu_data_ready;
    wire [31:0] cpu_data_in;

    // =========================================================================
    // DMA Controller Signals
    // =========================================================================

    // DMA configuration interface
    wire        dma_cfg_write;
    wire        dma_cfg_read;
    wire [3:0]  dma_cfg_addr;
    wire [31:0] dma_cfg_data_out;

    // DMA memory interface
    wire [27:0] dma_mem_addr;
    wire [1:0]  dma_mem_write_n;
    wire [1:0]  dma_mem_read_n;
    wire [31:0] dma_mem_data_out;
    wire [31:0] dma_mem_data_in;
    wire        dma_mem_ready;
    wire        dma_request;
    wire        dma_grant;

    // =========================================================================
    // Arbiter Signals (between CPU/DMA and mem_ctrl)
    // =========================================================================

    // CPU side of arbiter (memory space only)
    wire [27:0] cpu_arb_addr;
    wire [1:0]  cpu_arb_write_n;
    wire [1:0]  cpu_arb_read_n;
    wire [31:0] cpu_arb_data_out;
    wire [31:0] cpu_arb_data_in;
    wire        cpu_arb_ready;

    // Arbiter output to mem_ctrl
    wire [27:0] arb_mem_addr;
    wire [1:0]  arb_mem_write_n;
    wire [1:0]  arb_mem_read_n;
    wire [31:0] arb_mem_data_out;
    wire [31:0] arb_mem_data_in;
    wire        arb_mem_ready;

    // =========================================================================
    // Address Decode Logic
    // =========================================================================

    // Check if CPU is accessing DMA peripheral
    wire is_dma_access = (cpu_data_addr[27:5] == DMA_BASE_ADDR[27:5]);

    // Check if CPU is accessing memory space (QSPI Flash/RAM)
    wire is_mem_access = (cpu_data_addr[27:25] == 3'b000);

    // Check if CPU is accessing external peripherals (not DMA, not memory)
    wire is_peripheral_access = !is_mem_access && !is_dma_access;

    // =========================================================================
    // DMA Configuration Interface
    // =========================================================================

    assign dma_cfg_write = is_dma_access && (cpu_data_write_n != 2'b11);
    assign dma_cfg_read  = is_dma_access && (cpu_data_read_n != 2'b11);
    assign dma_cfg_addr  = cpu_data_addr[5:2];  // Word-aligned access

    // =========================================================================
    // CPU to Arbiter Interface (Memory Space Only)
    // =========================================================================

    assign cpu_arb_addr     = cpu_data_addr;
    assign cpu_arb_write_n  = is_mem_access ? cpu_data_write_n : 2'b11;
    assign cpu_arb_read_n   = is_mem_access ? cpu_data_read_n  : 2'b11;
    assign cpu_arb_data_out = cpu_data_out;

    // =========================================================================
    // External Peripheral Interface (Pass-through, excluding DMA and Memory)
    // =========================================================================

    assign data_addr          = cpu_data_addr;
    assign data_write_n       = is_peripheral_access ? cpu_data_write_n : 2'b11;
    assign data_read_n        = is_peripheral_access ? cpu_data_read_n  : 2'b11;
    assign data_read_complete = cpu_data_read_complete;
    assign data_out           = cpu_data_out;

    // =========================================================================
    // CPU Data Input Multiplexing
    // Priority: DMA config > Memory (via arbiter) > External peripheral
    // =========================================================================

    assign cpu_data_in = is_dma_access ? dma_cfg_data_out :
                         is_mem_access ? cpu_arb_data_in :
                         data_in;

    assign cpu_data_ready = is_dma_access ? 1'b1 :  // DMA config is always ready (single cycle)
                            is_mem_access ? cpu_arb_ready :
                            data_ready;

    // =========================================================================
    // Reset Synchronization (same as original tinyQV)
    // =========================================================================

    // Use a positive edge triggered reset for the CPU, to improve timing
    reg rst_reg_n;
    always @(posedge clk) rst_reg_n <= rstn;

    // =========================================================================
    // CPU Core Instantiation
    // =========================================================================

    tinyqv_cpu cpu (
        .clk(clk),
        .rstn(rst_reg_n),

        // Instruction interface (direct to mem_ctrl)
        .instr_addr(instr_addr),
        .instr_fetch_restart(instr_fetch_restart),
        .instr_fetch_stall(instr_fetch_stall),
        .instr_fetch_started(instr_fetch_started),
        .instr_fetch_stopped(instr_fetch_stopped),
        .instr_data_in(instr_data),
        .instr_ready(instr_ready),

        // Interrupt (combine external + DMA interrupt)
        .interrupt_req(interrupt_req | {15'b0, dma_interrupt}),

        // Data interface (goes through address decode)
        .data_addr(cpu_data_addr),
        .data_write_n(cpu_data_write_n),
        .data_read_n(cpu_data_read_n),
        .data_read_complete(cpu_data_read_complete),
        .data_out(cpu_data_out),
        .data_continue(cpu_data_continue),
        .data_ready(cpu_data_ready),
        .data_in(cpu_data_in),

        // Time
        .time_pulse(time_pulse),

        // Debug
        .debug_instr_complete(debug_instr_complete),
        .debug_instr_valid(debug_instr_valid),
        .debug_interrupt_pending(debug_interrupt_pending),
        .debug_branch(debug_branch),
        .debug_early_branch(debug_early_branch),
        .debug_ret(debug_ret),
        .debug_reg_wen(debug_reg_wen),
        .debug_counter_0(debug_counter_0),
        .debug_rd(debug_rd)
    );

    // =========================================================================
    // DMA Controller Instantiation
    // =========================================================================

    tinyqv_dma i_dma (
        .clk(clk),
        .rstn(rstn),

        // Configuration interface (from CPU when accessing DMA registers)
        .cfg_write(dma_cfg_write),
        .cfg_read(dma_cfg_read),
        .cfg_addr(dma_cfg_addr),
        .cfg_data_in(cpu_data_out),
        .cfg_data_out(dma_cfg_data_out),

        // Memory interface (to arbiter)
        .dma_addr(dma_mem_addr),
        .dma_write_n(dma_mem_write_n),
        .dma_read_n(dma_mem_read_n),
        .dma_data_out(dma_mem_data_out),
        .dma_data_in(dma_mem_data_in),
        .dma_ready(dma_mem_ready),

        // Arbitration
        .dma_request(dma_request),
        .dma_grant(dma_grant),

        // Interrupt
        .dma_interrupt(dma_interrupt)
    );

    // =========================================================================
    // Bus Arbiter Instantiation
    // Arbitrates between CPU and DMA for memory access
    // CPU has priority - DMA only gets access when CPU is not using the bus
    // =========================================================================

    dma_arbiter i_arbiter (
        .clk(clk),
        .rstn(rstn),

        // CPU side (memory operations only)
        .cpu_addr(cpu_arb_addr),
        .cpu_write_n(cpu_arb_write_n),
        .cpu_read_n(cpu_arb_read_n),
        .cpu_data_out(cpu_arb_data_out),
        .cpu_data_in(cpu_arb_data_in),
        .cpu_data_ready(cpu_arb_ready),

        // DMA side
        .dma_addr(dma_mem_addr),
        .dma_write_n(dma_mem_write_n),
        .dma_read_n(dma_mem_read_n),
        .dma_data_out(dma_mem_data_out),
        .dma_data_in(dma_mem_data_in),
        .dma_data_ready(dma_mem_ready),
        .dma_request(dma_request),
        .dma_grant(dma_grant),

        // Memory side (to mem_ctrl)
        .mem_addr(arb_mem_addr),
        .mem_write_n(arb_mem_write_n),
        .mem_read_n(arb_mem_read_n),
        .mem_data_out(arb_mem_data_out),
        .mem_data_in(arb_mem_data_in),
        .mem_data_ready(arb_mem_ready)
    );

    // =========================================================================
    // Memory Controller Instantiation
    // Handles instruction fetch and data access to QSPI Flash/RAM
    // =========================================================================

    tinyqv_mem_ctrl mem (
        .clk(clk),
        .rstn(rstn),

        // Instruction interface (direct from CPU, no arbitration needed)
        .instr_addr(instr_addr),
        .instr_fetch_restart(instr_fetch_restart),
        .instr_fetch_stall(instr_fetch_stall),
        .instr_fetch_started(instr_fetch_started),
        .instr_fetch_stopped(instr_fetch_stopped),
        .instr_data(instr_data),
        .instr_ready(instr_ready),

        // Data interface (from arbiter, shared by CPU and DMA)
        .data_addr(arb_mem_addr[24:0]),  // mem_ctrl uses 25-bit address
        .data_write_n(arb_mem_write_n),
        .data_read_n(arb_mem_read_n),
        .data_to_write(arb_mem_data_out),
        .data_continue(cpu_data_continue),  // Note: DMA doesn't use continue
        .data_ready(arb_mem_ready),
        .data_from_read(arb_mem_data_in),

        // QSPI interface (directly to external pins)
        .spi_data_in(spi_data_in),
        .spi_data_out(spi_data_out),
        .spi_data_oe(spi_data_oe),
        .spi_flash_select(spi_flash_select),
        .spi_ram_a_select(spi_ram_a_select),
        .spi_ram_b_select(spi_ram_b_select),
        .spi_clk_out(spi_clk_out),

        // Debug
        .debug_stall_txn(debug_stall_txn),
        .debug_stop_txn(debug_stop_txn)
    );

    // =========================================================================
    // Debug Signal Assignments
    // =========================================================================

    assign debug_instr_ready   = instr_ready;
    assign debug_fetch_restart = instr_fetch_restart;
    assign debug_data_ready    = cpu_data_ready;
    assign debug_data_continue = cpu_data_continue;

endmodule
