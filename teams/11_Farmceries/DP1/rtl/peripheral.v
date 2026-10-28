/*
 * Copyright (c) 2025 Member A
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

/**
 * TinyQV Secure UART Peripheral with AES-128 Encryption
 * 
 * Memory-mapped UART peripheral with hardware encryption for TinyQV RISC-V core.
 * Supports 4 baud rates: 9600, 19200, 38400, 115200
 * 
 * Register Map:
 * 0x00 - CTRL:      [3:0] baud_sel, [4] tx_enable, [5] rx_enable, [6] aes_enable
 * 0x04 - STATUS:    [0] tx_busy, [1] rx_ready, [2] rx_error, [3] aes_busy
 * 0x08 - TX_DATA:   Write to transmit byte
 * 0x0C - RX_DATA:   Read received byte
 * 0x10 - INT_EN:    [0] tx_done_int_en, [1] rx_ready_int_en
 * 0x14 - INT_CLR:   [0] clear_tx_int, [1] clear_rx_int
 * 0x18 - AES_KEY_0: AES key bits [31:0]
 * 0x1C - AES_KEY_1: AES key bits [63:32]
 * 0x20 - AES_KEY_2: AES key bits [95:64]
 * 0x24 - AES_KEY_3: AES key bits [127:96]
 * 
 * Physical Connections:
 * - UART TX: uo_out[0]
 * - UART RX: ui_in[7]
 */
module tqvp_basit_uart (
    input         clk,          // Clock - TinyQV runs at 70MHz
    input         rst_n,        // Reset_n - low to reset

    input  [7:0]  ui_in,        // Input PMOD - ui_in[7] is UART RX
    output [7:0]  uo_out,       // Output PMOD - uo_out[0] is UART TX

    input [5:0]   address,      // Register address
    input [31:0]  data_in,      // Write data

    input [1:0]   data_write_n, // Write control
    input [1:0]   data_read_n,  // Read control
    
    output [31:0] data_out,     // Read data
    output        data_ready,   // Read valid

    output        user_interrupt  // UART interrupt
);

    // Default is full AES-128 block buffering. The PPA script can override this
    // in its working copy to run reduced-block experiments (1/2/4/8 bytes).
    localparam integer AES_BLOCK_BYTES_CFG = 16;

    // UART TX/RX wires
    wire uart_tx_wire;
    wire rts_n_unused;  // RTS flow control output (unused)
    wire uart_rx_wire;
    
    // Connect UART RX from ui_in[7], TX to uo_out[0]
    assign uart_rx_wire = ui_in[7];
    assign uo_out = {7'b0, uart_tx_wire};
    
    // Instantiate Secure UART peripheral with AES-128 encryption (Phase 2)
    secure_uart_peripheral #(
        .AES_BLOCK_BYTES(AES_BLOCK_BYTES_CFG)
    ) secure_uart (
        .clk(clk),
        .rst_n(rst_n),
        
        // CPU interface
        .address(address),
        .data_in(data_in),
        .data_write_n(data_write_n),
        .data_read_n(data_read_n),
        .data_out(data_out),
        .data_ready(data_ready),
        
        // Physical UART
        .uart_rx_pin(uart_rx_wire),
        .uart_tx_pin(uart_tx_wire),
        
        // Flow control (unused)
        .cts_n(1'b0),
        .rts_n(rts_n_unused),  // Connect but don't use
        
        // Interrupt
        .interrupt(user_interrupt)
    );

endmodule

`default_nettype wire
