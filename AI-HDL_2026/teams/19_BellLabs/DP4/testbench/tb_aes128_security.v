`timescale 1ns/1ps
// ============================================================
// Bell Labs — University of Lagos, Nigeria
// AI Hardware Design League 2026 — Team #63
// DP3 Security Validation Testbench
// ============================================================

module tb_aes128_security;

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

    tqvp_belllabs_aes128 dut (
        .clk(clk),.rst_n(rst_n),.ui_in(ui_in),
        .uo_out(uo_out),.address(address),
        .data_in(data_in),.data_write_n(data_write_n),
        .data_read_n(data_read_n),.data_out(data_out),
        .data_ready(data_ready),.user_interrupt(user_interrupt)
    );

    initial clk=0;
    always #8 clk=~clk; // 62.5 MHz (approx 64 MHz target)

    task write32;
        input [5:0]  addr;
        input [31:0] data;
        begin
            @(negedge clk);
            address=addr; data_in=data;
            data_write_n=2'b10; data_read_n=2'b11;
            @(posedge clk); #1;
            data_write_n=2'b11;
        end
    endtask

    task read32;
        input  [5:0]  addr;
        output [31:0] rdata;
        begin
            @(negedge clk);
            address=addr;
            data_write_n=2'b11; data_read_n=2'b10;
            @(posedge clk); #1;
            rdata=data_out;
            data_read_n=2'b11;
        end
    endtask

    task do_reset;
        begin
            rst_n=0;
            repeat(5) @(posedge clk);
            #1; rst_n=1;
            repeat(2) @(posedge clk);
        end
    endtask

    task wait_done;
        reg [31:0] status;
        begin
            status = 0;
            while (status[0] == 0) begin
                read32(6'h24, status);
                if (status[0] == 0) repeat(1) @(posedge clk);
            end
        end
    endtask

    // Helper for timing
    task wait_done_count;
        output integer cycles;
        reg [31:0] status;
        begin
            cycles = 0;
            status = 0;
            while (status[0] == 0) begin
                read32(6'h24, status);
                cycles = cycles + 1;
                if (status[0] == 0) repeat(1) @(posedge clk);
            end
        end
    endtask

    reg [31:0] c0,c1,c2,c3,status;
    reg [31:0] ref_c0, ref_c1, ref_c2, ref_c3;
    integer pass_count;

    initial begin
        pass_count=0;
        rst_n=0; ui_in=8'h00;
        address=6'h00; data_in=32'h0;
        data_write_n=2'b11; data_read_n=2'b11;

        $display("============================================================");
        $display("DP3 SECURITY VALIDATION TESTBENCH — Team Bell Labs (#63)");
        $display("============================================================");

        // ══════════════════════════════════════════════
        // TEST 1 — Functional Correctness (NIST)
        // ══════════════════════════════════════════════
        $display("\nTEST 1 — Functional correctness (regression):");
        do_reset;

        // Vector 1
        write32(6'h00, 32'h00010203); // KEY_W0
        write32(6'h04, 32'h04050607); // KEY_W1
        write32(6'h08, 32'h08090a0b); // KEY_W2
        write32(6'h0C, 32'h0c0d0e0f); // KEY_W3
        write32(6'h10, 32'h00112233); // PLAIN_W0
        write32(6'h14, 32'h44556677); // PLAIN_W1
        write32(6'h18, 32'h8899aabb); // PLAIN_W2
        write32(6'h1C, 32'hccddeeff); // PLAIN_W3
        write32(6'h20, 32'h00000001); // START
        
        wait_done;

        read32(6'h28,c0); read32(6'h2C,c1);
        read32(6'h30,c2); read32(6'h34,c3);

        if(c0===32'h69c4e0d8 && c1===32'h6a7b0430 &&
           c2===32'hd8cdb780 && c3===32'h70b4c55a) begin
            $display("  NIST Vector 1: PASS");
            pass_count = pass_count + 1;
        end else begin
            $display("  NIST Vector 1: FAIL (Got %h %h %h %h)", c0, c1, c2, c3);
        end

        // ══════════════════════════════════════════════
        // TEST 2 — Key Lockout Validation
        // ══════════════════════════════════════════════
        $display("\nTEST 2 — Key lockout validation:");
        do_reset;

        // Step 1: Write key = 0xAABBCCDD to KEY_W0
        write32(6'h00, 32'hAABBCCDD);
        
        // Step 2: Write START to CTRL
        write32(6'h20, 32'h00000001);

        // Step 3: Read KEY_W0 -> Must return 0xDEADBEEF
        read32(6'h00, status);
        if (status === 32'hDEADBEEF)
            $display("  Step 3: Read KEY_W0 -> 0xDEADBEEF (OK)");
        else
            $display("  Step 3: Read KEY_W0 -> FAILED (Got %h)", status);

        // Step 4: Check STATUS[2] == 1
        read32(6'h24, status);
        if (status[2] === 1'b1) begin
            $display("  Step 4: STATUS[2] == 1 (KEY_LOCKED set)");
            $display("REPORT: KEY LOCKOUT PASS");
            pass_count = pass_count + 1;
        end else begin
            $display("  Step 4: STATUS[2] == 0 (FAILED)");
            $display("REPORT: KEY LOCKOUT FAIL");
        end

        // ══════════════════════════════════════════════
        // TEST 3 — Mask Seed Variation (Transparency)
        // ══════════════════════════════════════════════
        $display("\nTEST 3 — Mask seed variation (masking sanity check):");
        
        // Run 1: MASK_SEED = 32'h12345678
        do_reset;
        write32(6'h0E, 32'h12345678); // MASK_SEED
        write32(6'h00, 32'h00010203); // Vector 1 Key
        write32(6'h04, 32'h04050607);
        write32(6'h08, 32'h08090a0b);
        write32(6'h0C, 32'h0c0d0e0f);
        write32(6'h10, 32'h00112233); // Vector 1 Plain
        write32(6'h14, 32'h44556677);
        write32(6'h18, 32'h8899aabb);
        write32(6'h1C, 32'hccddeeff);
        write32(6'h20, 32'h00000001); // START
        wait_done;
        read32(6'h28, ref_c0); read32(6'h2C, ref_c1);
        read32(6'h30, ref_c2); read32(6'h34, ref_c3);
        $display("  Run 1 (Seed 12345678) Cipher: %h %h %h %h", ref_c0, ref_c1, ref_c2, ref_c3);

        // Run 2: MASK_SEED = 32'hABCDEF00
        do_reset;
        write32(6'h0E, 32'hABCDEF00); // MASK_SEED
        write32(6'h00, 32'h00010203); // Vector 1 Key
        write32(6'h04, 32'h04050607);
        write32(6'h08, 32'h08090a0b);
        write32(6'h0C, 32'h0c0d0e0f);
        write32(6'h10, 32'h00112233); // Vector 1 Plain
        write32(6'h14, 32'h44556677);
        write32(6'h18, 32'h8899aabb);
        write32(6'h1C, 32'hccddeeff);
        write32(6'h20, 32'h00000001); // START
        wait_done;
        read32(6'h28, c0); read32(6'h2C, c1);
        read32(6'h30, c2); read32(6'h34, c3);
        $display("  Run 2 (Seed ABCDEF00) Cipher: %h %h %h %h", c0, c1, c2, c3);

        if (c0===ref_c0 && c1===ref_c1 && c2===ref_c2 && c3===ref_c3) begin
            $display("REPORT: MASKING TRANSPARENCY PASS");
            pass_count = pass_count + 1;
        end else begin
            $display("REPORT: MASKING TRANSPARENCY FAIL");
        end

        // ══════════════════════════════════════════════
        // TEST 4 — Timing Invariance (Constant Time)
        // ══════════════════════════════════════════════
        $display("\nTEST 4 — Timing Invariance (Constant Time):");
        begin: timing_test
            integer cycles1, cycles2;
            
            do_reset;
            write32(6'h00, 32'h00010203);
            write32(6'h10, 32'h00112233);
            
            write32(6'h20, 32'h00000001); // START
            wait_done_count(cycles1);
            $display("  Vector 1 Encryption: %0d iterations", cycles1);
            
            do_reset;
            write32(6'h00, 32'hFFFFFFFF); // Different key
            write32(6'h10, 32'hAAAAAAAA); // Different plain
            
            write32(6'h20, 32'h00000001); // START
            wait_done_count(cycles2);
            
            if (cycles1 == cycles2) begin
                $display("  Vector 2 Encryption: %0d iterations (MATCH)", cycles2);
                $display("REPORT: TIMING INVARIANCE PASS");
                pass_count = pass_count + 1;
            end else begin
                $display("  Vector 2 Encryption: %0d iterations (MISMATCH)", cycles2);
                $display("REPORT: TIMING INVARIANCE FAIL");
            end
        end

        // ══════════════════════════════════════════════
        // FINAL SUMMARY
        // ══════════════════════════════════════════════
        $display("\n============================================================");
        if (pass_count === 4)
            $display("OVERALL RESULT: ALL SECURITY TESTS PASSED (4/4)");
        else
            $display("OVERALL RESULT: FAILED (%0d/4 passed)", pass_count);
        $display("============================================================");
        $finish;
    end

endmodule
