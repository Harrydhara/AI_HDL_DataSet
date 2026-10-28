`default_nettype none
`timescale 1ns / 1ps

/*
 * tb_custom.v
 * "Smart" Testbench for Advanced Verification
 */
module tb_custom ();

    // --- 1. System Signals ---
    reg clk;
    reg rst_n;
    reg ena;
    
    // --- 2. TinyTapeout I/O ---
    reg  [7:0] ui_in;     // Dedicated Inputs
    reg  [7:0] uio_in;    // Bidirectional Inputs
    wire [7:0] uo_out;    // Dedicated Outputs
    wire [7:0] uio_out;   // Bidirectional Outputs
    wire [7:0] uio_oe;    // Bidirectional Enable

    // --- 3. Clock Generation (100MHz) ---
    initial clk = 0;
    always #5 clk = ~clk;

    // --- 4. Instantiate the Wrapper ---
    // We name this instance 'dut' so Python can easily find it
    tt_um_tqv_peripheral_harness dut (
        .ui_in  (ui_in),
        .uo_out (uo_out),
        .uio_in (uio_in),
        .uio_out(uio_out),
        .uio_oe (uio_oe),
        .ena    (ena),
        .clk    (clk),
        .rst_n  (rst_n)
    );

    // --- 5. Whitebox Probes ---
    // These must be at the MODULE LEVEL (not inside 'initial').
    // They peek into the hierarchy: dut -> user_peripheral -> signal
    
    wire [7:0]  debug_rx_shifter = dut.user_peripheral.rx_shifter;
    wire [3:0]  debug_rx_bit_idx = dut.user_peripheral.rx_bit_idx;
    wire [31:0] debug_tx_reg     = dut.user_peripheral.tx_reg;
    wire [9:0]  debug_tx_frame   = dut.user_peripheral.tx_frame;

    // --- 6. Simulation Setup ---
    initial begin
        $dumpfile("tb_custom.vcd");
        $dumpvars(0, tb_custom);
        
        // Initialize inputs
        rst_n = 0;
        ena = 1;
        ui_in = 8'h00;
        uio_in = 8'h00;

        // Reset release happens in Python or here
        #20 rst_n = 1;
    end

endmodule