`default_nettype none
`timescale 1ns / 1ps

/*
 * tb_main.v
 * Passive Testbench - Hands full control to Python (test.py)
 */
module tb_main ();

    // --- 1. Signal Declarations ---
    reg clk;
    reg rst_n;
    reg ena;
    
    // TinyTapeout I/O
    reg  [7:0] ui_in;     // Dedicated Inputs
    reg  [7:0] uio_in;    // Bidirectional Inputs
    wire [7:0] uo_out;    // Dedicated Outputs
    wire [7:0] uio_out;   // Bidirectional Outputs
    wire [7:0] uio_oe;    // Bidirectional Enable

    // Handshake signal (kept for compatibility, but unused here)
    reg tb_done;

    // --- 2. Clock Generation ---
    // 100 MHz Clock (10ns period)
    initial clk = 0;
    always #5 clk = ~clk;

    // --- 3. DUT Instantiation ---
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

    // --- 4. Whitebox Probes ---
    // Expose internal signals for Python to see
    wire [7:0]  debug_rx_shifter = dut.user_peripheral.rx_shifter;
    wire [31:0] debug_tx_reg     = dut.user_peripheral.tx_reg;

    // --- 5. Simulation Setup ---
    initial begin
        // Setup Waveform Dump
        $dumpfile("tb_main.vcd");
        $dumpvars(0, tb_main);

        // --- KEY CHANGE: Passive Initialization ---
        // We initialize signals to 0 once at time 0.
        // We DO NOT toggle them again in Verilog. 
        // This allows 'test.py' to drive 'rst_n' and SPI pins without fighting Verilog.
        tb_done = 0;
        rst_n = 0; 
        ena = 1; 
        ui_in = 8'h00; 
        uio_in = 8'h00;
        
        // Note: No $finish here. Python controls the simulation end.
    end

endmodule