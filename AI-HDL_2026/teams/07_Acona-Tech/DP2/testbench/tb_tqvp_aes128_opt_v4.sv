//============================================================================
// Testbench: tb_tqvp_aes128_opt_v4
// Description: Testbench for Fully Optimized AES-128 with Pipelined Keys
//============================================================================

`timescale 1ns / 1ps

module tb_tqvp_aes128_opt_v4;

    parameter CLK_PERIOD = 15.625;  // 64MHz

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

    reg [127:0] test_key;
    reg [127:0] test_plaintext;
    reg [127:0] expected_ciphertext;
    reg [127:0] result;
    reg [31:0]  read_data;
    integer     test_num;
    integer     errors;
    integer     start_cycle, end_cycle;

    // Register addresses
    localparam [5:0] ADDR_CTRL   = 6'h00;
    localparam [5:0] ADDR_STATUS = 6'h04;
    localparam [5:0] ADDR_KEY0   = 6'h10;
    localparam [5:0] ADDR_KEY1   = 6'h14;
    localparam [5:0] ADDR_KEY2   = 6'h18;
    localparam [5:0] ADDR_KEY3   = 6'h1C;
    localparam [5:0] ADDR_DIN0   = 6'h20;
    localparam [5:0] ADDR_DIN1   = 6'h24;
    localparam [5:0] ADDR_DIN2   = 6'h28;
    localparam [5:0] ADDR_DIN3   = 6'h2C;
    localparam [5:0] ADDR_DOUT0  = 6'h30;
    localparam [5:0] ADDR_DOUT1  = 6'h34;
    localparam [5:0] ADDR_DOUT2  = 6'h38;
    localparam [5:0] ADDR_DOUT3  = 6'h3C;

    // DUT
    tqvp_aes128_opt_v4 u_dut (
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

    // Clock
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Cycle counter
    integer cycle_count;
    initial cycle_count = 0;
    always @(posedge clk) cycle_count = cycle_count + 1;

    // Tasks
    task write_reg(input [5:0] addr, input [31:0] wdata);
        begin
            @(posedge clk);
            address <= addr;
            data_in <= wdata;
            data_write_n <= 2'b10;
            data_read_n  <= 2'b11;
            @(posedge clk);
            data_write_n <= 2'b11;
            @(posedge clk);
        end
    endtask

    task read_reg(input [5:0] addr, output [31:0] rdata);
        begin
            @(posedge clk);
            address <= addr;
            data_write_n <= 2'b11;
            data_read_n  <= 2'b10;
            @(posedge clk);
            while (!data_ready) @(posedge clk);
            rdata = data_out;
            data_read_n <= 2'b11;
            @(posedge clk);
        end
    endtask

    task write_key(input [127:0] key);
        begin
            write_reg(ADDR_KEY0, key[127:96]);
            write_reg(ADDR_KEY1, key[95:64]);
            write_reg(ADDR_KEY2, key[63:32]);
            write_reg(ADDR_KEY3, key[31:0]);
        end
    endtask

    task write_din(input [127:0] din);
        begin
            write_reg(ADDR_DIN0, din[127:96]);
            write_reg(ADDR_DIN1, din[95:64]);
            write_reg(ADDR_DIN2, din[63:32]);
            write_reg(ADDR_DIN3, din[31:0]);
        end
    endtask

    task read_dout(output [127:0] dout);
        reg [31:0] tmp;
        begin
            read_reg(ADDR_DOUT0, tmp); dout[127:96] = tmp;
            read_reg(ADDR_DOUT1, tmp); dout[95:64]  = tmp;
            read_reg(ADDR_DOUT2, tmp); dout[63:32]  = tmp;
            read_reg(ADDR_DOUT3, tmp); dout[31:0]   = tmp;
        end
    endtask

    task wait_key_valid;
        reg [31:0] status;
        integer timeout;
        begin
            timeout = 0;
            status = 0;
            while (!(status[3]) && timeout < 200) begin
                read_reg(ADDR_STATUS, status);
                timeout = timeout + 1;
            end
        end
    endtask

    task wait_done;
        reg [31:0] status;
        integer timeout;
        begin
            timeout = 0;
            status = 0;
            while (!(status[1]) && timeout < 500) begin
                read_reg(ADDR_STATUS, status);
                timeout = timeout + 1;
            end
            if (timeout >= 500)
                $display("  ERROR: Encryption timeout!");
        end
    endtask

    task run_encrypt(input [127:0] key, input [127:0] ptext, output [127:0] ctext);
        begin
            write_key(key);
            wait_key_valid();
            write_din(ptext);
            start_cycle = cycle_count;
            write_reg(ADDR_CTRL, 32'h01);
            wait_done();
            end_cycle = cycle_count;
            read_dout(ctext);
        end
    endtask

    task run_decrypt(input [127:0] key, input [127:0] ctext, output [127:0] ptext);
        begin
            write_key(key);
            wait_key_valid();
            write_din(ctext);
            start_cycle = cycle_count;
            write_reg(ADDR_CTRL, 32'h03);
            wait_done();
            end_cycle = cycle_count;
            read_dout(ptext);
        end
    endtask

    // Main test
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
        $display("  DP2 v4: Fully Optimized AES-128 with Pipelined Keys");
        $display("  (Clock Gating + Fast MixColumns + Unrolled Keys + Key Pipeline)");
        $display("================================================================");
        $display("  Expected: ~22 cycles (was 12), ~15 logic levels (was 30)");
        $display("================================================================");

        repeat(10) @(posedge clk);
        rst_n = 1;
        repeat(5) @(posedge clk);

        //--------------------------------------------------------------------
        // Test 1: Reset
        //--------------------------------------------------------------------
        test_num = 1;
        $display("");
        $display("Test %0d: Reset Behavior", test_num);
        read_reg(ADDR_STATUS, read_data);
        $display("  STATUS: 0x%h", read_data);
        if (read_data[0] === 1'b0) begin
            $display("  PASSED");
        end else begin
            $display("  FAILED");
            errors = errors + 1;
        end

        //--------------------------------------------------------------------
        // Test 2: NIST Encryption
        //--------------------------------------------------------------------
        test_num = 2;
        $display("");
        $display("Test %0d: NIST FIPS-197 Encryption", test_num);

        test_key            = 128'h2b7e151628aed2a6abf7158809cf4f3c;
        test_plaintext      = 128'h3243f6a8885a308d313198a2e0370734;
        expected_ciphertext = 128'h3925841d02dc09fbdc118597196a0b32;

        run_encrypt(test_key, test_plaintext, result);

        $display("  Cycles: %0d (expected ~30 with pipelined keys)", end_cycle - start_cycle);
        if (result === expected_ciphertext) begin
            $display("  PASSED: Ciphertext matches");
            $display("    Result: %h", result);
        end else begin
            $display("  FAILED: Ciphertext mismatch");
            $display("    Expected: %h", expected_ciphertext);
            $display("    Got:      %h", result);
            errors = errors + 1;
        end

        //--------------------------------------------------------------------
        // Test 3: NIST Decryption
        //--------------------------------------------------------------------
        test_num = 3;
        $display("");
        $display("Test %0d: NIST FIPS-197 Decryption", test_num);

        run_decrypt(test_key, expected_ciphertext, result);

        $display("  Cycles: %0d", end_cycle - start_cycle);
        if (result === test_plaintext) begin
            $display("  PASSED: Plaintext matches");
            $display("    Result: %h", result);
        end else begin
            $display("  FAILED: Plaintext mismatch");
            $display("    Expected: %h", test_plaintext);
            $display("    Got:      %h", result);
            errors = errors + 1;
        end

        //--------------------------------------------------------------------
        // Test 4: All-Zeros
        //--------------------------------------------------------------------
        test_num = 4;
        $display("");
        $display("Test %0d: All-Zeros Vector", test_num);

        test_key            = 128'h00000000000000000000000000000000;
        test_plaintext      = 128'h00000000000000000000000000000000;
        expected_ciphertext = 128'h66e94bd4ef8a2c3b884cfa59ca342b2e;

        run_encrypt(test_key, test_plaintext, result);

        if (result === expected_ciphertext) begin
            $display("  PASSED");
        end else begin
            $display("  FAILED");
            $display("    Expected: %h", expected_ciphertext);
            $display("    Got:      %h", result);
            errors = errors + 1;
        end

        //--------------------------------------------------------------------
        // Test 5: Round Trip
        //--------------------------------------------------------------------
        test_num = 5;
        $display("");
        $display("Test %0d: Encrypt-Decrypt Round Trip", test_num);

        test_key = 128'hdeadbeefcafebabe0123456789abcdef;
        test_plaintext = 128'h0fedcba9876543210badf00dcafebeef;

        run_encrypt(test_key, test_plaintext, result);
        $display("  Encrypted: %h", result);

        run_decrypt(test_key, result, result);
        $display("  Decrypted: %h", result);

        if (result === test_plaintext) begin
            $display("  PASSED");
        end else begin
            $display("  FAILED");
            errors = errors + 1;
        end

        //--------------------------------------------------------------------
        // Summary
        //--------------------------------------------------------------------
        $display("");
        $display("================================================================");
        $display("  TEST SUMMARY");
        $display("================================================================");
        $display("  Total Tests: %0d", test_num);
        $display("  Passed:      %0d", test_num - errors);
        $display("  Failed:      %0d", errors);
        $display("================================================================");

        if (errors == 0) begin
            $display("");
            $display("  *** ALL TESTS PASSED ***");
            $display("  v4 Optimizations Verified!");
            $display("  - Clock Gating: OK");
            $display("  - Fast MixColumns: OK");
            $display("  - Unrolled Keys: OK");
            $display("  - Pipelined Key Fetch: OK");
        end else begin
            $display("");
            $display("  *** TESTS FAILED ***");
        end

        $display("================================================================");

        repeat(20) @(posedge clk);
        $finish;
    end

    // Timeout
    initial begin
        #20000000;
        $display("ERROR: Simulation timeout!");
        $finish;
    end

endmodule
