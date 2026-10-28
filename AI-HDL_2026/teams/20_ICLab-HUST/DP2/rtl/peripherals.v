/*
 * Minimal tinyQV_peripherals wrapper for new_dp1
 * Contains only the tqvp_dma peripheral at slot 4 (address 0x800_0100-0x800_013F)
 *
 * SPDX-License-Identifier: Apache-2.0
 *
 * PPA Optimisation applied (marked [OPT-P1] in code):
 *
 *  [OPT-P1] Removed intermediate wire data_ready_from_peri.
 *           tqvp_dma hardwires data_ready = 1'b1, therefore
 *           data_ready_from_peri = sel_dma ? 1'b1 : 1'b1 = 1'b1 always.
 *           The factor is dropped from the always-block conditions, removing
 *           a 2-input AND gate on the data_ready_r path and one on the
 *           data_out_hold capture condition.
 */

`default_nettype none

module tinyQV_peripherals #(parameter CLOCK_MHZ=64) (
    input         clk,
    input         rst_n,

    input  [7:0]  ui_in,
    input  [7:0]  ui_in_raw,
    output [7:0]  uo_out,

    output reg    audio,
    output        audio_select,

    input [10:0]  addr_in,
    input [31:0]  data_in,

    input [1:0]   data_write_n,
    input [1:0]   data_read_n,

    output [31:0] data_out,
    output        data_ready,

    input         data_read_complete,

    output [15:2] user_interrupts
);

    wire read_req = data_read_n != 2'b11;

    // Registered data handshake (mirrors full peripherals.v behaviour)
    reg [31:0] data_out_r;
    reg        data_out_hold;
    reg        data_ready_r;

    // Mask read_n while holding a result to avoid re-reading
    wire [1:0] data_read_n_peri = data_read_n | {2{data_ready_r}};

    // ------------------------------------------------------------------ //
    // Address decode
    //   Slot 4: addr_in[10]=0, addr_in[9:6]=4
    //   Full address: 0x800_0100 - 0x800_013F

    wire sel_dma = (addr_in[10] == 1'b0) && (addr_in[9:6] == 4'd4);

    // ------------------------------------------------------------------ //
    // tqvp_dma

    wire [31:0] dma_data_out;
    wire        dma_data_ready;
    wire        dma_interrupt;
    wire [7:0]  dma_uo_out;

    tqvp_dma i_dma (
        .clk(clk),
        .rst_n(rst_n),

        .ui_in(ui_in),
        .uo_out(dma_uo_out),

        .address(addr_in[5:0]),
        .data_in(data_in),

        .data_write_n(data_write_n    | {2{~sel_dma}}),
        .data_read_n(data_read_n_peri | {2{~sel_dma}}),

        .data_out(dma_data_out),
        .data_ready(dma_data_ready),

        .user_interrupt(dma_interrupt)
    );

    // ------------------------------------------------------------------ //
    // Data mux

    wire [31:0] data_from_peri = sel_dma ? dma_data_out : 32'h0;

    // [OPT-P1] tqvp_dma.data_ready is hardwired to 1'b1, so
    //          data_ready_from_peri = sel_dma ? 1'b1 : 1'b1 = 1'b1 always.
    //          The factor is removed from both conditions below, saving two
    //          AND gates on timing-critical read-handshake paths.
    always @(posedge clk) begin
        if (!rst_n) begin
            data_out_hold <= 0;
        end else begin
            if (data_read_complete) data_out_hold <= 0;

            if (!data_out_hold && read_req) begin
                data_out_hold <= 1;
                data_out_r    <= data_from_peri;
            end

            // [OPT-P1] Simplified from: read_req && data_ready_from_peri
            data_ready_r <= read_req;
        end
    end

    assign data_out   = data_out_r;
    assign data_ready = data_ready_r || data_write_n != 2'b11;

    // ------------------------------------------------------------------ //
    // Outputs

    // Drive uo_out directly from DMA peripheral
    assign uo_out = dma_uo_out;

    // DMA interrupt → user_interrupts[4]
    // user_interrupts is [15:2], so user_interrupts[4] is bit 2 of the 14-bit wire
    assign user_interrupts = {11'b0, dma_interrupt, 2'b0};

    // Audio not used
    assign audio_select = 1'b0;
    always @(*) audio = 1'b0;

    // Suppress unused-input warnings
    wire _unused = &{ui_in_raw, 1'b0};

endmodule
