`timescale 1ns / 1ps

module tb_dma_apb_slave;

    // --- Signals ---
    reg clk;
    reg rst_n;
    // APB Signals
    reg         psel, penable, pwrite;
    reg  [31:0] paddr, pwdata;
    wire [31:0] prdata;
    wire        pready, pslverr;
    
    // Internal Signals (Outputs of Slave)
    wire [31:0] cfg_src_addr, cfg_dst_addr, cfg_byte_len;
    wire        cfg_start, clear_irq;
    
    // Internal Inputs (Status from Core)
    reg         status_done, status_busy;

    // --- Instantiate DUT ---
    dma_apb_slave u_dut (
        .pclk(clk), .presetn(rst_n),
        .psel(psel), .penable(penable), .pwrite(pwrite),
        .paddr(paddr), .pwdata(pwdata), .prdata(prdata),
        .pready(pready), .pslverr(pslverr),
        .cfg_src_addr(cfg_src_addr), .cfg_dst_addr(cfg_dst_addr),
        .cfg_byte_len(cfg_byte_len), .cfg_start(cfg_start),
        .status_done(status_done), .status_busy(status_busy),
        .clear_irq(clear_irq)
    );

    // --- Clock Generation ---
    initial clk = 0;
    always #5 clk = ~clk;

    // --- APB Tasks ---
    task apb_write(input [31:0] addr, input [31:0] data);
        begin
            @(posedge clk);
            psel <= 1; pwrite <= 1;
            paddr <= addr; pwdata <= data; penable <= 0;
            @(posedge clk);
            penable <= 1;
            wait(pready);
            @(posedge clk);
            psel <= 0;
            penable <= 0; pwrite <= 0;
        end
    endtask

    task apb_read_and_check(input [31:0] addr, input [31:0] exp_data, input [8*20:1] test_name);
        begin
            @(posedge clk);
            psel <= 1; pwrite <= 0;
            paddr <= addr; penable <= 0;
            @(posedge clk);
            penable <= 1;
            wait(pready);
            #1;
            // Lấy mẫu sau khi ổn định
            if (prdata !== exp_data) 
                $error("[FAIL] %s - Addr: %h | Exp: %h, Got: %h", test_name, addr, exp_data, prdata);
            else 
                $display("[PASS] %s - Val: %h", test_name, prdata);
            @(posedge clk);
            psel <= 0; penable <= 0;
        end
    endtask

    // --- Main Test Sequence ---
    initial begin
        $dumpfile("apb_slave_wave.vcd");
        $dumpvars(0, tb_dma_apb_slave);
        
        // Init
        rst_n = 0; psel = 0; penable = 0;
        pwrite = 0;
        status_done = 0; status_busy = 0;
        #20; rst_n = 1; #10;

        $display("\n=== TEST 1: GHI/ĐỌC CÁC THANH GHI CẤU HÌNH ===");
        apb_write(32'h04, 32'hAAAA_0000); // Src Addr
        apb_write(32'h08, 32'hBBBB_0000); // Dst Addr
        apb_write(32'h0C, 32'd256);       // Length

        apb_read_and_check(32'h04, 32'hAAAA_0000, "Read Source Addr");
        apb_read_and_check(32'h08, 32'hBBBB_0000, "Read Dest Addr  ");
        apb_read_and_check(32'h0C, 32'd256,       "Read Byte Length");

        $display("\n=== TEST 2: ĐỌC THANH GHI TRẠNG THÁI (STATUS) ===");
        status_busy = 1; status_done = 0;
        apb_read_and_check(32'h10, 32'h0000_0001, "Status: Busy=1, Done=0");
        
        status_busy = 0; status_done = 1;
        apb_read_and_check(32'h10, 32'h0000_0002, "Status: Busy=0, Done=1");

        $display("\n=== TEST 3: KIỂM TRA AUTO-CLEAR PULSE CỦA CONTROL REG ===");
        apb_write(32'h00, 32'h0000_0003); // Set Start (bit 0) và Clear IRQ (bit 1)
        
        // Ngay chu kỳ sau, tín hiệu phải được tạo ra và tự động xóa
        if (cfg_start === 1 && clear_irq === 1) 
            $display("[PASS] Pulse Control generated correctly");
        else 
            $error("[FAIL] Pulse Control failed");
            
        @(posedge clk);
        // Đợi 1 chu kỳ để auto-clear hoạt động
        if (cfg_start === 0 && clear_irq === 0)
            $display("[PASS] Auto-clear works perfectly");
        else
            $error("[FAIL] Auto-clear did not reset signals");
            
        // End simulation
        #50;
        $finish;
    end // End of initial block

endmodule // End of tb_dma_apb_slave