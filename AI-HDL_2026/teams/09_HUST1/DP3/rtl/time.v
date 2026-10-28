/*
 * Copyright (c) 2024 Michael Bell
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

// Simple 32-bit register with write enable
// Note: Renamed comment to "register" as implementation is a D-FF, not a latch.
module latch_reg32_p (
    input  wire        clk,
    input  wire        wen,
    input  wire [31:0] data_in,
    output reg  [31:0] data_out
);
    always @(posedge clk) begin
        if (wen)
            data_out <= data_in;
    end
endmodule

// mtime and mtimecmp implementation for TinyQV
module tinyQV_time (
    input  wire        clk,
    input  wire        rstn,
    input  wire        time_pulse,      // High for one clock once per microsecond.
    input  wire        set_mtime,
    input  wire        set_mtimecmp,
    input  wire [31:0] data_in,
    input  wire        read_mtimecmp,   // data_out set to mtime if this is low.
    output reg  [31:0] data_out,
    output reg         timer_interrupt
);

    reg [31:0] mtime;
    reg [31:0] mtimecmp;

    // Write to mtimecmp
    always @(posedge clk) begin
        if (!rstn)
            mtimecmp <= 32'd0;
        else if (set_mtimecmp)
            mtimecmp <= data_in;
    end

    // Write to mtime
    always @(posedge clk) begin
        if (!rstn)
            mtime <= 32'd0;
        else if (set_mtime)
            mtime <= data_in;
        else if (time_pulse)
            mtime <= mtime + 32'd1;
    end

    // data output mux logic
    always @(*) begin
        if (read_mtimecmp)
            data_out = mtimecmp;
        else
            data_out = mtime;
    end

    // Timer interrupt logic
    // Logic: If (mtime - mtimecmp) is a small positive number, interrupt fires.
    // Checking the top 2 bits handles the wrap-around logic for comparison.
    always @(posedge clk) begin
        if (!rstn) begin
            timer_interrupt <= 1'b0;
        end else begin
            // Check if (mtime - mtimecmp) is in [0, 2^30)
            if (((mtime - mtimecmp) >> 30) == 2'b00)
                timer_interrupt <= 1'b1;
            else
                timer_interrupt <= 1'b0;
        end
    end

endmodule