`timescale 1ns / 1ps

module tb_aes_core;

    reg clk;
    reg rst_n;

    initial clk = 0;
    always #7.8125 clk = ~clk; // 64MHz

    reg  [127:0] data_in;
    reg  [127:0] round_key;
    wire [127:0] data_out;
    wire [3:0]   round_num;

    reg          start;
    reg          decrypt;
    wire         busy;
    wire         done;

    integer test_count;
    integer pass_count;
    integer fail_count;

    reg [127:0] nist_round_keys [0:10];

    aes_core dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .data_in   (data_in),
        .round_key (round_key),
        .data_out  (data_out),
        .round_num (round_num),
        .start     (start),
        .decrypt   (decrypt),
        .busy      (busy),
        .done      (done)
    );

    initial begin
        nist_round_keys[0]  = 128'h2b7e1516_28aed2a6_abf71588_09cf4f3c;
        nist_round_keys[1]  = 128'ha0fafe17_88542cb1_23a33939_2a6c7605;
        nist_round_keys[2]  = 128'hf2c295f2_7a96b943_5935807a_7359f67f;
        nist_round_keys[3]  = 128'h3d80477d_4716fe3e_1e237e44_6d7a883b;
        nist_round_keys[4]  = 128'hef44a541_a8525b7f_b671253b_db0bad00;
        nist_round_keys[5]  = 128'hd4d1c6f8_7c839d87_caf2b8bc_11f915bc;
        nist_round_keys[6]  = 128'h6d88a37a_110b3efd_dbf98641_ca0093fd;
        nist_round_keys[7]  = 128'h4e54f70e_5f5fc9f3_84a64fb2_4ea6dc4f;
        nist_round_keys[8]  = 128'head27321_b58dbad2_312bf560_7f8d292f;
        nist_round_keys[9]  = 128'hac7766f3_19fadc21_28d12941_575c006e;
        nist_round_keys[10] = 128'hd014f9a8_c9ee2589_e13f0cc8_b6630ca6;
    end

    always @(*) begin
        if (^round_num === 1'bX) round_key = 128'h0;
        else                    round_key = nist_round_keys[round_num];
    end

    task reset_dut;
        begin
            rst_n   = 0;
            data_in = 128'd0;
            start   = 0;
            decrypt = 0;
            repeat(4) @(posedge clk);
            rst_n = 1;
            repeat(2) @(posedge clk);
        end
    endtask

    task run_encrypt;
        input [127:0] plaintext;
        output [127:0] ciphertext;
        begin
            @(posedge clk);
            data_in = plaintext;
            decrypt = 0;

            @(posedge clk);
            start = 1;
            @(posedge clk);
            start = 0;

            wait(done == 1);
            @(posedge clk);
            ciphertext = data_out;

            wait(busy == 0);
            @(posedge clk);
        end
    endtask

    task run_decrypt;
        input [127:0] ciphertext;
        output [127:0] plaintext;
        begin
            @(posedge clk);
            data_in = ciphertext;
            decrypt = 1;

            @(posedge clk);
            start = 1;
            @(posedge clk);
            start = 0;

            wait(done == 1);
            @(posedge clk);
            plaintext = data_out;

            wait(busy == 0);
            @(posedge clk);
        end
    endtask

    reg [127:0] result;
    reg [127:0] decrypted;

    initial begin
        $display("============================================================");
        $display("AES-128 Core Testbench");
        $display("============================================================");
        $display("");

        test_count = 0;
        pass_count = 0;
        fail_count = 0;

        reset_dut();

        // TEST 1: NIST Encryption
        $display("------------------------------------------------------------");
        $display("TEST 1: NIST FIPS-197 Appendix B Encryption");
        $display("------------------------------------------------------------");

        run_encrypt(128'h3243f6a8_885a308d_313198a2_e0370734, result);

        test_count++;
        if (result === 128'h3925841d_02dc09fb_dc118597_196a0b32) begin
            pass_count++;
            $display("[PASS] NIST Appendix B Encryption");
        end else begin
            fail_count++;
            $display("[FAIL] NIST Appendix B Encryption");
            $display("       Expected: 3925841d02dc09fbdc118597196a0b32");
            $display("       Got:      %032h", result);
        end

        // TEST 2: NIST Decryption
        $display("");
        $display("------------------------------------------------------------");
        $display("TEST 2: NIST FIPS-197 Appendix B Decryption");
        $display("------------------------------------------------------------");

        run_decrypt(128'h3925841d_02dc09fb_dc118597_196a0b32, result);

        test_count++;
        if (result === 128'h3243f6a8_885a308d_313198a2_e0370734) begin
            pass_count++;
            $display("[PASS] NIST Appendix B Decryption");
        end else begin
            fail_count++;
            $display("[FAIL] NIST Appendix B Decryption");
            $display("       Expected: 3243f6a8885a308d313198a2e0370734");
            $display("       Got:      %032h", result);
        end

        // TEST 3: Round-Trip
        $display("");
        $display("------------------------------------------------------------");
        $display("TEST 3: Round-Trip Verification");
        $display("------------------------------------------------------------");

        run_encrypt(128'hdeadbeef_cafebabe_12345678_9abcdef0, result);
        run_decrypt(result, decrypted);

        test_count++;
        if (decrypted === 128'hdeadbeef_cafebabe_12345678_9abcdef0) begin
            pass_count++;
            $display("[PASS] Round-trip verification");
        end else begin
            fail_count++;
            $display("[FAIL] Round-trip verification");
            $display("       Encrypted: %032h", result);
            $display("       Decrypted: %032h", decrypted);
        end

        $display("");
        $display("============================================================");
        $display("TEST SUMMARY");
        $display("============================================================");
        $display("Total Tests: %0d", test_count);
        $display("Passed:      %0d", pass_count);
        $display("Failed:      %0d", fail_count);
        $display("============================================================");

        #100;
        $finish;
    end

    initial begin
        #1000000;
        $display("[ERROR] Simulation timeout!");
        $finish;
    end

    initial begin
        $dumpfile("tb_aes_core.vcd");
        $dumpvars(0, tb_aes_core);
    end

endmodule
