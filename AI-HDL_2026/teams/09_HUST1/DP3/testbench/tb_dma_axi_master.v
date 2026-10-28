`timescale 1ns / 1ps

module tb_dma_axi_master;

    reg clk;
    reg rst_n;

    // Config Inputs
    reg [31:0] cfg_src_addr = 32'h1000;
    reg [31:0] cfg_dst_addr = 32'h2000;
    reg [31:0] cfg_byte_len = 64; // 1 burst = 16 beats x 4 bytes
    reg        cfg_start;
    
    // Status Outputs
    wire status_busy, status_done;

    // FIFO Mock Signals
    reg         fifo_full, fifo_empty;
    wire        fifo_wr_en, fifo_rd_en;
    wire [31:0] fifo_wdata;
    reg  [31:0] fifo_rdata;

    // AXI Interface Signals
    wire [31:0] awaddr, araddr, wdata;
    wire [7:0]  awlen, arlen;
    wire        awvalid, wvalid, wlast, bready;
    wire        arvalid, rready;
    reg         awready, wready, bvalid;
    reg         arready, rvalid, rlast;
    reg  [31:0] rdata;

    // --- Instantiate DUT ---
    dma_axi_master u_dut (
        .aclk(clk), .aresetn(rst_n),
        .cfg_src_addr(cfg_src_addr), .cfg_dst_addr(cfg_dst_addr), 
        .cfg_byte_len(cfg_byte_len), .cfg_start(cfg_start),
        .status_busy(status_busy), .status_done(status_done),
        .fifo_full(fifo_full), .fifo_empty(fifo_empty),
        .fifo_wr_en(fifo_wr_en), .fifo_wdata(fifo_wdata),
        .fifo_rd_en(fifo_rd_en), .fifo_rdata(fifo_rdata),
        
        .m_axi_araddr(araddr), .m_axi_arlen(arlen), .m_axi_arvalid(arvalid), .m_axi_arready(arready),
        .m_axi_rdata(rdata), .m_axi_rlast(rlast), .m_axi_rvalid(rvalid), .m_axi_rready(rready),
        
        .m_axi_awaddr(awaddr), .m_axi_awlen(awlen), .m_axi_awvalid(awvalid), .m_axi_awready(awready),
        .m_axi_wdata(wdata), .m_axi_wlast(wlast), .m_axi_wvalid(wvalid), .m_axi_wready(wready),
        .m_axi_bvalid(bvalid), .m_axi_bready(bready)
    );

    // --- Clock Gen ---
    initial clk = 0;
    always #5 clk = ~clk;

    // --- AXI Memory Mock (Read Channel) ---
    integer r_beat_cnt = 0;
    always @(posedge clk) begin
        if (!rst_n) begin
            arready <= 0; rvalid <= 0; rlast <= 0; rdata <= 0;
        end else begin
            // Chấp nhận Address ngay lập tức
            arready <= 1; 
            
            if (arvalid && arready) begin
                rvalid <= 1;
                r_beat_cnt <= 0;
                rdata <= 32'hCAFE_0000;
            end
            
            if (rvalid && rready) begin
                if (r_beat_cnt == arlen) begin
                    rvalid <= 0;
                    rlast <= 0;
                end else begin
                    r_beat_cnt <= r_beat_cnt + 1;
                    rdata <= rdata + 1; // Tăng dữ liệu lên 1 sau mỗi beat
                    rlast <= (r_beat_cnt == arlen - 1);
                end
            end
        end
    end

    // --- FIFO Mock Behavior ---
    always @(posedge clk) begin
        // Giả lập FIFO có sẵn dữ liệu để Write Engine đọc
        if (fifo_wr_en) fifo_empty <= 0; 
        
        if (fifo_rd_en) fifo_rdata <= fifo_rdata + 1; // Cấp dữ liệu liên tục cho AXI Write
        else fifo_rdata <= 32'hDEAD_0000;
    end

    // --- AXI Memory Mock (Write Channel) ---
    always @(posedge clk) begin
        if (!rst_n) begin
            awready <= 0; wready <= 0; bvalid <= 0;
        end else begin
            awready <= 1; 
            wready <= 1;  // Luôn sẵn sàng nhận dữ liệu

            if (wvalid && wready && wlast) begin
                bvalid <= 1; // Báo ghi xong
            end else if (bvalid && bready) begin
                bvalid <= 0;
            end
        end
    end

    // --- Main Test Sequence ---
    initial begin
        $dumpfile("axi_master_wave.vcd");
        $dumpvars(0, tb_dma_axi_master);

        rst_n = 0; cfg_start = 0; 
        fifo_full = 0; fifo_empty = 1;
        #20; rst_n = 1; #10;

        $display("\n=== STARTING DMA AXI MASTER SIMULATION ===");
        
        // Kích hoạt DMA
        @(posedge clk);
        cfg_start <= 1;
        @(posedge clk);
        cfg_start <= 0;

        // Chờ toàn bộ quá trình hoàn tất (Status Done = 1)
        wait(status_done);
        $display("[PASS] DMA Transfer Completed successfully!");
        $display("       - Total bytes configured: %d", cfg_byte_len);
        $display("       - Status Done flag asserted.\n");

        #50;
        $finish;
    end
endmodule