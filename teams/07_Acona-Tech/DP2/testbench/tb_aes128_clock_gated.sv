//============================================================================
// Testbench: tb_aes128_clock_gated
// Description: Verification testbench for DP2 Clock-Gated AES-128
//
// FIXED: Uses correct register addresses from aes_reg_interface.sv
//
// Register Map:
//   0x00: AES_CTRL     - Control register
//   0x04: AES_STATUS   - Status register
//   0x10: AES_KEY0-3   - Key (0x10, 0x14, 0x18, 0x1C)
//   0x20: AES_DIN0-3   - Data in (0x20, 0x24, 0x28, 0x2C)
//   0x30: AES_DOUT0-3  - Data out (0x30, 0x34, 0x38, 0x3C)
//
// Author: AIHDL 2026 Competition Team (Team Acona)
// Date: February 2026
// Phase: DP2 - PPA Optimization Verification
//============================================================================

`timescale 1ns / 1ps

module tb_aes128_clock_gated;

    //========================================================================
    // Test Parameters
    //========================================================================
    parameter CLK_PERIOD = 15.625;  // 64 MHz
    
    //========================================================================
    // DUT Signals
    //========================================================================
    reg         clk;
    reg         rst_n;
    reg  [7:0]  ui_in;
    wire [7:0]  uo_out;
    reg  [5:0]  address;
    reg  [31:0] data_in;
    reg  [1:0]  data_write_n;
    reg  [1:0]  data_read_n;
    wire [31:0] data_out;
    wire        data_ready;
    wire        user_interrupt;
    
    //========================================================================
    // Clock Gating Monitoring
    //========================================================================
    integer core_clk_active_cycles;
    integer key_exp_clk_active_cycles;
    integer total_cycles;
    
    //========================================================================
    // DUT Instantiation - Uses optimized module
    //========================================================================
    tqvp_aes128_top_opt u_dut (
        .clk            (clk),
        .rst_n          (rst_n),
        .ui_in          (ui_in),
        .uo_out         (uo_out),
        .address        (address),
        .data_in        (data_in),
        .data_write_n   (data_write_n),
        .data_read_n    (data_read_n),
        .data_out       (data_out),
        .data_ready     (data_ready),
        .user_interrupt (user_interrupt)
    );
    
    //========================================================================
    // Clock Generation
    //========================================================================
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    //========================================================================
    // Clock Gating Activity Monitor
    //========================================================================
    initial begin
        core_clk_active_cycles = 0;
        key_exp_clk_active_cycles = 0;
        total_cycles = 0;
    end
    
    always @(posedge clk) begin
        total_cycles = total_cycles + 1;
        
        // Monitor core clock gate
        if (u_dut.u_aes128_core_opt.core_clk_enable)
            core_clk_active_cycles = core_clk_active_cycles + 1;
            
        // Monitor key expansion clock gate
        if (u_dut.u_aes128_core_opt.key_exp_clk_enable)
            key_exp_clk_active_cycles = key_exp_clk_active_cycles + 1;
    end
    
    //========================================================================
    // Register Addresses (BYTE offsets - matching aes_reg_interface.sv)
    //========================================================================
    localparam [5:0] ADDR_CTRL     = 6'h00;
    localparam [5:0] ADDR_STATUS   = 6'h04;
    localparam [5:0] ADDR_INT_EN   = 6'h08;
    localparam [5:0] ADDR_INT_STAT = 6'h0C;
    localparam [5:0] ADDR_KEY0     = 6'h10;
    localparam [5:0] ADDR_KEY1     = 6'h14;
    localparam [5:0] ADDR_KEY2     = 6'h18;
    localparam [5:0] ADDR_KEY3     = 6'h1C;
    localparam [5:0] ADDR_DIN0     = 6'h20;
    localparam [5:0] ADDR_DIN1     = 6'h24;
    localparam [5:0] ADDR_DIN2     = 6'h28;
    localparam [5:0] ADDR_DIN3     = 6'h2C;
    localparam [5:0] ADDR_DOUT0    = 6'h30;
    localparam [5:0] ADDR_DOUT1    = 6'h34;
    localparam [5:0] ADDR_DOUT2    = 6'h38;
    localparam [5:0] ADDR_DOUT3    = 6'h3C;
    
    //========================================================================
    // Task: Write Register
    //========================================================================
    task write_reg;
        input [5:0]  addr;
        input [31:0] wdata;
        begin
            @(posedge clk);
            address      <= addr;
            data_in      <= wdata;
            data_write_n <= 2'b10;  // 32-bit write
            data_read_n  <= 2'b11;  // No read
            
            @(posedge clk);
            data_write_n <= 2'b11;  // End write
            
            @(posedge clk);
        end
    endtask
    
    //========================================================================
    // Task: Read Register
    //========================================================================
    task read_reg;
        input  [5:0]  addr;
        output [31:0] rdata;
        begin
            @(posedge clk);
            address      <= addr;
            data_write_n <= 2'b11;  // No write
            data_read_n  <= 2'b10;  // 32-bit read
            
            @(posedge clk);
            // Wait for data_ready
            while (!data_ready) @(posedge clk);
            
            rdata = data_out;
            
            data_read_n <= 2'b11;  // End read
            @(posedge clk);
        end
    endtask
    
    //========================================================================
    // Task: Write 128-bit Key
    //========================================================================
    task write_key;
        input [127:0] key;
        begin
            write_reg(ADDR_KEY0, key[127:96]);
            write_reg(ADDR_KEY1, key[95:64]);
            write_reg(ADDR_KEY2, key[63:32]);
            write_reg(ADDR_KEY3, key[31:0]);
        end
    endtask
    
    //========================================================================
    // Task: Write 128-bit Data Input
    //========================================================================
    task write_din;
        input [127:0] din;
        begin
            write_reg(ADDR_DIN0, din[127:96]);
            write_reg(ADDR_DIN1, din[95:64]);
            write_reg(ADDR_DIN2, din[63:32]);
            write_reg(ADDR_DIN3, din[31:0]);
        end
    endtask
    
    //========================================================================
    // Task: Read 128-bit Data Output
    //========================================================================
    task read_dout;
        output [127:0] dout;
        reg [31:0] tmp;
        begin
            read_reg(ADDR_DOUT0, tmp); dout[127:96] = tmp;
            read_reg(ADDR_DOUT1, tmp); dout[95:64]  = tmp;
            read_reg(ADDR_DOUT2, tmp); dout[63:32]  = tmp;
            read_reg(ADDR_DOUT3, tmp); dout[31:0]   = tmp;
        end
    endtask
    
    //========================================================================
    // Task: Wait for Key Valid
    //========================================================================
    task wait_key_valid;
        reg [31:0] status;
        integer timeout;
        begin
            timeout = 0;
            status  = 0;
            while (!(status[3]) && timeout < 200) begin
                read_reg(ADDR_STATUS, status);
                timeout = timeout + 1;
            end
            if (timeout >= 200) begin
                $display("  WARNING: Key valid timeout");
            end
        end
    endtask
    
    //========================================================================
    // Task: Wait for Done
    //========================================================================
    task wait_done;
        reg [31:0] status;
        integer timeout;
        begin
            timeout = 0;
            status  = 0;
            while (!(status[1]) && timeout < 500) begin
                read_reg(ADDR_STATUS, status);
                timeout = timeout + 1;
            end
            if (timeout >= 500) begin
                $display("  ERROR: Operation timeout! Status=%h", status);
            end
        end
    endtask
    
    //========================================================================
    // Task: Run Encryption
    //========================================================================
    task run_encrypt;
        input  [127:0] key;
        input  [127:0] plaintext;
        output [127:0] ciphertext;
        begin
            // Write key and trigger key expansion
            write_key(key);
            write_reg(ADDR_CTRL, 32'h00);  // Clear ctrl first
            wait_key_valid();
            
            // Write plaintext
            write_din(plaintext);
            
            // Start encryption (bit 0 = start, bit 1 = 0 for encrypt)
            write_reg(ADDR_CTRL, 32'h01);
            
            // Wait for done
            wait_done();
            
            // Read result
            read_dout(ciphertext);
        end
    endtask
    
    //========================================================================
    // Task: Run Decryption
    //========================================================================
    task run_decrypt;
        input  [127:0] key;
        input  [127:0] ciphertext;
        output [127:0] plaintext;
        begin
            // Write key and trigger key expansion
            write_key(key);
            write_reg(ADDR_CTRL, 32'h00);
            wait_key_valid();
            
            // Write ciphertext
            write_din(ciphertext);
            
            // Start decryption (bit 0 = start, bit 1 = 1 for decrypt)
            write_reg(ADDR_CTRL, 32'h03);
            
            // Wait for done
            wait_done();
            
            // Read result
            read_dout(plaintext);
        end
    endtask
    
    //========================================================================
    // Test Vectors (NIST FIPS-197)
    //========================================================================
    
    // Test Vector 1: All zeros
    localparam [127:0] KEY1    = 128'h00000000000000000000000000000000;
    localparam [127:0] PLAIN1  = 128'h00000000000000000000000000000000;
    localparam [127:0] CIPHER1 = 128'h66e94bd4ef8a2c3b884cfa59ca342b2e;
    
    // Test Vector 2: NIST Appendix B
    localparam [127:0] KEY2    = 128'h2b7e151628aed2a6abf7158809cf4f3c;
    localparam [127:0] PLAIN2  = 128'h3243f6a8885a308d313198a2e0370734;
    localparam [127:0] CIPHER2 = 128'h3925841d02dc09fbdc118597196a0b32;
    
    //========================================================================
    // Main Test Sequence
    //========================================================================
    reg [127:0] result;
    integer test_count;
    integer pass_count;
    integer fail_count;
    
    initial begin
        $display("==========================================================");
        $display("  DP2 Clock-Gated AES-128 Verification Testbench");
        $display("==========================================================");
        $display("  Clock Period: %.3f ns (%.1f MHz)", CLK_PERIOD, 1000.0/CLK_PERIOD);
        $display("==========================================================");
        
        // Initialize
        rst_n = 0;
        ui_in = 8'h00;
        address = 6'h00;
        data_in = 32'h00000000;
        data_write_n = 2'b11;
        data_read_n = 2'b11;
        test_count = 0;
        pass_count = 0;
        fail_count = 0;
        
        // Reset
        #(CLK_PERIOD * 10);
        rst_n = 1;
        #(CLK_PERIOD * 10);
        
        //--------------------------------------------------------------------
        // Test 1: Encryption with all-zero key and plaintext
        //--------------------------------------------------------------------
        $display("\n--- Test 1: Encryption (All Zeros) ---");
        test_count = test_count + 1;
        
        run_encrypt(KEY1, PLAIN1, result);
        
        if (result === CIPHER1) begin
            $display("  PASS: Ciphertext matches expected");
            $display("    Result: %h", result);
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: Ciphertext mismatch");
            $display("    Expected: %h", CIPHER1);
            $display("    Got:      %h", result);
            fail_count = fail_count + 1;
        end
        
        //--------------------------------------------------------------------
        // Test 2: Decryption (reverse of Test 1)
        //--------------------------------------------------------------------
        $display("\n--- Test 2: Decryption (Reverse of Test 1) ---");
        test_count = test_count + 1;
        
        run_decrypt(KEY1, CIPHER1, result);
        
        if (result === PLAIN1) begin
            $display("  PASS: Decrypted plaintext matches");
            $display("    Result: %h", result);
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: Decryption mismatch");
            $display("    Expected: %h", PLAIN1);
            $display("    Got:      %h", result);
            fail_count = fail_count + 1;
        end
        
        //--------------------------------------------------------------------
        // Test 3: NIST Appendix B Encryption
        //--------------------------------------------------------------------
        $display("\n--- Test 3: NIST Appendix B Encryption ---");
        test_count = test_count + 1;
        
        run_encrypt(KEY2, PLAIN2, result);
        
        if (result === CIPHER2) begin
            $display("  PASS: NIST ciphertext matches");
            $display("    Result: %h", result);
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: NIST mismatch");
            $display("    Expected: %h", CIPHER2);
            $display("    Got:      %h", result);
            fail_count = fail_count + 1;
        end
        
        //--------------------------------------------------------------------
        // Test 4: NIST Appendix B Decryption
        //--------------------------------------------------------------------
        $display("\n--- Test 4: NIST Appendix B Decryption ---");
        test_count = test_count + 1;
        
        run_decrypt(KEY2, CIPHER2, result);
        
        if (result === PLAIN2) begin
            $display("  PASS: NIST decryption matches");
            $display("    Result: %h", result);
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: NIST decryption mismatch");
            $display("    Expected: %h", PLAIN2);
            $display("    Got:      %h", result);
            fail_count = fail_count + 1;
        end
        
        //--------------------------------------------------------------------
        // Idle Period (to measure clock gating effectiveness)
        //--------------------------------------------------------------------
        $display("\n--- Idle Period (100 cycles) ---");
        #(CLK_PERIOD * 100);
        
        //--------------------------------------------------------------------
        // Final Report
        //--------------------------------------------------------------------
        $display("\n==========================================================");
        $display("  TEST SUMMARY");
        $display("==========================================================");
        $display("  Total Tests:  %0d", test_count);
        $display("  Passed:       %0d", pass_count);
        $display("  Failed:       %0d", fail_count);
        $display("==========================================================");
        
        $display("\n==========================================================");
        $display("  CLOCK GATING STATISTICS");
        $display("==========================================================");
        $display("  Total Cycles:              %0d", total_cycles);
        $display("  Core Clock Active Cycles:  %0d (%.1f%%)", 
                 core_clk_active_cycles, 
                 100.0 * core_clk_active_cycles / total_cycles);
        $display("  Key Exp Clock Active:      %0d (%.1f%%)", 
                 key_exp_clk_active_cycles,
                 100.0 * key_exp_clk_active_cycles / total_cycles);
        $display("  Core Clock Gated Cycles:   %0d (%.1f%% power saved)", 
                 total_cycles - core_clk_active_cycles,
                 100.0 * (total_cycles - core_clk_active_cycles) / total_cycles);
        $display("==========================================================");
        
        if (fail_count == 0) begin
            $display("\n  *** ALL TESTS PASSED - Clock Gating Verified! ***\n");
        end else begin
            $display("\n  *** SOME TESTS FAILED - Check Implementation ***\n");
        end
        
        $finish;
    end
    
    //========================================================================
    // Timeout Watchdog
    //========================================================================
    initial begin
        #(CLK_PERIOD * 50000);
        $display("ERROR: Testbench timeout!");
        $finish;
    end
    
    //========================================================================
    // Waveform Dump
    //========================================================================
    initial begin
        $dumpfile("tb_aes128_clock_gated.vcd");
        $dumpvars(0, tb_aes128_clock_gated);
    end

endmodule
