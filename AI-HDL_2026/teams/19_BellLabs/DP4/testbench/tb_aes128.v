`timescale 1ns/1ps

module tb_aes128;

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
    always #8 clk=~clk;

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

    integer i, pass_count;
    reg [31:0] c0,c1,c2,c3,status;

    initial begin
        pass_count=0;
        rst_n=0; ui_in=8'h00;
        address=6'h00; data_in=32'h0;
        data_write_n=2'b11; data_read_n=2'b11;

        $dumpfile("waves.vcd");
        $dumpvars(0, tb_aes128);

        // ══════════════════════════════════════════════
        // TEST 1 — NIST vector 000102.../001122...
        // ══════════════════════════════════════════════
        do_reset;

        write32(6'h00, 32'h00010203); // KEY_W0
        write32(6'h04, 32'h04050607); // KEY_W1
        write32(6'h08, 32'h08090a0b); // KEY_W2
        write32(6'h0C, 32'h0c0d0e0f); // KEY_W3
        write32(6'h10, 32'h00112233); // PLAIN_W0
        write32(6'h14, 32'h44556677); // PLAIN_W1
        write32(6'h18, 32'h8899aabb); // PLAIN_W2
        write32(6'h1C, 32'hccddeeff); // PLAIN_W3
        write32(6'h0E, 32'hACE12345); write32(6'h20, 32'h00000001);

        // Wait for encryption (10 rounds = 10 cycles + some overhead)
        repeat(15) @(posedge clk);

        status=32'h0;
        for(i=0;i<20;i=i+1) begin
            read32(6'h24,status);
            if(status[0]==1'b1) i=99;
        end

        read32(6'h28,c0); read32(6'h2C,c1);
        read32(6'h30,c2); read32(6'h34,c3);

        $display("============================================");
        $display("TEST 1 — NIST vector 000102.../001122...");
        $display("Expected: 69c4e0d8  6a7b0430  d8cdb780  70b4c55a");
        $display("Got:      %08h  %08h  %08h  %08h",c0,c1,c2,c3);
        if(c0===32'h69c4e0d8 && c1===32'h6a7b0430 &&
           c2===32'hd8cdb780 && c3===32'h70b4c55a) begin
            $display("TEST 1: PASSED");
            pass_count=pass_count+1;
        end else begin
            $display("TEST 1: FAILED");
        end

        // ══════════════════════════════════════════════
        // TEST 2 — NIST SP 800-38A ECB-AES128 vector 1
        // ══════════════════════════════════════════════
        do_reset;

        write32(6'h00, 32'h2b7e1516); // KEY_W0
        write32(6'h04, 32'h28aed2a6); // KEY_W1
        write32(6'h08, 32'habf71588); // KEY_W2
        write32(6'h0C, 32'h09cf4f3c); // KEY_W3
        write32(6'h10, 32'h6bc1bee2); // PLAIN_W0
        write32(6'h14, 32'h2e409f96); // PLAIN_W1
        write32(6'h18, 32'he93d7e11); // PLAIN_W2
        write32(6'h1C, 32'h7393172a); // PLAIN_W3
        write32(6'h0E, 32'hACE12345); write32(6'h20, 32'h00000001);

        // Wait for encryption (10 rounds = 10 cycles + some overhead)
        repeat(15) @(posedge clk);

        status=32'h0;
        for(i=0;i<20;i=i+1) begin
            read32(6'h24,status);
            if(status[0]==1'b1) i=99;
        end

        read32(6'h28,c0); read32(6'h2C,c1);
        read32(6'h30,c2); read32(6'h34,c3);

        $display("============================================");
        $display("TEST 2 — NIST SP800-38A ECB-AES128 vector 1");
        $display("Expected: 3ad77bb4  0d7a3660  a89ecaf3  2466ef97");
        $display("Got:      %08h  %08h  %08h  %08h",c0,c1,c2,c3);
        if(c0===32'h3ad77bb4 && c1===32'h0d7a3660 &&
           c2===32'ha89ecaf3 && c3===32'h2466ef97) begin
            $display("TEST 2: PASSED");
            pass_count=pass_count+1;
        end else begin
            $display("TEST 2: FAILED");
        end

        // ══════════════════════════════════════════════
        // TEST 3 — Security (Key Lockout & Poisoning)
        // ══════════════════════════════════════════════
        $display("============================================");
        $display("TEST 3 — Security (Key Lockout)");
        do_reset;

        // 1. Set a known key
        write32(6'h00, 32'h12345678);
        read32(6'h00, c0);
        if (c0 === 32'h12345678) 
            $display("[SEC] Pre-lock Read: SUCCESS (Real key visible)");
        else 
            $display("[SEC] Pre-lock Read: FAILED (Got %h)", c0);

        // 2. Start encryption to engage lock
        write32(6'h0E, 32'hACE12345); write32(6'h20, 32'h00000001);
        
        // 3. Check STATUS[2] for Key Locked flag
        read32(6'h24, status);
        if (status[2] === 1'b1)
            $display("[SEC] STATUS[2] Lock Flag: SUCCESS (Locked)");
        else
            $display("[SEC] STATUS[2] Lock Flag: FAILED");

        // 4. Try to read key again (should be poisoned)
        read32(6'h00, c0);
        if (c0 === 32'hDEADBEEF)
            $display("[SEC] Post-lock Read: SUCCESS (Poisoned with 0xDEADBEEF)");
        else
            $display("[SEC] Post-lock Read: FAILED (Got %h)", c0);

        if (c0 === 32'hDEADBEEF && status[2] === 1'b1) begin
            $display("TEST 3: PASSED");
            pass_count = pass_count + 1;
        end else begin
            $display("TEST 3: FAILED");
        end

        $display("============================================");
        if(pass_count==3)
            $display("ALL TESTS PASSED — DP3 security verification complete");
        else
            $display("REGRESSION FAILED — %0d/3 tests passed", pass_count);
        $display("============================================");
        $finish;
    end

endmodule
