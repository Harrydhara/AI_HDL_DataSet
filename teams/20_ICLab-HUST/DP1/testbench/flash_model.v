/* Behavioral QSPI Flash model for TinyQV simulation.
 *
 * The qspi_controller keeps the flash in continuous fast-read quad I/O mode.
 * For every read transaction it sends:
 *   - ADDR   : 6 nibbles (24-bit address, quad, OE=1 from controller)
 *   - DUMMY1 : 2 nibbles (continuation marker 0xAA, OE=1 from controller)
 *   - DUMMY2 : 4 nibbles (OE=0, flash can ignore or tristate)
 *   - DATA   : nibble pairs per byte (flash drives, high nibble first)
 *
 * Data is loaded from test_program.hex (one byte per line, hex format).
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none
`timescale 1ns / 1ps

module flash_model (
    input      spi_clk,
    input      spi_cs_n,    // active-low chip select
    input [3:0] spi_data_in, // data driven by controller (MOSI quad)
    output reg [3:0] spi_data_out, // data driven by flash (MISO quad)
    output reg       spi_data_oe   // 1 = flash driving the bus
);

    // ---------- memory ----------
    reg [7:0] mem [0:65535];
    initial begin
        $readmemh("test_program.hex", mem);
        spi_data_out = 4'hF;
        spi_data_oe  = 0;
    end

    // ---------- state ----------
    integer  phase;      // 0=ADDR, 1=DUMMY, 2=DATA
    integer  nibble_cnt;
    reg [23:0] addr_reg;
    reg [7:0]  data_buf;

    localparam ADDR_NIBBLES  = 6;
    localparam DUMMY_NIBBLES = 6; // DUMMY1(2) + DUMMY2(4)

    // Reset on CS deassert
    always @(posedge spi_cs_n or negedge spi_cs_n) begin
        if (spi_cs_n) begin
            // CS deasserted → go idle
            spi_data_oe  <= 0;
            spi_data_out <= 4'hF;
            phase        <= 0;
            nibble_cnt   <= 0;
            addr_reg     <= 0;
        end
    end

    // Sample on rising SPI clock (controller drives on falling, stable on rising)
    always @(posedge spi_clk) begin
        if (!spi_cs_n) begin
            case (phase)
                // --- ADDR: 6 nibbles, high nibble of addr first ---
                0: begin
                    addr_reg   <= {addr_reg[19:0], spi_data_in};
                    if (nibble_cnt == ADDR_NIBBLES - 1) begin
                        phase      <= 1;
                        nibble_cnt <= 0;
                    end else begin
                        nibble_cnt <= nibble_cnt + 1;
                    end
                end

                // --- DUMMY: 6 nibbles, ignore data ---
                1: begin
                    if (nibble_cnt == DUMMY_NIBBLES - 1) begin
                        phase      <= 2;
                        nibble_cnt <= 0;
                        // Pre-load first byte
                        data_buf   <= mem[addr_reg[15:0]];
                    end else begin
                        nibble_cnt <= nibble_cnt + 1;
                    end
                end

                // --- DATA: drive nibbles on negedge (prepared here) ---
                2: begin
                    // nibble_cnt: even=high nibble just sampled, odd=low nibble just sampled
                    // Advance to next byte AFTER the low nibble (odd count)
                    if (nibble_cnt[0] == 1'b1) begin
                        // low nibble was just clocked out, move to next byte
                        addr_reg   <= addr_reg + 1;
                        data_buf   <= mem[(addr_reg + 1) & 16'hFFFF];
                    end
                    nibble_cnt <= nibble_cnt + 1;
                end
            endcase
        end
    end

    // Drive data on falling SPI clock edge (so it's stable before next rising)
    always @(negedge spi_clk) begin
        if (!spi_cs_n && phase == 2) begin
            spi_data_oe <= 1;
            if (nibble_cnt[0] == 1'b0)
                spi_data_out <= data_buf[7:4]; // high nibble first
            else
                spi_data_out <= data_buf[3:0]; // low nibble
        end else if (spi_cs_n) begin
            spi_data_oe  <= 0;
            spi_data_out <= 4'hF;
        end
    end

endmodule
