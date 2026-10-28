`timescale 1ns/1ps

module tb_dma_top;

    // Clock và Reset
    reg clk;
    reg rst_n;

    // APB Signals
    reg         psel;
    reg         penable;
    reg         pwrite;
    reg  [31:0] paddr;
    reg  [31:0] pwdata;
    wire [31:0] prdata;
    wire        pready;
    wire        pslverr;

    // Interrupts
    wire dma_irq;
    wire security_violation;

    // AXI4 Master (Mô phỏng đơn giản bằng cách phản hồi ready)
    reg m_axi_arready, m_axi_awready, m_axi_wready, m_axi_bvalid;

    // Khởi tạo Module DMA Top với vùng an toàn mẫu
    dma_top #(
        .SAFE_BASE_ADDR(32'h8000_0000),
        .SAFE_BOUND_ADDR(32'h80FF_FFFF)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .psel(psel),
        .penable(penable),
        .pwrite(pwrite),
        .paddr(paddr),
        .pwdata(pwdata),
        .prdata(prdata),
        .pready(pready),
        .pslverr(pslverr),
        .dma_irq(dma_irq),
        .security_violation(security_violation),
        // Kết nối các tín hiệu AXI (để trống hoặc nối dummy cho TB này)
        .m_axi_arready(m_axi_arready),
        .m_axi_awready(m_axi_awready),
        .m_axi_wready(m_axi_wready),
        .m_axi_bvalid(m_axi_bvalid)
        // ... các tín hiệu khác nối tương ứng ...
    );

    // Tạo xung Clock
    always #5 clk = ~clk;

    // Task ghi APB
    task apb_write(input [31:0] addr, input [31:0] data);
        begin
            @(posedge clk);
            psel = 1; paddr = addr; pwdata = data; pwrite = 1;
            @(posedge clk);
            penable = 1;
            wait(pready);
            @(posedge clk);
            psel = 0; penable = 0; pwrite = 0;
        end
    endtask

    initial begin
        // Khởi tạo tín hiệu
        clk = 0; rst_n = 0;
        psel = 0; penable = 0; pwrite = 0; paddr = 0; pwdata = 0;
        m_axi_arready = 1; m_axi_awready = 1; m_axi_wready = 1; m_axi_bvalid = 1;

        #20 rst_n = 1;
        #10;

        // --- KỊCH BẢN 1: GIAO DỊCH HỢP LỆ (Normal Functionality) ---
        $display("[%0t] TEST 1: Starting Valid Transfer...", $time);
        apb_write(32'h04, 32'h8000_1000); // cfg_src_addr (Trong vùng an toàn)
        apb_write(32'h08, 32'h8000_2000); // cfg_dst_addr (Trong vùng an toàn)
        apb_write(32'h0C, 32'h0000_0100); // cfg_byte_len (256 bytes)
        apb_write(32'h00, 32'h0000_0001); // cfg_start = 1
        
        #50;
        if (dut.secure_cfg_start) 
            $display("[%0t] PASS: Valid transfer allowed through Security Gate.", $time);
        else 
            $display("[%0t] FAIL: Valid transfer was blocked!", $time);


        // --- KỊCH BẢN 2: TẤN CÔNG BẢO MẬT (Proof of Security) ---
        $display("\n[%0t] TEST 2: Starting Illegal Transfer (Attack)...", $time);
        apb_write(32'h04, 32'h1000_0000); // cfg_src_addr (NGOÀI vùng an toàn - 0x1000...)
        apb_write(32'h00, 32'h0000_0001); // cfg_start = 1
        
        #20;
        if (!dut.secure_cfg_start && security_violation) begin
            $display("[%0t] SUCCESS: Security Gate blocked the attack!", $time);
            $display("[%0t] SUCCESS: security_violation signal triggered.", $time);
        end else begin
            $display("[%0t] CRITICAL FAIL: Security Gate leaked an illegal address!", $time);
        end

        #100 $finish;
    end

endmodule