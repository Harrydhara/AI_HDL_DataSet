/*
 * DMA Bus Arbiter
 *
 * Arbitrates between CPU and DMA for access to the memory bus.
 * CPU has priority - DMA only gets access when CPU is not using the bus.
 *
 * This module sits between the tinyQV CPU and the memory controller,
 * allowing DMA transfers without modifying the original CPU design.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module dma_arbiter (
    input  wire        clk,
    input  wire        rstn,

    // CPU interface (from tinyQV data bus - directly exposed, no memory operations)
    input  wire [27:0] cpu_addr,
    input  wire [1:0]  cpu_write_n,
    input  wire [1:0]  cpu_read_n,
    input  wire [31:0] cpu_data_out,
    output wire [31:0] cpu_data_in,
    output wire        cpu_data_ready,

    // DMA interface
    input  wire [27:0] dma_addr,
    input  wire [1:0]  dma_write_n,
    input  wire [1:0]  dma_read_n,
    input  wire [31:0] dma_data_out,
    output wire [31:0] dma_data_in,
    output wire        dma_data_ready,
    input  wire        dma_request,
    output reg         dma_grant,

    // Memory/Peripheral bus (directly to external memory controller or QSPI)
    output wire [27:0] mem_addr,
    output wire [1:0]  mem_write_n,
    output wire [1:0]  mem_read_n,
    output wire [31:0] mem_data_out,
    input  wire [31:0] mem_data_in,
    input  wire        mem_data_ready
);

    // Arbitration logic
    // CPU has priority - DMA only gets the bus when CPU is idle
    wire cpu_active = (cpu_write_n != 2'b11) || (cpu_read_n != 2'b11);
    wire dma_active = dma_grant && ((dma_write_n != 2'b11) || (dma_read_n != 2'b11));

    // Grant DMA access when:
    // 1. DMA requests the bus
    // 2. CPU is not currently using the bus
    // 3. We're not in the middle of a CPU transaction
    always @(posedge clk) begin
        if (!rstn) begin
            dma_grant <= 1'b0;
        end else begin
            if (dma_request && !cpu_active) begin
                dma_grant <= 1'b1;
            end else if (!dma_request || cpu_active) begin
                // Revoke grant if CPU needs the bus or DMA releases request
                dma_grant <= 1'b0;
            end
        end
    end

    // Bus multiplexing
    // When DMA has grant and is active, use DMA signals
    // Otherwise, use CPU signals
    wire use_dma = dma_grant && dma_active;

    assign mem_addr     = use_dma ? dma_addr     : cpu_addr;
    assign mem_write_n  = use_dma ? dma_write_n  : cpu_write_n;
    assign mem_read_n   = use_dma ? dma_read_n   : cpu_read_n;
    assign mem_data_out = use_dma ? dma_data_out : cpu_data_out;

    // Route memory response back to appropriate master
    assign cpu_data_in    = mem_data_in;
    assign cpu_data_ready = !use_dma ? mem_data_ready : 1'b0;

    assign dma_data_in    = mem_data_in;
    assign dma_data_ready = use_dma ? mem_data_ready : 1'b0;

endmodule
