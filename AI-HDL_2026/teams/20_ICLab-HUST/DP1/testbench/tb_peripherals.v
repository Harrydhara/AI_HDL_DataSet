`default_nettype none

/* Testbench wrapper for tinyQV_peripherals.
   Exposes all bus signals for cocotb-driven tests. */
module tb_peripherals (
    input         clk,
    input         rst_n,

    input  [7:0]  ui_in,
    input  [7:0]  ui_in_raw,
    output [7:0]  uo_out,

    output        audio,
    output        audio_select,

    input  [10:0] addr_in,
    input  [31:0] data_in,
    input  [1:0]  data_write_n,
    input  [1:0]  data_read_n,

    output [31:0] data_out,
    output        data_ready,

    input         data_read_complete,

    output [15:2] user_interrupts
);

`ifdef COCOTB_SIM
initial begin
    $dumpfile("peripherals.vcd");
    $dumpvars(0, tb_peripherals);
    #1;
end
`endif

    tinyQV_peripherals #(.CLOCK_MHZ(64)) dut (
        .clk              (clk),
        .rst_n            (rst_n),
        .ui_in            (ui_in),
        .ui_in_raw        (ui_in_raw),
        .uo_out           (uo_out),
        .audio            (audio),
        .audio_select     (audio_select),
        .addr_in          (addr_in),
        .data_in          (data_in),
        .data_write_n     (data_write_n),
        .data_read_n      (data_read_n),
        .data_out         (data_out),
        .data_ready       (data_ready),
        .data_read_complete(data_read_complete),
        .user_interrupts  (user_interrupts)
    );

endmodule
