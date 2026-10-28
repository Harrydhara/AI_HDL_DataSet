`timescale 1ns / 1ps

module tb_dma_fifo_latch;

    // Parameters
    parameter DEPTH = 16;
    parameter WIDTH = 32;

    // Signals
    reg              clk;
    reg              rst_n;
    reg              wr_en;
    reg  [WIDTH-1:0] wdata;
    reg              rd_en;
    wire [WIDTH-1:0] rdata;
    wire             full;
    wire             empty;

    // Instantiate DUT (Device Under Test)
    dma_fifo_latch #(
        .DEPTH(DEPTH)
    ) u_fifo (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(wr_en),
        .wdata(wdata),
        .rd_en(rd_en),
        .rdata(rdata),
        .full(full),
        .empty(empty)
    );

    // Clock Gen
    initial clk = 0;
    always #5 clk = ~clk; // 100MHz

    integer i;

    initial begin
        $dumpfile("fifo_wave.vcd");
        $dumpvars(0, tb_dma_fifo_latch);
        
        $display("=== [TEST] Starting FIFO Test ===");

        // 1. Reset
        rst_n = 0; wr_en = 0; rd_en = 0; wdata = 0;
        #20;
        rst_n = 1;
        #10;
        
        // Check initial state
        if (empty !== 1 || full !== 0) $error("[FAIL] Reset state incorrect");
        else $display("[PASS] Reset state OK");

        // 2. Write untill FULL
        $display("=== [TEST] Writing Data until FULL ===");
        for (i = 0; i < DEPTH; i = i + 1) begin
            @(posedge clk);
            if (!full) begin
                wr_en <= 1;
                wdata <= 32'hA000_0000 + i; // Pattern A0000000, A0000001...
            end
        end
        @(posedge clk);
        wr_en <= 0;
        
        #10;
        if (full) $display("[PASS] FIFO is FULL");
        else $error("[FAIL] FIFO should be FULL but isn't");

        // 3. Read untill EMPTY
        $display("=== [TEST] Reading Data until EMPTY ===");
        for (i = 0; i < DEPTH; i = i + 1) begin
            @(posedge clk);
            if (!empty) begin
                rd_en <= 1;
                // Check data immediately (Latch based often valid instantly or next edge depending on design)
                // Here we verify at next edge to be safe
            end
        end
        
        @(posedge clk);
        rd_en <= 0;
        #10;
        if (empty) $display("[PASS] FIFO is EMPTY");
        else $error("[FAIL] FIFO should be EMPTY");

        // 4. Concurrent Read/Write (Ping-Pong)
        $display("=== [TEST] Concurrent Read/Write ===");
        @(posedge clk);
        wr_en <= 1; wdata <= 32'hDEAD_BEEF;
        @(posedge clk);
        wr_en <= 0; rd_en <= 1;
        @(posedge clk); // Data should be valid here
        if (rdata == 32'hDEAD_BEEF) $display("[PASS] Data Integrity Check OK");
        else $error("[FAIL] Data Mismatch! Exp: DEADBEEF, Got: %h", rdata);
        
        rd_en <= 0;
        #20;
        $finish;
    end

endmodule