/*
 * Testbench for TinyQV DMA Controller (tinyqv_dma.v)
 *
 * Test Cases:
 * 1. Register read/write verification
 * 2. Single word DMA transfer (32-bit)
 * 3. Multi-word DMA transfer (32-bit)
 * 4. 16-bit transfer mode
 * 5. 8-bit transfer mode
 * 6. Interrupt generation and clearing
 * 7. BUSY/DONE status verification
 * 8. Back-to-back transfers
 *
 * SPDX-License-Identifier: Apache-2.0
 */

`timescale 1ns/1ps

module tb_tinyqv_dma;

    //=========================================================================
    // Parameters
    //=========================================================================
    localparam CLK_PERIOD = 10;  // 100MHz clock

    // Register addresses
    localparam REG_SRC_ADDR = 4'h0;
    localparam REG_DST_ADDR = 4'h1;
    localparam REG_COUNT    = 4'h2;
    localparam REG_CTRL     = 4'h3;
    localparam REG_STATUS   = 4'h4;

    // Control register bits
    localparam CTRL_START = 0;
    localparam CTRL_BUSY  = 1;
    localparam CTRL_DONE  = 2;
    localparam CTRL_IE    = 3;
    // SIZE bits [5:4]: 00=8-bit, 01=16-bit, 10=32-bit

    //=========================================================================
    // Signals
    //=========================================================================
    reg         clk;
    reg         rstn;

    // Configuration interface
    reg         cfg_write;
    reg         cfg_read;
    reg  [3:0]  cfg_addr;
    reg  [31:0] cfg_data_in;
    wire [31:0] cfg_data_out;

    // DMA bus interface
    wire [27:0] dma_addr;
    wire [1:0]  dma_write_n;
    wire [1:0]  dma_read_n;
    wire [31:0] dma_data_out;
    reg  [31:0] dma_data_in;
    reg         dma_ready;

    // Bus arbitration
    wire        dma_request;
    reg         dma_grant;

    // Interrupt
    wire        dma_interrupt;

    //=========================================================================
    // Clock Generation
    //=========================================================================
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    //=========================================================================
    // DUT Instantiation
    //=========================================================================
    tinyqv_dma dut (
        .clk(clk),
        .rstn(rstn),

        .cfg_write(cfg_write),
        .cfg_read(cfg_read),
        .cfg_addr(cfg_addr),
        .cfg_data_in(cfg_data_in),
        .cfg_data_out(cfg_data_out),

        .dma_addr(dma_addr),
        .dma_write_n(dma_write_n),
        .dma_read_n(dma_read_n),
        .dma_data_out(dma_data_out),
        .dma_data_in(dma_data_in),
        .dma_ready(dma_ready),

        .dma_request(dma_request),
        .dma_grant(dma_grant),

        .dma_interrupt(dma_interrupt)
    );

    //=========================================================================
    // Memory Model
    //=========================================================================
    reg [31:0] memory [0:4095];  // 16KB memory (4K x 32-bit)
    integer mem_idx;

    always @(posedge clk) begin
        if (!rstn) begin
            dma_ready <= 1'b0;
            dma_data_in <= 32'h0;
        end else begin
            dma_ready <= 1'b0;

            if (dma_grant) begin
                // Read operation
                if (dma_read_n != 2'b11) begin
                    mem_idx = dma_addr[13:2];  // Word address
                    case (dma_read_n)
                        2'b00: dma_data_in <= {24'h0, memory[mem_idx][7:0]};   // 8-bit
                        2'b01: dma_data_in <= {16'h0, memory[mem_idx][15:0]};  // 16-bit
                        2'b10: dma_data_in <= memory[mem_idx];                  // 32-bit
                        default: dma_data_in <= 32'h0;
                    endcase
                    dma_ready <= 1'b1;
                end

                // Write operation
                if (dma_write_n != 2'b11) begin
                    mem_idx = dma_addr[13:2];  // Word address
                    case (dma_write_n)
                        2'b00: memory[mem_idx][7:0]  <= dma_data_out[7:0];    // 8-bit
                        2'b01: memory[mem_idx][15:0] <= dma_data_out[15:0];   // 16-bit
                        2'b10: memory[mem_idx]       <= dma_data_out;          // 32-bit
                    endcase
                    dma_ready <= 1'b1;
                end
            end
        end
    end

    // Auto-grant DMA requests
    always @(posedge clk) begin
        if (!rstn)
            dma_grant <= 1'b0;
        else
            dma_grant <= dma_request;
    end

    //=========================================================================
    // Test Tasks
    //=========================================================================

    // Write to DMA register
    task write_reg;
        input [3:0]  addr;
        input [31:0] data;
    begin
        @(posedge clk);
        cfg_write   <= 1'b1;
        cfg_read    <= 1'b0;
        cfg_addr    <= addr;
        cfg_data_in <= data;
        @(posedge clk);
        cfg_write   <= 1'b0;
    end
    endtask

    // Read from DMA register
    task read_reg;
        input  [3:0]  addr;
        output [31:0] data;
    begin
        @(posedge clk);
        cfg_read  <= 1'b1;
        cfg_write <= 1'b0;
        cfg_addr  <= addr;
        @(posedge clk);
        data = cfg_data_out;
        cfg_read  <= 1'b0;
    end
    endtask

    // Configure and start DMA transfer
    // Arguments: src_addr, dst_addr, count, size(00=8,01=16,10=32), ie
    task start_dma;
        input [27:0] src;
        input [27:0] dst;
        input [15:0] cnt;
        input [1:0]  size;
        input        ie;
    begin
        write_reg(REG_SRC_ADDR, {4'b0, src});
        write_reg(REG_DST_ADDR, {4'b0, dst});
        write_reg(REG_COUNT, {16'b0, cnt});
        write_reg(REG_CTRL, {26'b0, size, ie, 3'b001});  // START=1
    end
    endtask

    // Wait for DMA completion
    task wait_dma_done;
        output integer success;
        integer cnt;
    begin
        success = 0;
        cnt = 0;
        while (cnt < 5000) begin
            @(posedge clk);
            if (dma_interrupt || dut.ctrl_reg[CTRL_DONE]) begin
                success = 1;
                cnt = 5000;  // Exit loop
            end
            cnt = cnt + 1;
        end
    end
    endtask

    // Clear DMA done/interrupt
    task clear_done;
    begin
        write_reg(REG_CTRL, 32'h00000004);  // Write 1 to DONE bit to clear
    end
    endtask

    //=========================================================================
    // Test Variables
    //=========================================================================
    integer errors;
    integer i, j;
    integer success;
    reg [31:0] read_data;

    //=========================================================================
    // Test Sequence
    //=========================================================================
    initial begin
        $dumpfile("tb_tinyqv_dma.vcd");
        $dumpvars(0, tb_tinyqv_dma);

        // Initialize
        rstn        = 0;
        cfg_write   = 0;
        cfg_read    = 0;
        cfg_addr    = 0;
        cfg_data_in = 0;
        dma_data_in = 0;
        dma_ready   = 0;
        dma_grant   = 0;
        errors      = 0;

        // Initialize memory with test patterns
        for (i = 0; i < 4096; i = i + 1) begin
            memory[i] = 32'h0;
        end

        // Source data (words 0-63)
        for (i = 0; i < 64; i = i + 1) begin
            memory[i] = 32'hA5000000 + i;
        end

        // Reset sequence
        #(CLK_PERIOD * 5);
        rstn = 1;
        #(CLK_PERIOD * 5);

        $display("");
        $display("==============================================================");
        $display("          TinyQV DMA Controller Testbench                     ");
        $display("==============================================================");
        $display("");

        //=====================================================================
        // Test 1: Register Read/Write Verification
        //=====================================================================
        $display("--------------------------------------------------------------");
        $display("Test 1: Register Read/Write Verification");
        $display("--------------------------------------------------------------");

        // Test SRC_ADDR register
        write_reg(REG_SRC_ADDR, 28'h1234567);
        read_reg(REG_SRC_ADDR, read_data);
        if (read_data[27:0] !== 28'h1234567) begin
            $display("  [FAIL] SRC_ADDR: wrote 0x1234567, read 0x%07h", read_data[27:0]);
            errors = errors + 1;
        end else begin
            $display("  [PASS] SRC_ADDR register works correctly");
        end

        // Test DST_ADDR register
        write_reg(REG_DST_ADDR, 28'h7654321);
        read_reg(REG_DST_ADDR, read_data);
        if (read_data[27:0] !== 28'h7654321) begin
            $display("  [FAIL] DST_ADDR: wrote 0x7654321, read 0x%07h", read_data[27:0]);
            errors = errors + 1;
        end else begin
            $display("  [PASS] DST_ADDR register works correctly");
        end

        // Test COUNT register
        write_reg(REG_COUNT, 16'hABCD);
        read_reg(REG_COUNT, read_data);
        if (read_data[15:0] !== 16'hABCD) begin
            $display("  [FAIL] COUNT: wrote 0xABCD, read 0x%04h", read_data[15:0]);
            errors = errors + 1;
        end else begin
            $display("  [PASS] COUNT register works correctly");
        end

        // Test CTRL register (IE and SIZE bits)
        write_reg(REG_CTRL, 32'h00000038);  // IE=1, SIZE=10
        read_reg(REG_CTRL, read_data);
        if (read_data[5:3] !== 3'b111) begin
            $display("  [FAIL] CTRL IE/SIZE bits not set correctly");
            errors = errors + 1;
        end else begin
            $display("  [PASS] CTRL register works correctly");
        end

        // Clear registers for next test
        write_reg(REG_SRC_ADDR, 0);
        write_reg(REG_DST_ADDR, 0);
        write_reg(REG_COUNT, 0);
        write_reg(REG_CTRL, 0);
        #(CLK_PERIOD * 2);

        //=====================================================================
        // Test 2: Single Word DMA Transfer (32-bit)
        //=====================================================================
        $display("");
        $display("--------------------------------------------------------------");
        $display("Test 2: Single Word DMA Transfer (32-bit)");
        $display("--------------------------------------------------------------");

        memory[256] = 32'h0;  // Clear destination
        $display("  Source:      memory[0]   = 0x%08h", memory[0]);
        $display("  Destination: memory[256] = 0x%08h (before)", memory[256]);

        // src=0x000, dst=0x400(word 256), cnt=1, size=32-bit, ie=1
        start_dma(28'h0000000, 28'h0000400, 16'd1, 2'b10, 1'b1);

        wait_dma_done(success);

        if (!success) begin
            $display("  [FAIL] DMA transfer timeout!");
            errors = errors + 1;
        end else begin
            $display("  Destination: memory[256] = 0x%08h (after)", memory[256]);
            if (memory[256] !== memory[0]) begin
                $display("  [FAIL] Data mismatch!");
                errors = errors + 1;
            end else begin
                $display("  [PASS] Single word transfer successful");
            end
        end

        // Verify interrupt
        if (!dma_interrupt) begin
            $display("  [FAIL] Interrupt not asserted!");
            errors = errors + 1;
        end else begin
            $display("  [PASS] Interrupt asserted correctly");
        end

        clear_done();
        #(CLK_PERIOD * 5);

        //=====================================================================
        // Test 3: Multi-Word DMA Transfer (32-bit, 16 words)
        //=====================================================================
        $display("");
        $display("--------------------------------------------------------------");
        $display("Test 3: Multi-Word DMA Transfer (32-bit, 16 words)");
        $display("--------------------------------------------------------------");

        // Clear destination
        for (i = 512; i < 528; i = i + 1) begin
            memory[i] = 32'h0;
        end

        $display("  Transferring 16 words from memory[0-15] to memory[512-527]");

        // src=0x000, dst=0x800(word 512), cnt=16, size=32-bit, ie=1
        start_dma(28'h0000000, 28'h0000800, 16'd16, 2'b10, 1'b1);

        wait_dma_done(success);

        if (!success) begin
            $display("  [FAIL] DMA transfer timeout!");
            errors = errors + 1;
        end else begin
            // Verify all 16 words
            j = 0;
            for (i = 0; i < 16; i = i + 1) begin
                if (memory[i] !== memory[512 + i]) begin
                    $display("  [FAIL] Word %0d: src=0x%08h, dst=0x%08h",
                             i, memory[i], memory[512 + i]);
                    j = j + 1;
                end
            end
            if (j == 0) begin
                $display("  [PASS] All 16 words transferred correctly");
            end else begin
                errors = errors + j;
            end
        end

        clear_done();
        #(CLK_PERIOD * 5);

        //=====================================================================
        // Test 4: 16-bit Transfer Mode
        //=====================================================================
        $display("");
        $display("--------------------------------------------------------------");
        $display("Test 4: 16-bit Transfer Mode (4 transfers)");
        $display("--------------------------------------------------------------");

        // Setup source with known pattern
        memory[100] = 32'h12345678;
        memory[101] = 32'hAABBCCDD;
        // Clear destination
        memory[600] = 32'h0;
        memory[601] = 32'h0;

        $display("  Source memory[100] = 0x%08h", memory[100]);
        $display("  Source memory[101] = 0x%08h", memory[101]);

        // src=0x190(word 100), dst=0x960(word 600), cnt=4, size=16-bit, ie=1
        start_dma(28'h0000190, 28'h0000960, 16'd4, 2'b01, 1'b1);

        wait_dma_done(success);

        if (!success) begin
            $display("  [FAIL] DMA transfer timeout!");
            errors = errors + 1;
        end else begin
            $display("  Dest memory[600] = 0x%08h", memory[600]);
            $display("  Dest memory[601] = 0x%08h", memory[601]);
            // Note: 16-bit transfers write lower 16 bits only
            if (memory[600][15:0] !== memory[100][15:0]) begin
                $display("  [FAIL] 16-bit transfer mismatch");
                errors = errors + 1;
            end else begin
                $display("  [PASS] 16-bit transfers work correctly");
            end
        end

        clear_done();
        #(CLK_PERIOD * 5);

        //=====================================================================
        // Test 5: 8-bit Transfer Mode
        //=====================================================================
        $display("");
        $display("--------------------------------------------------------------");
        $display("Test 5: 8-bit Transfer Mode (4 transfers)");
        $display("--------------------------------------------------------------");

        memory[200] = 32'hDEADBEEF;
        memory[700] = 32'h0;

        $display("  Source memory[200] = 0x%08h", memory[200]);

        // src=0x320(word 200), dst=0xAF0(word 700), cnt=4, size=8-bit, ie=1
        start_dma(28'h0000320, 28'h0000AF0, 16'd4, 2'b00, 1'b1);

        wait_dma_done(success);

        if (!success) begin
            $display("  [FAIL] DMA transfer timeout!");
            errors = errors + 1;
        end else begin
            $display("  Dest memory[700] = 0x%08h", memory[700]);
            if (memory[700][7:0] !== memory[200][7:0]) begin
                $display("  [FAIL] 8-bit transfer mismatch");
                errors = errors + 1;
            end else begin
                $display("  [PASS] 8-bit transfers work correctly");
            end
        end

        clear_done();
        #(CLK_PERIOD * 5);

        //=====================================================================
        // Test 6: Interrupt Enable/Disable
        //=====================================================================
        $display("");
        $display("--------------------------------------------------------------");
        $display("Test 6: Interrupt Enable/Disable");
        $display("--------------------------------------------------------------");

        memory[800] = 32'h0;

        // src=0x000, dst=0xC80(word 800), cnt=1, size=32-bit, ie=0 (disabled)
        start_dma(28'h0000000, 28'h0000C80, 16'd1, 2'b10, 1'b0);

        // Wait for DONE bit instead of interrupt
        #(CLK_PERIOD * 100);
        read_reg(REG_CTRL, read_data);

        if (dma_interrupt) begin
            $display("  [FAIL] Interrupt asserted when disabled!");
            errors = errors + 1;
        end else if (read_data[CTRL_DONE]) begin
            $display("  [PASS] Transfer completed without interrupt (as expected)");
        end else begin
            $display("  [FAIL] Transfer did not complete");
            errors = errors + 1;
        end

        clear_done();
        #(CLK_PERIOD * 5);

        //=====================================================================
        // Test 7: BUSY Status Verification
        //=====================================================================
        $display("");
        $display("--------------------------------------------------------------");
        $display("Test 7: BUSY Status Verification");
        $display("--------------------------------------------------------------");

        // Check BUSY is 0 before starting
        read_reg(REG_CTRL, read_data);
        if (read_data[CTRL_BUSY]) begin
            $display("  [FAIL] BUSY should be 0 before starting");
            errors = errors + 1;
        end else begin
            $display("  [PASS] BUSY is 0 before starting");
        end

        // Start a longer transfer
        // src=0x000, dst=0x1000(word 1024), cnt=8, size=32-bit, ie=1
        start_dma(28'h0000000, 28'h0001000, 16'd8, 2'b10, 1'b1);

        // Check BUSY immediately after starting
        #(CLK_PERIOD * 3);
        read_reg(REG_CTRL, read_data);
        if (!read_data[CTRL_BUSY]) begin
            $display("  [FAIL] BUSY should be 1 during transfer");
            errors = errors + 1;
        end else begin
            $display("  [PASS] BUSY is 1 during transfer");
        end

        // Wait for completion
        wait_dma_done(success);

        // Check BUSY is 0 after completion
        read_reg(REG_CTRL, read_data);
        if (read_data[CTRL_BUSY]) begin
            $display("  [FAIL] BUSY should be 0 after completion");
            errors = errors + 1;
        end else begin
            $display("  [PASS] BUSY is 0 after completion");
        end

        clear_done();
        #(CLK_PERIOD * 5);

        //=====================================================================
        // Test 8: STATUS Register (Remaining Count)
        //=====================================================================
        $display("");
        $display("--------------------------------------------------------------");
        $display("Test 8: STATUS Register (Remaining Count)");
        $display("--------------------------------------------------------------");

        // src=0x000, dst=0x1400(word 1280), cnt=10, size=32-bit, ie=1
        start_dma(28'h0000000, 28'h0001400, 16'd10, 2'b10, 1'b1);

        // Wait for completion
        wait_dma_done(success);

        // Check remaining count is 0
        read_reg(REG_STATUS, read_data);
        if (read_data[15:0] !== 16'd0) begin
            $display("  [FAIL] Remaining count should be 0, got %0d", read_data[15:0]);
            errors = errors + 1;
        end else begin
            $display("  [PASS] Remaining count is 0 after completion");
        end

        clear_done();

        //=====================================================================
        // Test Summary
        //=====================================================================
        $display("");
        $display("==============================================================");
        if (errors == 0) begin
            $display("              ALL TESTS PASSED!                             ");
        end else begin
            $display("              %0d TEST(S) FAILED!                           ", errors);
        end
        $display("==============================================================");
        $display("");

        #(CLK_PERIOD * 20);
        $finish;
    end

    //=========================================================================
    // Timeout Watchdog
    //=========================================================================
    initial begin
        #1000000;  // 1ms timeout
        $display("");
        $display("[ERROR] Simulation timeout!");
        $display("");
        $finish;
    end

endmodule
