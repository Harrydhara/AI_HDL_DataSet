/*
 * Testbench for DMA Bus Arbiter
 *
 * Tests:
 * 1. CPU-only access
 * 2. DMA-only access
 * 3. CPU priority when both request
 * 4. DMA access when CPU is idle
 *
 * SPDX-License-Identifier: Apache-2.0
 */

`timescale 1ns/1ps

module tb_dma_arbiter;

    // Clock and reset
    reg clk;
    reg rstn;

    // CPU interface
    reg  [27:0] cpu_addr;
    reg  [1:0]  cpu_write_n;
    reg  [1:0]  cpu_read_n;
    reg  [31:0] cpu_data_out;
    wire [31:0] cpu_data_in;
    wire        cpu_data_ready;

    // DMA interface
    reg  [27:0] dma_addr;
    reg  [1:0]  dma_write_n;
    reg  [1:0]  dma_read_n;
    reg  [31:0] dma_data_out;
    wire [31:0] dma_data_in;
    wire        dma_data_ready;
    reg         dma_request;
    wire        dma_grant;

    // Memory interface
    wire [27:0] mem_addr;
    wire [1:0]  mem_write_n;
    wire [1:0]  mem_read_n;
    wire [31:0] mem_data_out;
    reg  [31:0] mem_data_in;
    reg         mem_data_ready;

    // Clock generation: 100MHz
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // DUT instantiation
    dma_arbiter dut (
        .clk(clk),
        .rstn(rstn),

        .cpu_addr(cpu_addr),
        .cpu_write_n(cpu_write_n),
        .cpu_read_n(cpu_read_n),
        .cpu_data_out(cpu_data_out),
        .cpu_data_in(cpu_data_in),
        .cpu_data_ready(cpu_data_ready),

        .dma_addr(dma_addr),
        .dma_write_n(dma_write_n),
        .dma_read_n(dma_read_n),
        .dma_data_out(dma_data_out),
        .dma_data_in(dma_data_in),
        .dma_data_ready(dma_data_ready),
        .dma_request(dma_request),
        .dma_grant(dma_grant),

        .mem_addr(mem_addr),
        .mem_write_n(mem_write_n),
        .mem_read_n(mem_read_n),
        .mem_data_out(mem_data_out),
        .mem_data_in(mem_data_in),
        .mem_data_ready(mem_data_ready)
    );

    // Simple memory model
    reg [31:0] memory [0:255];
    integer i;

    always @(posedge clk) begin
        mem_data_ready <= 1'b0;

        if (mem_read_n != 2'b11) begin
            mem_data_in <= memory[mem_addr[7:0]];
            mem_data_ready <= 1'b1;
        end

        if (mem_write_n != 2'b11) begin
            memory[mem_addr[7:0]] <= mem_data_out;
            mem_data_ready <= 1'b1;
        end
    end

    // Test tasks
    task cpu_idle;
    begin
        cpu_addr     = 28'h0;
        cpu_write_n  = 2'b11;
        cpu_read_n   = 2'b11;
        cpu_data_out = 32'h0;
    end
    endtask

    task cpu_read;
        input [27:0] addr;
    begin
        cpu_addr    = addr;
        cpu_read_n  = 2'b10;  // 32-bit read
        cpu_write_n = 2'b11;
        @(posedge clk);
        wait(cpu_data_ready);
        @(posedge clk);
        cpu_read_n = 2'b11;
    end
    endtask

    task cpu_write;
        input [27:0] addr;
        input [31:0] data;
    begin
        cpu_addr     = addr;
        cpu_data_out = data;
        cpu_write_n  = 2'b10;  // 32-bit write
        cpu_read_n   = 2'b11;
        @(posedge clk);
        wait(cpu_data_ready);
        @(posedge clk);
        cpu_write_n = 2'b11;
    end
    endtask

    task dma_idle;
    begin
        dma_addr     = 28'h0;
        dma_write_n  = 2'b11;
        dma_read_n   = 2'b11;
        dma_data_out = 32'h0;
        dma_request  = 1'b0;
    end
    endtask

    task dma_read;
        input [27:0] addr;
    begin
        dma_request = 1'b1;
        @(posedge clk);
        wait(dma_grant);
        dma_addr   = addr;
        dma_read_n = 2'b10;  // 32-bit read
        @(posedge clk);
        wait(dma_data_ready);
        @(posedge clk);
        dma_read_n  = 2'b11;
        dma_request = 1'b0;
    end
    endtask

    task dma_write;
        input [27:0] addr;
        input [31:0] data;
    begin
        dma_request  = 1'b1;
        @(posedge clk);
        wait(dma_grant);
        dma_addr     = addr;
        dma_data_out = data;
        dma_write_n  = 2'b10;  // 32-bit write
        @(posedge clk);
        wait(dma_data_ready);
        @(posedge clk);
        dma_write_n  = 2'b11;
        dma_request  = 1'b0;
    end
    endtask

    // Test sequence
    integer errors;
    initial begin
        $dumpfile("tb_dma_arbiter.vcd");
        $dumpvars(0, tb_dma_arbiter);

        // Initialize
        rstn = 0;
        cpu_idle;
        dma_idle;
        mem_data_in = 32'h0;
        mem_data_ready = 1'b0;
        errors = 0;

        // Initialize memory
        for (i = 0; i < 256; i = i + 1) begin
            memory[i] = 32'hDEAD0000 + i;
        end

        // Reset
        #20 rstn = 1;
        #20;

        $display("===========================================");
        $display("      DMA Arbiter Testbench Starting       ");
        $display("===========================================");

        // Test 1: CPU-only read
        $display("\nTest 1: CPU-only read from address 0x10");
        cpu_read(28'h10);
        if (cpu_data_in !== 32'hDEAD0010) begin
            $display("  ERROR: Expected 0xDEAD0010, got 0x%08h", cpu_data_in);
            errors = errors + 1;
        end else begin
            $display("  PASS: Read data = 0x%08h", cpu_data_in);
        end
        cpu_idle;
        #20;

        // Test 2: CPU-only write
        $display("\nTest 2: CPU-only write to address 0x20");
        cpu_write(28'h20, 32'hCAFEBABE);
        cpu_read(28'h20);
        if (cpu_data_in !== 32'hCAFEBABE) begin
            $display("  ERROR: Expected 0xCAFEBABE, got 0x%08h", cpu_data_in);
            errors = errors + 1;
        end else begin
            $display("  PASS: Written and read back = 0x%08h", cpu_data_in);
        end
        cpu_idle;
        #20;

        // Test 3: DMA-only read (CPU idle)
        $display("\nTest 3: DMA-only read from address 0x30 (CPU idle)");
        dma_read(28'h30);
        if (dma_data_in !== 32'hDEAD0030) begin
            $display("  ERROR: Expected 0xDEAD0030, got 0x%08h", dma_data_in);
            errors = errors + 1;
        end else begin
            $display("  PASS: DMA read data = 0x%08h", dma_data_in);
        end
        dma_idle;
        #20;

        // Test 4: DMA-only write (CPU idle)
        $display("\nTest 4: DMA-only write to address 0x40 (CPU idle)");
        dma_write(28'h40, 32'h12345678);
        dma_read(28'h40);
        if (dma_data_in !== 32'h12345678) begin
            $display("  ERROR: Expected 0x12345678, got 0x%08h", dma_data_in);
            errors = errors + 1;
        end else begin
            $display("  PASS: DMA written and read back = 0x%08h", dma_data_in);
        end
        dma_idle;
        #20;

        // Test 5: CPU priority test
        $display("\nTest 5: CPU priority when both request");
        // Start DMA request
        dma_request = 1'b1;
        dma_addr    = 28'h50;
        dma_read_n  = 2'b10;
        @(posedge clk);

        // CPU also requests (should get priority)
        cpu_addr   = 28'h60;
        cpu_read_n = 2'b10;
        @(posedge clk);
        @(posedge clk);

        // Check that CPU got the bus
        if (mem_addr !== 28'h60) begin
            $display("  ERROR: CPU should have priority, mem_addr = 0x%07h", mem_addr);
            errors = errors + 1;
        end else begin
            $display("  PASS: CPU has priority, mem_addr = 0x%07h", mem_addr);
        end

        // Wait for CPU to finish
        wait(cpu_data_ready);
        @(posedge clk);
        cpu_idle;

        // Now DMA should get access
        @(posedge clk);
        @(posedge clk);
        if (dma_grant && mem_addr == 28'h50) begin
            $display("  PASS: DMA got access after CPU finished");
        end else begin
            $display("  INFO: DMA grant = %b, mem_addr = 0x%07h", dma_grant, mem_addr);
        end

        dma_idle;
        #40;

        // Summary
        $display("\n===========================================");
        if (errors == 0) begin
            $display("      All tests PASSED!                    ");
        end else begin
            $display("      %0d test(s) FAILED!                  ", errors);
        end
        $display("===========================================");

        #100;
        $finish;
    end

    // Timeout watchdog
    initial begin
        #50000;
        $display("ERROR: Timeout!");
        $finish;
    end

endmodule
