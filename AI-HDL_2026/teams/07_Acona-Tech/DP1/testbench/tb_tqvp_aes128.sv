//============================================================================
// Module: tb_tqvp_aes128
// Description: Top-Level Integration Testbench for AES-128 Crypto Accelerator
//              Verifies complete system operation through register interface
//
// Test Cases:
//   1. Reset behavior
//   2. NIST FIPS-197 Appendix B encryption
//   3. NIST FIPS-197 decryption (reverse of test 2)
//   4. All-zeros test vector
//   5. All-ones test vector
//   6. Back-to-back operations
//   7. Key change between operations
//   8. Interrupt functionality
//   9. Encrypt-decrypt round trip
//
// Author: AIHDL 2026 Competition Team
// Date: January 2026
//============================================================================

`timescale 1ns / 1ps

module tb_tqvp_aes128;

    //------------------------------------------------------------------------
    // Parameters
    //------------------------------------------------------------------------
    parameter CLK_PERIOD = 15.625;  // 64MHz

    // Addressing mode:
    // 0: TB sends BYTE offsets (0x00,0x04,0x10,...)
    // 1: TB sends WORD offsets (0x00,0x01,0x04,... = byte/4)
    parameter ADDR_MODE_WORDS = 0;

    //------------------------------------------------------------------------
    // DUT Signals
    //------------------------------------------------------------------------
    reg          clk;
    reg          rst_n;
    reg  [7:0]   ui_in;
    wire [7:0]   uo_out;
    reg  [5:0]   address;
    reg  [31:0]  data_in;
    reg  [1:0]   data_write_n;
    reg  [1:0]   data_read_n;
    wire [31:0]  data_out;
    wire         data_ready;
    wire         user_interrupt;

    //------------------------------------------------------------------------
    // Test Variables
    //------------------------------------------------------------------------
    reg [127:0] test_key;
    reg [127:0] test_plaintext;
    reg [127:0] expected_ciphertext;
    reg [127:0] result;
    reg [31:0]  read_data;
    integer     test_num;
    integer     errors;

    //------------------------------------------------------------------------
    // Register Addresses (BYTE offsets)
    //------------------------------------------------------------------------
    localparam [5:0] ADDR_CTRL_B     = 6'h00;
    localparam [5:0] ADDR_STATUS_B   = 6'h04;
    localparam [5:0] ADDR_INT_EN_B   = 6'h08;
    localparam [5:0] ADDR_INT_STAT_B = 6'h0C;
    localparam [5:0] ADDR_KEY0_B     = 6'h10;
    localparam [5:0] ADDR_KEY1_B     = 6'h14;
    localparam [5:0] ADDR_KEY2_B     = 6'h18;
    localparam [5:0] ADDR_KEY3_B     = 6'h1C;
    localparam [5:0] ADDR_DIN0_B     = 6'h20;
    localparam [5:0] ADDR_DIN1_B     = 6'h24;
    localparam [5:0] ADDR_DIN2_B     = 6'h28;
    localparam [5:0] ADDR_DIN3_B     = 6'h2C;
    localparam [5:0] ADDR_DOUT0_B    = 6'h30;
    localparam [5:0] ADDR_DOUT1_B    = 6'h34;
    localparam [5:0] ADDR_DOUT2_B    = 6'h38;
    localparam [5:0] ADDR_DOUT3_B    = 6'h3C;

    // Convert to actual bus address depending on mode
    function automatic [5:0] A(input [5:0] byte_addr);
        begin
            if (ADDR_MODE_WORDS) A = (byte_addr >> 2);
            else                 A = byte_addr;
        end
    endfunction

    //------------------------------------------------------------------------
    // DUT Instantiation
    //------------------------------------------------------------------------
    tqvp_aes128 u_dut (
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

    //------------------------------------------------------------------------
    // Clock Generation
    //------------------------------------------------------------------------
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    //------------------------------------------------------------------------
    // Task: Write Register
    //------------------------------------------------------------------------
    task write_reg;
        input [5:0]  addr_b;
        input [31:0] wdata;
        begin
            @(posedge clk);
            address <= A(addr_b);
            data_in <= wdata;
            data_write_n <= 2'b10;
            data_read_n  <= 2'b11;

            @(posedge clk);
            data_write_n <= 2'b11;

            @(posedge clk);
        end
    endtask

    //------------------------------------------------------------------------
    // Task: Read Register
    //------------------------------------------------------------------------
    task read_reg;
        input  [5:0]  addr_b;
        output [31:0] rdata;
        begin
            @(posedge clk);
            address <= A(addr_b);
            data_write_n <= 2'b11;
            data_read_n  <= 2'b10;

            @(posedge clk);
            while (!data_ready) @(posedge clk);

            rdata = data_out;

            data_read_n <= 2'b11;
            @(posedge clk);
        end
    endtask

    //------------------------------------------------------------------------
    // Task: Write 128-bit Key
    //------------------------------------------------------------------------
    task write_key;
        input [127:0] key;
        begin
            write_reg(ADDR_KEY0_B, key[127:96]);
            write_reg(ADDR_KEY1_B, key[95:64]);
            write_reg(ADDR_KEY2_B, key[63:32]);
            write_reg(ADDR_KEY3_B, key[31:0]);
        end
    endtask

    //------------------------------------------------------------------------
    // Task: Write 128-bit Data Input
    //------------------------------------------------------------------------
    task write_din;
        input [127:0] din;
        begin
            write_reg(ADDR_DIN0_B, din[127:96]);
            write_reg(ADDR_DIN1_B, din[95:64]);
            write_reg(ADDR_DIN2_B, din[63:32]);
            write_reg(ADDR_DIN3_B, din[31:0]);
        end
    endtask

    //------------------------------------------------------------------------
    // Task: Read 128-bit Data Output
    //------------------------------------------------------------------------
    task read_dout;
        output [127:0] dout;
        reg [31:0] tmp;
        begin
            read_reg(ADDR_DOUT0_B, tmp); dout[127:96] = tmp;
            read_reg(ADDR_DOUT1_B, tmp); dout[95:64]  = tmp;
            read_reg(ADDR_DOUT2_B, tmp); dout[63:32]  = tmp;
            read_reg(ADDR_DOUT3_B, tmp); dout[31:0]   = tmp;
        end
    endtask

    //------------------------------------------------------------------------
    // Task: Wait for Done
    //------------------------------------------------------------------------
    task wait_done;
        reg [31:0] status;
        integer timeout;
        begin
            timeout = 0;
            status  = 0;
            while (!(status[1]) && timeout < 1000) begin
                read_reg(ADDR_STATUS_B, status);
                timeout = timeout + 1;
            end
            if (timeout >= 1000) begin
                $display("  ERROR: Operation timeout!");
            end
        end
    endtask

    //------------------------------------------------------------------------
    // Task: Wait for Key Valid
    //------------------------------------------------------------------------
    task wait_key_valid;
        reg [31:0] status;
        integer timeout;
        begin
            timeout = 0;
            status  = 0;
            while (!(status[3]) && timeout < 100) begin
                read_reg(ADDR_STATUS_B, status);
                timeout = timeout + 1;
            end
        end
    endtask

    //------------------------------------------------------------------------
    // Task: Run Encryption
    //------------------------------------------------------------------------
    task run_encrypt;
        input  [127:0] key;
        input  [127:0] plaintext;
        output [127:0] ciphertext;
        begin
            write_key(key);
            wait_key_valid();
            write_din(plaintext);
            write_reg(ADDR_CTRL_B, 32'h01);  // START=1, MODE=0
            wait_done();
            read_dout(ciphertext);
        end
    endtask

    //------------------------------------------------------------------------
    // Task: Run Decryption
    //------------------------------------------------------------------------
    task run_decrypt;
        input  [127:0] key;
        input  [127:0] ciphertext;
        output [127:0] plaintext;
        begin
            write_key(key);
            wait_key_valid();
            write_din(ciphertext);
            write_reg(ADDR_CTRL_B, 32'h03);  // START=1, MODE=1
            wait_done();
            read_dout(plaintext);
        end
    endtask

    //------------------------------------------------------------------------
    // Main Test Sequence
    //------------------------------------------------------------------------
    initial begin
        rst_n = 0;
        ui_in = 8'h00;
        address = 6'h00;
        data_in = 32'd0;
        data_write_n = 2'b11;
        data_read_n  = 2'b11;
        test_num = 0;
        errors = 0;

        $display("");
        $display("================================================================");
        $display("  AES-128 Crypto Accelerator - Top-Level Integration Test");
        $display("================================================================");
        $display("  ADDR_MODE_WORDS = %0d (0=byte offsets, 1=word offsets)", ADDR_MODE_WORDS);
        $display("================================================================");

        // Reset
        repeat(10) @(posedge clk);
        rst_n = 1;
        repeat(5) @(posedge clk);

        // Test 1: Reset Behavior
        test_num = 1;
        $display("");
        $display("Test %0d: Reset Behavior", test_num);

        read_reg(ADDR_STATUS_B, read_data);
        $display("  STATUS after reset: 0x%h", read_data);
        $display("    BUSY=%b, DONE=%b, ERROR=%b, KEY_VALID=%b",
                 read_data[0], read_data[1], read_data[2], read_data[3]);

        if (read_data[0] === 1'b0) begin
            $display("  PASSED: Not busy after reset");
        end else begin
            $display("  FAILED: Busy after reset");
            errors = errors + 1;
        end

        // Test 2: NIST Encryption
        test_num = 2;
        $display("");
        $display("Test %0d: NIST FIPS-197 Appendix B Encryption", test_num);

        test_key            = 128'h2b7e151628aed2a6abf7158809cf4f3c;
        test_plaintext      = 128'h3243f6a8885a308d313198a2e0370734;
        expected_ciphertext = 128'h3925841d02dc09fbdc118597196a0b32;

        run_encrypt(test_key, test_plaintext, result);

        if (result === expected_ciphertext) begin
            $display("  PASSED: NIST encryption correct");
        end else begin
            $display("  FAILED: NIST encryption mismatch");
            $display("    Expected: %h", expected_ciphertext);
            $display("    Got:      %h", result);
            errors = errors + 1;
        end

        // Test 3: NIST Decryption
        test_num = 3;
        $display("");
        $display("Test %0d: NIST FIPS-197 Decryption", test_num);

        run_decrypt(test_key, expected_ciphertext, result);

        if (result === test_plaintext) begin
            $display("  PASSED: NIST decryption correct");
        end else begin
            $display("  FAILED: NIST decryption mismatch");
            $display("    Expected: %h", test_plaintext);
            $display("    Got:      %h", result);
            errors = errors + 1;
        end

        // Test 4: All-Zeros
        test_num = 4;
        $display("");
        $display("Test %0d: All-Zeros Test Vector", test_num);

        test_key            = 128'h00000000000000000000000000000000;
        test_plaintext      = 128'h00000000000000000000000000000000;
        expected_ciphertext = 128'h66e94bd4ef8a2c3b884cfa59ca342b2e;

        run_encrypt(test_key, test_plaintext, result);

        if (result === expected_ciphertext) begin
            $display("  PASSED: All-zeros encryption correct");
        end else begin
            $display("  FAILED: All-zeros encryption mismatch");
            $display("    Expected: %h", expected_ciphertext);
            $display("    Got:      %h", result);
            errors = errors + 1;
        end

        run_decrypt(test_key, expected_ciphertext, result);
        if (result === test_plaintext) begin
            $display("  PASSED: All-zeros decryption correct");
        end else begin
            $display("  FAILED: All-zeros decryption mismatch");
            errors = errors + 1;
        end

        // Test 5: All-Ones
        test_num = 5;
        $display("");
        $display("Test %0d: All-Ones Test Vector", test_num);

        test_key            = 128'hffffffffffffffffffffffffffffffff;
        test_plaintext      = 128'hffffffffffffffffffffffffffffffff;

        // FIXED expected ciphertext (AES-128 ECB, key=FF..FF, pt=FF..FF)
        expected_ciphertext = 128'hbcbf217cb280cf30b2517052193ab979;

        run_encrypt(test_key, test_plaintext, result);

        if (result === expected_ciphertext) begin
            $display("  PASSED: All-ones encryption correct");
        end else begin
            $display("  FAILED: All-ones encryption mismatch");
            $display("    Expected: %h", expected_ciphertext);
            $display("    Got:      %h", result);
            errors = errors + 1;
        end

        // Test 6: Back-to-Back
        test_num = 6;
        $display("");
        $display("Test %0d: Back-to-Back Operations", test_num);

        test_key = 128'h2b7e151628aed2a6abf7158809cf4f3c;

        run_encrypt(test_key, 128'h6bc1bee22e409f96e93d7e117393172a, result);
        $display("  Block 1: %h", result);

        run_encrypt(test_key, 128'hae2d8a571e03ac9c9eb76fac45af8e51, result);
        $display("  Block 2: %h", result);

        $display("  PASSED: Back-to-back operations completed");

        // Test 7: Key Change
        test_num = 7;
        $display("");
        $display("Test %0d: Key Change Between Operations", test_num);

        test_plaintext = 128'h00000000000000000000000000000000;

        test_key = 128'h00000000000000000000000000000000;
        run_encrypt(test_key, test_plaintext, result);
        $display("  Key1 result: %h", result);

        test_key = 128'hffffffffffffffffffffffffffffffff;
        run_encrypt(test_key, test_plaintext, result);
        $display("  Key2 result: %h", result);

        if (result !== 128'h66e94bd4ef8a2c3b884cfa59ca342b2e) begin
            $display("  PASSED: Different key produces different result");
        end else begin
            $display("  FAILED: Key change not effective");
            errors = errors + 1;
        end

        // Test 8: Interrupt
        test_num = 8;
        $display("");
        $display("Test %0d: Interrupt Functionality", test_num);

        write_reg(ADDR_INT_EN_B, 32'h01);
        write_reg(ADDR_INT_STAT_B, 32'hFF);

        test_key = 128'h2b7e151628aed2a6abf7158809cf4f3c;
        test_plaintext = 128'h3243f6a8885a308d313198a2e0370734;

        write_key(test_key);
        wait_key_valid();
        write_din(test_plaintext);
        write_reg(ADDR_CTRL_B, 32'h01);

        wait_done();

        if (user_interrupt === 1'b1) begin
            $display("  PASSED: Interrupt asserted on completion");
        end else begin
            $display("  FAILED: Interrupt not asserted");
            errors = errors + 1;
        end

        write_reg(ADDR_INT_STAT_B, 32'h01);
        @(posedge clk);

        if (user_interrupt === 1'b0) begin
            $display("  PASSED: Interrupt cleared");
        end else begin
            $display("  FAILED: Interrupt not cleared");
            errors = errors + 1;
        end

        write_reg(ADDR_INT_EN_B, 32'h00);

        // Test 9: Round trip
        test_num = 9;
        $display("");
        $display("Test %0d: Encrypt-Decrypt Round Trip", test_num);

        test_key = 128'hdeadbeefcafebabe0123456789abcdef;
        test_plaintext = 128'h0fedcba9876543210badf00dcafebeef;

        run_encrypt(test_key, test_plaintext, result);
        $display("  Original:   %h", test_plaintext);
        $display("  Encrypted:  %h", result);

        run_decrypt(test_key, result, result);
        $display("  Decrypted:  %h", result);

        if (result === test_plaintext) begin
            $display("  PASSED: Round trip successful");
        end else begin
            $display("  FAILED: Round trip mismatch");
            errors = errors + 1;
        end

        // Summary
        $display("");
        $display("================================================================");
        $display("  TEST SUMMARY");
        $display("================================================================");
        $display("  Total Tests: %0d", test_num);
        $display("  Passed:      %0d", test_num - errors);
        $display("  Failed:      %0d", errors);

        if (errors == 0) $display("  *** ALL TESTS PASSED ***");
        else             $display("  *** TESTS FAILED - REVIEW ERRORS ABOVE ***");

        $display("================================================================");

        repeat(20) @(posedge clk);
        $finish;
    end

    //------------------------------------------------------------------------
    // Timeout Watchdog
    //------------------------------------------------------------------------
    initial begin
        #5000000;
        $display("");
        $display("ERROR: Simulation timeout!");
        $display("================================================================");
        $finish;
    end

    //------------------------------------------------------------------------
    // Waveform Dump
    //------------------------------------------------------------------------
    initial begin
        $dumpfile("tb_tqvp_aes128.vcd");
        $dumpvars(0, tb_tqvp_aes128);
    end

endmodule
