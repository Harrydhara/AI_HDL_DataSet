`timescale 1ns/1ps

module crc_datapath_tb;

  reg clk;
  reg rst_n;
  reg start;
  reg reset;
  reg [31:0] seed;
  reg [15:0] len;
  reg [31:0] data_in;
  wire busy;
  wire done;
  wire [31:0] result;

  // DUT
  crc_datapath uut (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .reset(reset),
    .seed(seed),
    .len(len),
    .data_in(data_in),
    .busy(busy),
    .done(done),
    .result(result)
  );

  // Clock
  initial clk = 0;
  always #5 clk = ~clk;

  // Waveform dump
  initial begin
    $dumpfile("crc.vcd");
    $dumpvars(0, crc_datapath_tb);
    $display("VCD: crc.vcd opened at time %0t", $time);
  end

  // Synchronous single-word run task
  task run_single_sync(input [31:0] din, input [31:0] expected_crc);
    begin
      // present data and seed, wait a posedge so DUT can sample stable data
      data_in = din;
      seed    = 32'hFFFFFFFF;
      len     = 16'd1;

      // ensure data stable at a posedge, then assert start synchronously
      @(posedge clk);
      start <= 1'b1;
      @(posedge clk);
      start <= 1'b0;

      // wait for done
      wait(done == 1);
      @(posedge clk);

      if (result !== expected_crc) begin
        $display("FAIL: Input %h, Expected %h, Got %h", din, expected_crc, result);
      end else begin
        $display("PASS: Input %h, CRC %h", din, result);
      end

      // clear for next test
      @(posedge clk);
      len = 16'd0;
      data_in = 32'h0;
      seed = 32'hFFFFFFFF;
      #1;
    end
  endtask

  initial begin
    // Init
    start = 0;
    reset = 0;
    seed = 32'hFFFFFFFF;
    len = 0;
    data_in = 32'h0;
    rst_n = 0;

    // release reset
    #20 rst_n = 1;
    @(posedge clk);

    // Regression vectors with Python-generated expected CRCs (LSB-first)
    run_single_sync(32'hA5A5A5A5, 32'hD0CA6977);
    run_single_sync(32'h5A5A5A5A, 32'h0E714994);
    run_single_sync(32'h00000000, 32'h00000000);
    run_single_sync(32'hFFFFFFFF, 32'hDEBB20E3);
    run_single_sync(32'h12345678, 32'h8E2958CE);
    run_single_sync(32'hDEADBEEF, 32'h3B1EBF03);

    #50;
    $display("Regression completed.");
    $finish;
  end

endmodule
