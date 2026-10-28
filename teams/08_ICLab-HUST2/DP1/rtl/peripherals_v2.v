/*
 * Minimal tinyQV_peripherals wrapper for Winograd accelerator
 * Contains only the tqvp_winograd peripheral at slot 14 (address 0x800_0380-0x800_03BF)
 *
 * SPDX-License-Identifier: Apache-2.0
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
    //   Slot 14: addr_in[10]=0, addr_in[9:6]=14 (4'hE)
    //   Full address: 0x800_0380 - 0x800_03BF

    wire sel_wino = (addr_in[10] == 1'b0) && (addr_in[9:6] == 4'd14);

    // ------------------------------------------------------------------ //
    // tqvp_winograd

    wire [31:0] wino_data_out;
    wire        wino_data_ready;
    wire        wino_interrupt;
    wire [7:0]  wino_uo_out;

    tqvp_winograd i_user_peri14 (
        .clk(clk),
        .rst_n(rst_n),

        .ui_in(ui_in),
        .uo_out(wino_uo_out),

        .address(addr_in[5:0]),
        .data_in(data_in),

        .data_write_n(data_write_n    | {2{~sel_wino}}),
        .data_read_n(data_read_n_peri | {2{~sel_wino}}),

        .data_out(wino_data_out),
        .data_ready(wino_data_ready),

        .user_interrupt(wino_interrupt)
    );

    // ------------------------------------------------------------------ //
    // Data mux

    wire [31:0] data_from_peri       = sel_wino ? wino_data_out   : 32'h0;
    wire        data_ready_from_peri = sel_wino ? wino_data_ready : 1'b1;

    always @(posedge clk) begin
        if (!rst_n) begin
            data_out_hold <= 0;
        end else begin
            if (data_read_complete) data_out_hold <= 0;

            if (!data_out_hold && data_ready_from_peri && data_read_n != 2'b11) begin
                data_out_hold <= 1;
                data_out_r    <= data_from_peri;
            end

            data_ready_r <= read_req && data_ready_from_peri;
        end
    end

    assign data_out   = data_out_r;
    assign data_ready = data_ready_r || data_write_n != 2'b11;

    // ------------------------------------------------------------------ //
    // Outputs

    assign uo_out = wino_uo_out;

    // Winograd interrupt → user_interrupts[14]
    // user_interrupts is [15:2], bit index 14 = position 12 of the wire
    assign user_interrupts = {1'b0, wino_interrupt, 12'b0};

    // Audio not used
    assign audio_select = 1'b0;
    always @(*) audio = 1'b0;

    // Suppress unused-input warnings
    wire _unused = &{ui_in_raw, 1'b0};

endmodule