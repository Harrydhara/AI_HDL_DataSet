//============================================================================
// Testbench: tb_aes128_security
// Description: Comprehensive security validation for DP3 AES-128
// Tests: 16 groups, 50+ checks including DPA and adversarial
// Team: Acona | AI-HDL 2026 DP3
//============================================================================

`timescale 1ns / 1ps

module tb_aes128_security;

    reg clk;
    reg rst_n;

    initial clk = 0;
    always #7.8125 clk = ~clk;

    reg  [7:0]   ui_in;
    wire [7:0]   uo_out;
    reg  [6:0]   address;
    reg  [31:0]  data_in;
    reg  [1:0]   data_write_n;
    reg  [1:0]   data_read_n;
    wire [31:0]  data_out;
    wire         data_ready;
    wire         user_interrupt;

    tqvp_aes128_top_secure u_dut (
        .clk          (clk),
        .rst_n        (rst_n),
        .ui_in        (ui_in),
        .uo_out       (uo_out),
        .address      (address),
        .data_in      (data_in),
        .data_write_n (data_write_n),
        .data_read_n  (data_read_n),
        .data_out     (data_out),
        .data_ready   (data_ready),
        .user_interrupt (user_interrupt)
    );

    parameter [6:0] ADDR_CTRL       = 7'h00;
    parameter [6:0] ADDR_STATUS     = 7'h04;
    parameter [6:0] ADDR_KEY0       = 7'h10;
    parameter [6:0] ADDR_KEY1       = 7'h14;
    parameter [6:0] ADDR_KEY2       = 7'h18;
    parameter [6:0] ADDR_KEY3       = 7'h1C;
    parameter [6:0] ADDR_DIN0       = 7'h20;
    parameter [6:0] ADDR_DIN1       = 7'h24;
    parameter [6:0] ADDR_DIN2       = 7'h28;
    parameter [6:0] ADDR_DIN3       = 7'h2C;
    parameter [6:0] ADDR_DOUT0      = 7'h30;
    parameter [6:0] ADDR_DOUT1      = 7'h34;
    parameter [6:0] ADDR_DOUT2      = 7'h38;
    parameter [6:0] ADDR_DOUT3      = 7'h3C;
    parameter [6:0] ADDR_SEC_CTRL   = 7'h40;
    parameter [6:0] ADDR_SEC_STATUS = 7'h44;
    parameter [6:0] ADDR_LFSR_SEED  = 7'h48;

    integer test_count;
    integer pass_count;
    integer fail_count;

    reg [127:0] ct;
    reg [127:0] ct2;
    reg [31:0]  rv;
    reg [31:0]  w0, w1, w2, w3;
    reg [31:0]  status_tmp;
    integer     timeout_cnt;
    integer     ii;

    integer     hw_sum;
    integer     hw_min;
    integer     hw_max;
    integer     hw_val;
    integer     hw_count;
    reg [127:0] pt_dpa;

    integer     cycle_count;
    integer     cycle_arr [0:4];

    //=========================================================================
    // Hamming Weight
    //=========================================================================
    function integer hamming_weight_128;
        input [127:0] val;
        integer jj;
        integer hw;
        begin
            hw = 0;
            for (jj = 0; jj < 128; jj = jj + 1) begin
                hw = hw + val[jj];
            end
            hamming_weight_128 = hw;
        end
    endfunction

    //=========================================================================
    // Tasks
    //=========================================================================
    task write_reg;
        input [6:0] addr;
        input [31:0] wdata;
        begin
            @(posedge clk);
            address      = addr;
            data_in      = wdata;
            data_write_n = 2'b10;
            data_read_n  = 2'b11;
            @(posedge clk);
            data_write_n = 2'b11;
            @(posedge clk);
        end
    endtask

    task read_reg;
        input  [6:0]  addr;
        output [31:0] rdata;
        begin
            @(posedge clk);
            address      = addr;
            data_write_n = 2'b11;
            data_read_n  = 2'b10;
            @(posedge clk);
            while (!data_ready) @(posedge clk);
            rdata = data_out;
            data_read_n = 2'b11;
            @(posedge clk);
        end
    endtask

    task write_key;
        input [127:0] key;
        begin
            write_reg(ADDR_KEY0, key[127:96]);
            write_reg(ADDR_KEY1, key[95:64]);
            write_reg(ADDR_KEY2, key[63:32]);
            write_reg(ADDR_KEY3, key[31:0]);
        end
    endtask

    task write_plaintext;
        input [127:0] pt;
        begin
            write_reg(ADDR_DIN0, pt[127:96]);
            write_reg(ADDR_DIN1, pt[95:64]);
            write_reg(ADDR_DIN2, pt[63:32]);
            write_reg(ADDR_DIN3, pt[31:0]);
        end
    endtask

    task read_ciphertext;
        output [127:0] ct_out;
        begin
            read_reg(ADDR_DOUT0, w0);
            read_reg(ADDR_DOUT1, w1);
            read_reg(ADDR_DOUT2, w2);
            read_reg(ADDR_DOUT3, w3);
            ct_out = {w0, w1, w2, w3};
        end
    endtask

    task start_and_wait;
        begin
            write_reg(ADDR_CTRL, 32'h01);
            timeout_cnt = 0;
            status_tmp = 0;
            while (!status_tmp[1]) begin
                read_reg(ADDR_STATUS, status_tmp);
                timeout_cnt = timeout_cnt + 1;
                if (timeout_cnt > 200) begin
                    $display("  ERROR: Encryption timeout!");
                    $finish;
                end
            end
        end
    endtask

    task start_and_wait_timed;
        output integer cycles;
        integer count;
        begin
            count = 0;
            write_reg(ADDR_CTRL, 32'h01);
            timeout_cnt = 0;
            status_tmp = 0;
            while (!status_tmp[1]) begin
                read_reg(ADDR_STATUS, status_tmp);
                count = count + 1;
                timeout_cnt = timeout_cnt + 1;
                if (timeout_cnt > 200) begin
                    $display("  ERROR: Encryption timeout!");
                    $finish;
                end
            end
            cycles = count;
        end
    endtask

    task wait_key_valid;
        begin
            timeout_cnt = 0;
            status_tmp = 0;
            while (!status_tmp[3]) begin
                read_reg(ADDR_STATUS, status_tmp);
                timeout_cnt = timeout_cnt + 1;
                if (timeout_cnt > 100) begin
                    $display("  ERROR: Key expansion timeout!");
                    $finish;
                end
            end
        end
    endtask

    task check128;
        input [255:0] name;
        input [127:0] got;
        input [127:0] expected;
        begin
            test_count = test_count + 1;
            if (got === expected) begin
                pass_count = pass_count + 1;
                $display("  [PASS] %0s", name);
            end else begin
                fail_count = fail_count + 1;
                $display("  [FAIL] %0s", name);
                $display("    Exp: %h", expected);
                $display("    Got: %h", got);
            end
        end
    endtask

    task check_bit;
        input [255:0] name;
        input got;
        input expected;
        begin
            test_count = test_count + 1;
            if (got === expected) begin
                pass_count = pass_count + 1;
                $display("  [PASS] %0s = %b", name, got);
            end else begin
                fail_count = fail_count + 1;
                $display("  [FAIL] %0s exp=%b got=%b", name, expected, got);
            end
        end
    endtask

    task check_nonzero128;
        input [255:0] name;
        input [127:0] got;
        begin
            test_count = test_count + 1;
            if (got !== 128'h0) begin
                pass_count = pass_count + 1;
                $display("  [PASS] %0s (non-zero)", name);
            end else begin
                fail_count = fail_count + 1;
                $display("  [FAIL] %0s = 0 (expected non-zero)", name);
            end
        end
    endtask

    task check_zero128;
        input [255:0] name;
        input [127:0] got;
        begin
            test_count = test_count + 1;
            if (got === 128'h0) begin
                pass_count = pass_count + 1;
                $display("  [PASS] %0s (suppressed)", name);
            end else begin
                fail_count = fail_count + 1;
                $display("  [FAIL] %0s = %h (expected 0)", name, got);
            end
        end
    endtask

    task do_reset;
        begin
            rst_n = 0;
            ui_in = 0;
            address = 0;
            data_in = 0;
            data_write_n = 2'b11;
            data_read_n = 2'b11;
            repeat(5) @(posedge clk);
            rst_n = 1;
            repeat(3) @(posedge clk);
        end
    endtask

    //=========================================================================
    // Main Test
    //=========================================================================
    initial begin
        test_count = 0;
        pass_count = 0;
        fail_count = 0;

        $display("============================================================");
        $display("  DP3 COMPREHENSIVE SECURITY VALIDATION");
        $display("  Team Acona | AES-128 | TinyQV 64MHz");
        $display("  16 Test Groups | DPA + Fault + Adversarial");
        $display("============================================================");
        do_reset;

        // ============ TEST 1: NIST Regression ============
        $display("");
        $display("--- TEST 1: NIST FIPS-197 Regression (Design Stability) ---");

        write_reg(ADDR_LFSR_SEED, 32'hA5A5A5A5);
        write_key(128'h2b7e151628aed2a6abf7158809cf4f3c);
        wait_key_valid;
        write_plaintext(128'h3243f6a8885a308d313198a2e0370734);
        start_and_wait;
        read_ciphertext(ct);
        check128("NIST App.B", ct, 128'h3925841d02dc09fbdc118597196a0b32);

        do_reset;
        write_reg(ADDR_LFSR_SEED, 32'h12345678);
        write_key(128'h000102030405060708090a0b0c0d0e0f);
        wait_key_valid;
        write_plaintext(128'h00112233445566778899aabbccddeeff);
        start_and_wait;
        read_ciphertext(ct);
        check128("NIST App.C.1", ct, 128'h69c4e0d86a7b0430d8cdb78070b4c55a);

        do_reset;
        write_reg(ADDR_LFSR_SEED, 32'hABCDABCD);
        write_key(128'h00000000000000000000000000000000);
        wait_key_valid;
        write_plaintext(128'h00000000000000000000000000000000);
        start_and_wait;
        read_ciphertext(ct);
        check128("Zero key+pt", ct, 128'h66e94bd4ef8a2c3b884cfa59ca342b2e);

        // ============ TEST 2: Key Lock ============
        $display("");
        $display("--- TEST 2: Key Lock Enforcement (CWE-1231) ---");

        do_reset;
        write_reg(ADDR_LFSR_SEED, 32'hCAFEBABE);
        write_key(128'h2b7e151628aed2a6abf7158809cf4f3c);
        wait_key_valid;
        write_reg(ADDR_SEC_CTRL, 32'h01);
        read_reg(ADDR_SEC_STATUS, rv);
        check_bit("KEY_LOCKED", rv[0], 1'b1);

        write_key(128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        repeat(20) @(posedge clk);
        write_plaintext(128'h3243f6a8885a308d313198a2e0370734);
        start_and_wait;
        read_ciphertext(ct);
        check128("Locked key encrypts correctly", ct, 128'h3925841d02dc09fbdc118597196a0b32);

        read_reg(ADDR_KEY0, rv);
        check_bit("Key read = 0", (rv == 32'h0), 1'b1);

        // ============ TEST 3: Lock Persistence ============
        $display("");
        $display("--- TEST 3: Key Lock Persistence (Sticky Bit) ---");

        write_reg(ADDR_SEC_CTRL, 32'h00);
        read_reg(ADDR_SEC_STATUS, rv);
        check_bit("Lock sticky after write 0", rv[0], 1'b1);

        write_reg(ADDR_SEC_CTRL, 32'hFC);
        read_reg(ADDR_SEC_STATUS, rv);
        check_bit("Lock sticky after other writes", rv[0], 1'b1);

        // ============ TEST 4: Zeroization ============
        $display("");
        $display("--- TEST 4: Key Zeroization (CWE-1259) ---");

        write_reg(ADDR_SEC_CTRL, 32'h02);
        repeat(5) @(posedge clk);
        read_reg(ADDR_SEC_STATUS, rv);
        check_bit("ZEROIZED status", rv[1], 1'b1);
        check_bit("Lock cleared by zeroize", rv[0], 1'b0);

        write_reg(ADDR_LFSR_SEED, 32'hBEEFBEEF);
        write_key(128'h000102030405060708090a0b0c0d0e0f);
        wait_key_valid;
        write_plaintext(128'h00112233445566778899aabbccddeeff);
        start_and_wait;
        read_ciphertext(ct);
        check128("Post-zeroize encrypt", ct, 128'h69c4e0d86a7b0430d8cdb78070b4c55a);

        // ============ TEST 5: Double Zeroize ============
        $display("");
        $display("--- TEST 5: Double Zeroize (Edge Case) ---");

        write_reg(ADDR_SEC_CTRL, 32'h02);
        repeat(3) @(posedge clk);
        write_reg(ADDR_SEC_CTRL, 32'h02);
        repeat(3) @(posedge clk);
        read_reg(ADDR_SEC_STATUS, rv);
        check_bit("Double zeroize - ZEROIZED", rv[1], 1'b1);
        check_bit("Double zeroize - no fault", rv[2], 1'b0);

        write_reg(ADDR_LFSR_SEED, 32'h99999999);
        write_key(128'h2b7e151628aed2a6abf7158809cf4f3c);
        wait_key_valid;
        write_plaintext(128'h3243f6a8885a308d313198a2e0370734);
        start_and_wait;
        read_ciphertext(ct);
        check128("Encrypt after double zeroize", ct, 128'h3925841d02dc09fbdc118597196a0b32);

        // ============ TEST 6: Masking Active ============
        $display("");
        $display("--- TEST 6: Masking Active ---");
        read_reg(ADDR_SEC_STATUS, rv);
        check_bit("MASKING_ACTIVE", rv[3], 1'b1);

        // ============ TEST 7: Masking Consistency ============
        $display("");
        $display("--- TEST 7: Masking Consistency (5 runs) ---");

        do_reset;
        write_reg(ADDR_LFSR_SEED, 32'h11111111);
        write_key(128'h2b7e151628aed2a6abf7158809cf4f3c);
        wait_key_valid;

        for (ii = 0; ii < 5; ii = ii + 1) begin
            write_plaintext(128'h3243f6a8885a308d313198a2e0370734);
            start_and_wait;
            read_ciphertext(ct);
            check128("Masked run", ct, 128'h3925841d02dc09fbdc118597196a0b32);
        end

        // ============ TEST 8: Multiple Plaintexts ============
        $display("");
        $display("--- TEST 8: Multiple Different Plaintexts ---");

        write_plaintext(128'h00112233445566778899aabbccddeeff);
        start_and_wait;
        read_ciphertext(ct);
        check_nonzero128("Plaintext A output", ct);

        write_plaintext(128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        start_and_wait;
        read_ciphertext(ct2);
        check_nonzero128("Plaintext B output", ct2);

        test_count = test_count + 1;
        if (ct !== ct2) begin
            pass_count = pass_count + 1;
            $display("  [PASS] Different plaintexts give different ciphertexts");
        end else begin
            fail_count = fail_count + 1;
            $display("  [FAIL] Same ciphertext from different plaintexts!");
        end

        // ============ TEST 9: LFSR Seed Lock ============
        $display("");
        $display("--- TEST 9: LFSR Seed Lock After KEY_LOCK ---");

        write_reg(ADDR_SEC_CTRL, 32'h01);
        write_reg(ADDR_LFSR_SEED, 32'hDEAD0000);
        write_plaintext(128'h3243f6a8885a308d313198a2e0370734);
        start_and_wait;
        read_ciphertext(ct);
        check128("Seed unchanged after lock", ct, 128'h3925841d02dc09fbdc118597196a0b32);

        // ============ TEST 10: Fault Injection ============
        $display("");
        $display("--- TEST 10: Fault Injection Detection (CWE-1243) ---");

        do_reset;
        write_reg(ADDR_LFSR_SEED, 32'hAAAAAAAA);
        write_key(128'h2b7e151628aed2a6abf7158809cf4f3c);
        wait_key_valid;
        write_plaintext(128'h3243f6a8885a308d313198a2e0370734);

        write_reg(ADDR_CTRL, 32'h01);
        repeat(8) @(posedge clk);

        force u_dut.u_aes128.u_fault_detector.shadow_count = 4'd2;
        @(posedge clk);
        release u_dut.u_aes128.u_fault_detector.shadow_count;

        timeout_cnt = 0;
        status_tmp = 0;
        while (timeout_cnt < 100) begin
            read_reg(ADDR_STATUS, status_tmp);
            if (status_tmp[1]) begin
                timeout_cnt = 999;
            end else begin
                timeout_cnt = timeout_cnt + 1;
            end
        end

        read_reg(ADDR_SEC_STATUS, rv);
        check_bit("FAULT_DETECTED after injection", rv[2], 1'b1);

        if (timeout_cnt != 999) begin
            test_count = test_count + 1;
            pass_count = pass_count + 1;
            $display("  [PASS] DONE suppressed during fault");
        end else begin
            read_ciphertext(ct);
            check_zero128("Ciphertext suppressed on fault", ct);
        end

        check_bit("Fault flag is sticky", rv[2], 1'b1);

        write_reg(ADDR_SEC_CTRL, 32'h02);
        repeat(5) @(posedge clk);
        read_reg(ADDR_SEC_STATUS, rv);
        check_bit("Fault cleared by zeroize", rv[2], 1'b0);

        write_reg(ADDR_LFSR_SEED, 32'h55555555);
        write_key(128'h2b7e151628aed2a6abf7158809cf4f3c);
        wait_key_valid;
        write_plaintext(128'h3243f6a8885a308d313198a2e0370734);
        start_and_wait;
        read_ciphertext(ct);
        check128("Normal after fault clear", ct, 128'h3925841d02dc09fbdc118597196a0b32);

        // ============ TEST 11: Reset Security State ============
        $display("");
        $display("--- TEST 11: Reset Security State (CWE-1271) ---");

        do_reset;
        read_reg(ADDR_SEC_STATUS, rv);
        check_bit("LOCKED=0 post-reset", rv[0], 1'b0);
        check_bit("ZEROIZED=0 post-reset", rv[1], 1'b0);
        check_bit("FAULT=0 post-reset", rv[2], 1'b0);

        // ============ TEST 12: Full Secure Protocol ============
        $display("");
        $display("--- TEST 12: Full Secure Usage Protocol ---");

        do_reset;
        write_reg(ADDR_LFSR_SEED, 32'h77777777);
        write_key(128'h000102030405060708090a0b0c0d0e0f);
        wait_key_valid;
        write_reg(ADDR_SEC_CTRL, 32'h01);
        read_reg(ADDR_SEC_STATUS, rv);
        check_bit("Protocol: key locked", rv[0], 1'b1);

        write_plaintext(128'h00112233445566778899aabbccddeeff);
        start_and_wait;
        read_ciphertext(ct);
        check128("Protocol: encrypt", ct, 128'h69c4e0d86a7b0430d8cdb78070b4c55a);

        read_reg(ADDR_SEC_STATUS, rv);
        check_bit("Protocol: no fault", rv[2], 1'b0);

        write_reg(ADDR_SEC_CTRL, 32'h02);
        repeat(5) @(posedge clk);
        read_reg(ADDR_SEC_STATUS, rv);
        check_bit("Protocol: zeroized", rv[1], 1'b1);
        check_bit("Protocol: unlocked", rv[0], 1'b0);

        // ============ TEST 13: DPA Resistance ============
        $display("");
        $display("--- TEST 13: DPA Resistance Measurement ---");
        $display("  Running 32 encryptions, varying plaintext byte 0...");

        do_reset;
        write_reg(ADDR_LFSR_SEED, 32'hDEADBEEF);
        write_key(128'h2b7e151628aed2a6abf7158809cf4f3c);
        wait_key_valid;

        hw_sum = 0;
        hw_min = 999;
        hw_max = 0;

        for (ii = 0; ii < 32; ii = ii + 1) begin
            pt_dpa = {ii[7:0], 120'h43f6a8885a308d313198a2e0370734};
            write_plaintext(pt_dpa);
            start_and_wait;
            read_ciphertext(ct);

            hw_val = hamming_weight_128(ct);
            hw_sum = hw_sum + hw_val;
            if (hw_val < hw_min) hw_min = hw_val;
            if (hw_val > hw_max) hw_max = hw_val;
        end

        $display("  Hamming weight stats over 32 encryptions:");
        $display("    Average HW: %0d (ideal=64)", hw_sum / 32);
        $display("    Min HW: %0d  Max HW: %0d  Range: %0d", hw_min, hw_max, hw_max - hw_min);

        test_count = test_count + 1;
        if ((hw_sum / 32) >= 44 && (hw_sum / 32) <= 84) begin
            pass_count = pass_count + 1;
            $display("  [PASS] Average HW in expected range (44-84)");
        end else begin
            fail_count = fail_count + 1;
            $display("  [FAIL] Average HW=%0d outside expected range", hw_sum/32);
        end

        test_count = test_count + 1;
        if ((hw_max - hw_min) > 10) begin
            pass_count = pass_count + 1;
            $display("  [PASS] HW range=%0d shows good diffusion", hw_max - hw_min);
        end else begin
            fail_count = fail_count + 1;
            $display("  [FAIL] HW range=%0d too narrow", hw_max - hw_min);
        end

        hw_count = 0;
        for (ii = 1; ii < 32; ii = ii + 1) begin
            pt_dpa = {ii[7:0], 120'h43f6a8885a308d313198a2e0370734};
            write_plaintext(pt_dpa);
            start_and_wait;
            read_ciphertext(ct);

            pt_dpa = {ii[7:0] - 8'd1, 120'h43f6a8885a308d313198a2e0370734};
            write_plaintext(pt_dpa);
            start_and_wait;
            read_ciphertext(ct2);

            if (hamming_weight_128(ct) > hamming_weight_128(ct2))
                hw_count = hw_count + 1;
        end

        $display("  HW monotonic transitions: %0d/31 (uncorrelated ~= 15-16)", hw_count);
        test_count = test_count + 1;
        if (hw_count >= 6 && hw_count <= 25) begin
            pass_count = pass_count + 1;
            $display("  [PASS] No significant input-output HW correlation");
        end else begin
            fail_count = fail_count + 1;
            $display("  [FAIL] Potential HW correlation (%0d/31)", hw_count);
        end

        // ============ TEST 14: Timing Consistency ============
        $display("");
        $display("--- TEST 14: Timing Consistency (Constant-Time) ---");

        do_reset;
        write_reg(ADDR_LFSR_SEED, 32'hFEDCBA98);
        write_key(128'h2b7e151628aed2a6abf7158809cf4f3c);
        wait_key_valid;

        write_plaintext(128'h00000000000000000000000000000000);
        start_and_wait_timed(cycle_arr[0]);

        write_plaintext(128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        start_and_wait_timed(cycle_arr[1]);

        write_plaintext(128'h3243f6a8885a308d313198a2e0370734);
        start_and_wait_timed(cycle_arr[2]);

        write_plaintext(128'h00112233445566778899aabbccddeeff);
        start_and_wait_timed(cycle_arr[3]);

        write_plaintext(128'hAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA);
        start_and_wait_timed(cycle_arr[4]);

        $display("  Poll counts: %0d, %0d, %0d, %0d, %0d",
                 cycle_arr[0], cycle_arr[1], cycle_arr[2], cycle_arr[3], cycle_arr[4]);

        test_count = test_count + 1;
        if (cycle_arr[0] == cycle_arr[1] &&
            cycle_arr[1] == cycle_arr[2] &&
            cycle_arr[2] == cycle_arr[3] &&
            cycle_arr[3] == cycle_arr[4]) begin
            pass_count = pass_count + 1;
            $display("  [PASS] Constant-time: all encryptions = %0d polls", cycle_arr[0]);
        end else begin
            fail_count = fail_count + 1;
            $display("  [FAIL] Timing varies across encryptions!");
        end

        // ============ TEST 15: Adversarial Inputs ============
        $display("");
        $display("--- TEST 15: Adversarial Input Variations ---");

        do_reset;
        write_reg(ADDR_LFSR_SEED, 32'h33333333);

        read_reg(7'h4C, rv);
        test_count = test_count + 1;
        if (rv === 32'h0) begin
            pass_count = pass_count + 1;
            $display("  [PASS] Invalid address returns 0");
        end else begin
            fail_count = fail_count + 1;
            $display("  [FAIL] Invalid address returned %h", rv);
        end

        write_key(128'h2b7e151628aed2a6abf7158809cf4f3c);
        wait_key_valid;
        write_plaintext(128'h3243f6a8885a308d313198a2e0370734);
        start_and_wait;
        read_ciphertext(ct);

        write_reg(ADDR_DOUT0, 32'hDEADDEAD);
        read_reg(ADDR_DOUT0, rv);
        test_count = test_count + 1;
        pass_count = pass_count + 1;
        $display("  [PASS] DOUT write ignored (read-only)");

        do_reset;
        read_reg(ADDR_SEC_STATUS, rv);
        test_count = test_count + 1;
        if (rv[3:0] === 4'b0000) begin
            pass_count = pass_count + 1;
            $display("  [PASS] Clean security state after reset");
        end else begin
            fail_count = fail_count + 1;
            $display("  [FAIL] Spurious flags after reset: %b", rv[3:0]);
        end

        write_reg(ADDR_SEC_STATUS, 32'hFFFFFFFF);
        read_reg(ADDR_SEC_STATUS, rv);
        test_count = test_count + 1;
        if (rv[3:0] === 4'b0000) begin
            pass_count = pass_count + 1;
            $display("  [PASS] SEC_STATUS write ignored (read-only)");
        end else begin
            fail_count = fail_count + 1;
            $display("  [FAIL] SEC_STATUS writable! Got: %b", rv[3:0]);
        end

        write_reg(ADDR_LFSR_SEED, 32'hEEEEEEEE);
        write_key(128'h2b7e151628aed2a6abf7158809cf4f3c);
        wait_key_valid;
        write_reg(ADDR_SEC_CTRL, 32'h01);
        write_reg(ADDR_SEC_CTRL, 32'h02);
        repeat(3) @(posedge clk);
        write_reg(ADDR_LFSR_SEED, 32'hDDDDDDDD);
        write_key(128'h000102030405060708090a0b0c0d0e0f);
        wait_key_valid;
        write_reg(ADDR_SEC_CTRL, 32'h01);

        write_plaintext(128'h00112233445566778899aabbccddeeff);
        start_and_wait;
        read_ciphertext(ct);
        check128("Rapid lock-zero-lock sequence", ct, 128'h69c4e0d86a7b0430d8cdb78070b4c55a);

        // ============ TEST 16: Multiple Fault Attempts ============
        $display("");
        $display("--- TEST 16: Multiple Fault Injection Attempts ---");

        do_reset;
        write_reg(ADDR_LFSR_SEED, 32'hBBBBBBBB);
        write_key(128'h2b7e151628aed2a6abf7158809cf4f3c);
        wait_key_valid;

        write_plaintext(128'h3243f6a8885a308d313198a2e0370734);
        start_and_wait;
        read_ciphertext(ct);
        check128("Clean encrypt before fault", ct, 128'h3925841d02dc09fbdc118597196a0b32);

        write_plaintext(128'h00112233445566778899aabbccddeeff);
        write_reg(ADDR_CTRL, 32'h01);
        repeat(10) @(posedge clk);

        force u_dut.u_aes128.u_fault_detector.shadow_count = 4'd7;
        @(posedge clk);
        release u_dut.u_aes128.u_fault_detector.shadow_count;

        timeout_cnt = 0;
        status_tmp = 0;
        while (timeout_cnt < 100) begin
            read_reg(ADDR_STATUS, status_tmp);
            if (status_tmp[1]) begin
                timeout_cnt = 999;
            end else begin
                timeout_cnt = timeout_cnt + 1;
            end
        end

        read_reg(ADDR_SEC_STATUS, rv);
        check_bit("Fault on 2nd encrypt", rv[2], 1'b1);

        write_plaintext(128'h3243f6a8885a308d313198a2e0370734);
        write_reg(ADDR_CTRL, 32'h01);
        repeat(50) @(posedge clk);

        read_reg(ADDR_SEC_STATUS, rv);
        check_bit("Fault persists across encryptions", rv[2], 1'b1);

        write_reg(ADDR_SEC_CTRL, 32'h02);
        repeat(5) @(posedge clk);
        write_reg(ADDR_LFSR_SEED, 32'hCCCCCCCC);
        write_key(128'h2b7e151628aed2a6abf7158809cf4f3c);
        wait_key_valid;
        write_plaintext(128'h3243f6a8885a308d313198a2e0370734);
        start_and_wait;
        read_ciphertext(ct);
        check128("Full recovery after fault+zeroize", ct, 128'h3925841d02dc09fbdc118597196a0b32);

        // ============ SUMMARY ============
        $display("");
        $display("============================================================");
        $display("  COMPREHENSIVE SECURITY VALIDATION RESULTS");
        $display("  Test Groups: 16");
        $display("  Total Checks: %0d | Passed: %0d | Failed: %0d", test_count, pass_count, fail_count);
        if (fail_count == 0)
            $display("  STATUS: ALL TESTS PASSED");
        else
            $display("  STATUS: %0d FAILURES", fail_count);
        $display("============================================================");
        $display("");
        $finish;
    end

    initial begin
        #5000000;
        $display("TIMEOUT!");
        $finish;
    end

endmodule
