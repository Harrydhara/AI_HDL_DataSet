//==============================================================================
// tb_interface.v — Testbench for winograd_peripheral
//
// Address map (step=4, byte-addressed):
//  0x00  CTRL          0x04  STATUS        0x08  CONFIG
//  0x0C  INPUT_IDX     0x10  INPUT_DATA    (write 16x, auto-increment)
//  0x14  FILTER_IDX    0x18  FILTER_DATA   (write 9x, auto-increment)
//  0x1C  OUTPUT[0]     0x20  OUTPUT[1]     0x24  OUTPUT[2]     0x28  OUTPUT[3]
//  0x2C  ACC[0]        0x30  ACC[1]        0x34  ACC[2]        0x38  ACC[3]
//==============================================================================
`timescale 1ns/1ps

module tb_interface;

    parameter DATA_WIDTH = 32;
    parameter FRAC_BITS  = 16;
    parameter CLK_PERIOD = 10;

    reg                   clk;
    reg                   rstn;
    reg  [5:0]            address;
    reg  [1:0]            data_write_n;
    reg  [1:0]            data_read_n;
    reg  [DATA_WIDTH-1:0] data_in;
    wire [DATA_WIDTH-1:0] data_out;
    wire                  data_ready;
    wire                  winograd_irq;

    integer i, ch, error_count, timeout;
    reg [31:0] read_val, status_val;

    // -----------------------------------------------------------------------
    // Address constants
    // -----------------------------------------------------------------------
    localparam CTRL_ADDR    = 6'h00;
    localparam STATUS_ADDR  = 6'h04;
    localparam CONFIG_ADDR  = 6'h08;
    localparam INPUT_IDX    = 6'h0C;
    localparam INPUT_DATA   = 6'h10;
    localparam FILTER_IDX   = 6'h14;
    localparam FILTER_DATA  = 6'h18;
    localparam OUTPUT_0     = 6'h1C;
    localparam OUTPUT_1     = 6'h20;
    localparam OUTPUT_2     = 6'h24;
    localparam OUTPUT_3     = 6'h28;
    localparam ACC_0        = 6'h2C;
    localparam ACC_1        = 6'h30;
    localparam ACC_2        = 6'h34;
    localparam ACC_3        = 6'h38;

    // CTRL bits
    localparam CTRL_START      = 32'h01;
    localparam CTRL_ACCUM_EN   = 32'h08;
    localparam CTRL_CLEAR_ACC  = 32'h10;
    localparam CTRL_IRQ_EN     = 32'h20;
    localparam CTRL_START_ACCUM= 32'h09;   // START | ACCUM_EN

    // -----------------------------------------------------------------------
    // DUT
    // -----------------------------------------------------------------------
    winograd_peripheral #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC_BITS (FRAC_BITS)
    ) dut (
        .clk(clk), .rstn(rstn),
        .address(address),
        .data_write_n(data_write_n),
        .data_read_n (data_read_n),
        .data_in(data_in),
        .data_out(data_out),
        .data_ready(data_ready),
        .winograd_irq(winograd_irq)
    );

    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // -----------------------------------------------------------------------
    // Bus helpers
    // -----------------------------------------------------------------------
    task write_reg;
        input [5:0]  addr;
        input [31:0] wdata;
        begin
            @(posedge clk); #1;
            address      = addr;
            data_in      = wdata;
            data_write_n = 2'b10;   // 32-bit write
            data_read_n  = 2'b11;
            @(posedge clk); #1;
            data_write_n = 2'b11;
            @(posedge clk); #1;
        end
    endtask

    task read_reg;
        input  [5:0]  addr;
        output [31:0] rdata;
        begin
            @(posedge clk); #1;
            address      = addr;
            data_write_n = 2'b11;
            data_read_n  = 2'b10;   // 32-bit read
            @(posedge clk); #1;
            @(posedge clk); #1;
            rdata       = data_out;
            data_read_n = 2'b11;
            @(posedge clk); #1;
        end
    endtask

    task wait_done;
        begin
            repeat(5) @(posedge clk);
            timeout = 0;
            read_reg(STATUS_ADDR, status_val);
            while (status_val[0] == 1'b1 && timeout < 20000) begin
                @(posedge clk);
                read_reg(STATUS_ADDR, status_val);
                timeout = timeout + 1;
            end
            if (timeout >= 20000) begin
                $display("  ERROR: Timeout waiting for BUSY=0!");
                error_count = error_count + 1;
            end
        end
    endtask

    // -----------------------------------------------------------------------
    // Load helpers (use auto-index FIFO)
    // -----------------------------------------------------------------------
    reg [31:0] filter_vals [0:8];
    reg [31:0] input_vals  [0:15];

    task load_inputs;
        integer k;
        begin
            write_reg(INPUT_IDX, 32'd0);          // reset index = 0
            for (k = 0; k < 16; k = k + 1)
                write_reg(INPUT_DATA, input_vals[k]);  // auto-increment
        end
    endtask

    task load_filters;
        integer k;
        begin
            write_reg(FILTER_IDX, 32'd0);         // reset index = 0
            for (k = 0; k < 9; k = k + 1)
                write_reg(FILTER_DATA, filter_vals[k]); // auto-increment
        end
    endtask

    task run_one_channel;
        input with_accum;
        begin
            load_filters();
            load_inputs();
            if (with_accum)
                write_reg(CTRL_ADDR, CTRL_START_ACCUM);
            else
                write_reg(CTRL_ADDR, CTRL_START);
            wait_done();
        end
    endtask

    // -----------------------------------------------------------------------
    // Pass/fail helper
    // -----------------------------------------------------------------------
    task check;
        input [5:0]  addr;
        input [31:0] expected;
        input [63:0] label;   // up to 8 chars for $display
        begin
            read_reg(addr, read_val);
            if (read_val === expected) begin
                $display("  PASS: %s = %f (0x%08h)",
                         label, $itor($signed(expected))/65536.0, expected);
            end else begin
                $display("  FAIL: %s expected 0x%08h (%f), got 0x%08h (%f)",
                         label, expected, $itor($signed(expected))/65536.0,
                         read_val, $itor($signed(read_val))/65536.0);
                error_count = error_count + 1;
            end
        end
    endtask

    // -----------------------------------------------------------------------
    // Test body
    // -----------------------------------------------------------------------
    initial begin
        error_count  = 0;
        address      = 6'h0;
        data_in      = 32'h0;
        data_write_n = 2'b11;
        data_read_n  = 2'b11;

        $display("\n============================================================");
        $display("  TB: winograd_peripheral — address map v2");
        $display("============================================================");

        rstn = 0; #(CLK_PERIOD * 10);
        rstn = 1; #(CLK_PERIOD * 5);

        // --------------------------------------------------------------------
        // TEST 1: Single channel, no accumulation
        // filter = all 1.0, input = 1..16
        // Expected 2x2 outputs: 54, 63, 90, 99
        // --------------------------------------------------------------------
        $display("\n--- TEST 1: Single channel, all-ones filter, input 1..16 ---");

        for (i = 0; i < 9;  i = i+1) filter_vals[i] = 32'h00010000; // 1.0
        for (i = 0; i < 16; i = i+1) input_vals[i]  = (i+1) << 16;  // 1.0 .. 16.0

        run_one_channel(0);

        check(OUTPUT_0, 32'h00360000, "out[0]");  // 54.0
        check(OUTPUT_1, 32'h003F0000, "out[1]");  // 63.0
        check(OUTPUT_2, 32'h005A0000, "out[2]");  // 90.0
        check(OUTPUT_3, 32'h00630000, "out[3]");  // 99.0

        // ACC should be 0 (ACCUM_EN was off)
        read_reg(ACC_0, read_val);
        if (read_val === 32'h0)
            $display("  PASS: acc[0] = 0 (ACCUM_EN was off)");
        else begin
            $display("  FAIL: acc[0] should be 0, got 0x%08h", read_val);
            error_count = error_count + 1;
        end

        // --------------------------------------------------------------------
        // TEST 2: 3 channels with ACCUM_EN
        // filter=1.0, input = all c+1 for channel c → per-channel conv = 9*(c+1)
        // acc = 9*1 + 9*2 + 9*3 = 54 for each output pixel
        // --------------------------------------------------------------------
        $display("\n--- TEST 2: 3 channels with ACCUM_EN (expect acc=54.0) ---");

        write_reg(CTRL_ADDR, CTRL_CLEAR_ACC);
        #(CLK_PERIOD * 2);
        read_reg(ACC_0, read_val);
        if (read_val === 32'h0)
            $display("  PASS: acc cleared");
        else begin
            $display("  FAIL: acc not cleared (0x%08h)", read_val);
            error_count = error_count + 1;
        end

        for (ch = 0; ch < 3; ch = ch+1) begin
            $display("  [Channel %0d] input = %0d.0", ch, ch+1);
            for (i = 0; i < 9;  i = i+1) filter_vals[i] = 32'h00010000;    // 1.0
            for (i = 0; i < 16; i = i+1) input_vals[i]  = (ch+1) << 16;    // (c+1).0
            run_one_channel(1);
        end

        check(ACC_0, 32'h00360000, "acc[0]");   // 54.0
        check(ACC_1, 32'h00360000, "acc[1]");   // 54.0
        check(ACC_2, 32'h00360000, "acc[2]");   // 54.0
        check(ACC_3, 32'h00360000, "acc[3]");   // 54.0

        // Last channel output = 9*3 = 27.0
        check(OUTPUT_0, 32'h001B0000, "out[0] last ch");

        // --------------------------------------------------------------------
        // TEST 3: CLEAR_ACC then run 1 channel → acc == output
        // --------------------------------------------------------------------
        $display("\n--- TEST 3: CLEAR_ACC then 1 channel → acc == output ---");

        write_reg(CTRL_ADDR, CTRL_CLEAR_ACC);
        #(CLK_PERIOD * 2);

        for (i = 0; i < 9;  i = i+1) filter_vals[i] = 32'h00010000; // 1.0
        for (i = 0; i < 16; i = i+1) input_vals[i]  = 32'h00020000; // 2.0
        run_one_channel(1);

        read_reg(ACC_0,    read_val);
        read_reg(OUTPUT_0, status_val);
        $display("  acc[0]    = %f", $itor($signed(read_val))/65536.0);
        $display("  output[0] = %f", $itor($signed(status_val))/65536.0);
        if (read_val === status_val)
            $display("  PASS: acc == output");
        else begin
            $display("  FAIL: acc=0x%08h, out=0x%08h", read_val, status_val);
            error_count = error_count + 1;
        end

        // --------------------------------------------------------------------
        // TEST 4: 2 identical channels, filter=0.5, input=1..16
        // Each channel conv output = [27, 31.5, 45, 49.5]
        // ACC after 2 channels      = [54, 63,  90, 99  ]
        // --------------------------------------------------------------------
        $display("\n--- TEST 4: 2 channels, filter=0.5, input 1..16 → acc=[54,63,90,99] ---");

        write_reg(CTRL_ADDR, CTRL_CLEAR_ACC);
        #(CLK_PERIOD * 2);

        for (ch = 0; ch < 2; ch = ch+1) begin
            for (i = 0; i < 9;  i = i+1) filter_vals[i] = 32'h00008000; // 0.5
            for (i = 0; i < 16; i = i+1) input_vals[i]  = (i+1) << 16;
            run_one_channel(1);
        end

        check(ACC_0, 32'h00360000, "acc[0]");   // 54.0
        check(ACC_1, 32'h003F0000, "acc[1]");   // 63.0
        check(ACC_2, 32'h005A0000, "acc[2]");   // 90.0
        check(ACC_3, 32'h00630000, "acc[3]");   // 99.0

        // --------------------------------------------------------------------
        // TEST 5: Read back INPUT_IDX and FILTER_IDX after loading
        // --------------------------------------------------------------------
        $display("\n--- TEST 5: Read-back INPUT_IDX / FILTER_IDX ---");

        // Load 16 inputs → IDX should have auto-incremented to 15 (capped)
        write_reg(INPUT_IDX, 32'd0);
        for (i = 0; i < 16; i = i+1)
            write_reg(INPUT_DATA, 32'hAABBCCDD);
        read_reg(INPUT_IDX, read_val);
        if (read_val === 32'd15)
            $display("  PASS: INPUT_IDX = 15 after 16 writes");
        else begin
            $display("  FAIL: INPUT_IDX expected 15, got %0d", read_val);
            error_count = error_count + 1;
        end

        // Load 9 filters → IDX should auto-increment to 8 (capped)
        write_reg(FILTER_IDX, 32'd0);
        for (i = 0; i < 9; i = i+1)
            write_reg(FILTER_DATA, 32'h11223344);
        read_reg(FILTER_IDX, read_val);
        if (read_val === 32'd8)
            $display("  PASS: FILTER_IDX = 8 after 9 writes");
        else begin
            $display("  FAIL: FILTER_IDX expected 8, got %0d", read_val);
            error_count = error_count + 1;
        end

        // Set IDX mid-stream and verify
        write_reg(INPUT_IDX, 32'd5);
        read_reg(INPUT_IDX, read_val);
        if (read_val === 32'd5)
            $display("  PASS: INPUT_IDX set to 5 correctly");
        else begin
            $display("  FAIL: INPUT_IDX expected 5, got %0d", read_val);
            error_count = error_count + 1;
        end

        // --------------------------------------------------------------------
        // RESULTS
        // --------------------------------------------------------------------
        #(CLK_PERIOD * 10);
        $display("\n============================================================");
        $display("  Tests: 5  Errors: %0d", error_count);
        if (error_count == 0)
            $display("  Result: ALL TESTS PASSED ✓");
        else
            $display("  Result: SOME TESTS FAILED ✗");
        $display("============================================================\n");
        $finish;
    end

    initial begin
        #500_000_000;
        $display("GLOBAL TIMEOUT");
        $finish;
    end

endmodule