`default_nettype none

/* Testbench wrapper for tinyQV_time.
   Exposes all signals directly for cocotb control. */
module tb_time (
    input        clk,
    input        rstn,

    input        time_pulse,
    input        set_mtime,
    input        set_mtimecmp,
    input [31:0] data_in,
    input        read_mtimecmp,

    output [31:0] data_out,
    output        timer_interrupt
);

`ifdef COCOTB_SIM
initial begin
    $dumpfile("time.vcd");
    $dumpvars(0, tb_time);
    #1;
end
`endif

    tinyQV_time dut (
        .clk            (clk),
        .rstn           (rstn),
        .time_pulse     (time_pulse),
        .set_mtime      (set_mtime),
        .set_mtimecmp   (set_mtimecmp),
        .data_in        (data_in),
        .read_mtimecmp  (read_mtimecmp),
        .data_out       (data_out),
        .timer_interrupt(timer_interrupt)
    );

endmodule
