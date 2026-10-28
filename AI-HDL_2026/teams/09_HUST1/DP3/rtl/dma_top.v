module dma_top #(
    parameter [31:0] SAFE_BASE_ADDR  = 32'h8000_0000,
    parameter [31:0] SAFE_BOUND_ADDR = 32'h80FF_FFFF
)(
    input  wire        clk,
    input  wire        rst_n,

    // APB Slave Interface
    input  wire        psel,
    input  wire        penable,
    input  wire        pwrite,
    input  wire [31:0] paddr,
    input  wire [31:0] pwdata,
    output wire [31:0] prdata,
    output wire        pready,
    output wire        pslverr,

    // Interrupt & Security Alarm
    output reg         dma_irq,
    output reg         security_violation,

    // AXI4 Master Interface
    output wire [31:0] m_axi_araddr,
    output wire [7:0]  m_axi_arlen,
    output wire [2:0]  m_axi_arsize,
    output wire [1:0]  m_axi_arburst,
    output wire        m_axi_arvalid,
    input  wire        m_axi_arready,
    input  wire [31:0] m_axi_rdata,
    input  wire        m_axi_rlast,
    input  wire        m_axi_rvalid,
    output wire        m_axi_rready,
    output wire [31:0] m_axi_awaddr,
    output wire [7:0]  m_axi_awlen,
    output wire [2:0]  m_axi_awsize,
    output wire [1:0]  m_axi_awburst,
    output wire        m_axi_awvalid,
    input  wire        m_axi_awready,
    output wire [31:0] m_axi_wdata,
    output wire        m_axi_wlast,
    output wire        m_axi_wvalid,
    input  wire        m_axi_wready,
    input  wire        m_axi_bvalid,
    output wire        m_axi_bready
);

    // 1. Khai báo đầy đủ tín hiệu nội bộ (Đã fix lỗi thiếu signals)
    wire [31:0] cfg_src_addr, cfg_dst_addr, cfg_byte_len;
    wire        cfg_start, clear_irq;
    wire        status_busy, status_done;
    
    wire        fifo_full, fifo_empty;
    wire        fifo_wr_en, fifo_rd_en;
    wire [31:0] fifo_wdata, fifo_rdata;

    wire        is_src_safe;
    wire        is_dst_safe;
    wire        is_config_safe;
    wire        secure_cfg_start;

    // 2. Logic Kiểm tra Bảo mật (Đã fix lỗi tràn số bằng cách sử dụng 33-bit addition)
    assign is_src_safe = (cfg_src_addr >= SAFE_BASE_ADDR) && 
                         ({1'b0, cfg_src_addr} + {1'b0, cfg_byte_len} <= {1'b0, SAFE_BOUND_ADDR});
                         
    assign is_dst_safe = (cfg_dst_addr >= SAFE_BASE_ADDR) && 
                         ({1'b0, cfg_dst_addr} + {1'b0, cfg_byte_len} <= {1'b0, SAFE_BOUND_ADDR});
    
    assign is_config_safe = is_src_safe && is_dst_safe;
    assign secure_cfg_start = cfg_start && is_config_safe;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) security_violation <= 1'b0;
        else if (cfg_start && !is_config_safe) security_violation <= 1'b1;
        else if (clear_irq) security_violation <= 1'b0;
    end

    // 3. Khởi tạo các Sub-modules (Đã nối đầy đủ Port)
    dma_apb_slave u_slave (
        .pclk(clk), .presetn(rst_n),
        .psel(psel), .penable(penable), .pwrite(pwrite), .paddr(paddr), .pwdata(pwdata),
        .prdata(prdata), .pready(pready), .pslverr(pslverr),
        .cfg_src_addr(cfg_src_addr), .cfg_dst_addr(cfg_dst_addr), .cfg_byte_len(cfg_byte_len),
        .cfg_start(cfg_start), .status_done(status_done), .status_busy(status_busy), .clear_irq(clear_irq)
    );

    dma_fifo_latch #(.DEPTH(16)) u_fifo (
        .clk(clk), .rst_n(rst_n),
        .wr_en(fifo_wr_en), .wdata(fifo_wdata),
        .rd_en(fifo_rd_en), .rdata(fifo_rdata),
        .full(fifo_full), .empty(fifo_empty)
    );

    dma_axi_master u_master (
        .aclk(clk), .aresetn(rst_n),
        .cfg_src_addr(cfg_src_addr), .cfg_dst_addr(cfg_dst_addr), .cfg_byte_len(cfg_byte_len),
        .cfg_start(secure_cfg_start), .status_busy(status_busy), .status_done(status_done),
        .fifo_full(fifo_full), .fifo_empty(fifo_empty),
        .fifo_wr_en(fifo_wr_en), .fifo_wdata(fifo_wdata),
        .fifo_rd_en(fifo_rd_en), .fifo_rdata(fifo_rdata),
        // AXI Mappings
        .m_axi_araddr(m_axi_araddr), .m_axi_arlen(m_axi_arlen), .m_axi_arsize(m_axi_arsize),
        .m_axi_arburst(m_axi_arburst), .m_axi_arvalid(m_axi_arvalid), .m_axi_arready(m_axi_arready),
        .m_axi_rdata(m_axi_rdata), .m_axi_rlast(m_axi_rlast), .m_axi_rvalid(m_axi_rvalid), .m_axi_rready(m_axi_rready),
        .m_axi_awaddr(m_axi_awaddr), .m_axi_awlen(m_axi_awlen), .m_axi_awsize(m_axi_awsize),
        .m_axi_awburst(m_axi_awburst), .m_axi_awvalid(m_axi_awvalid), .m_axi_awready(m_axi_awready),
        .m_axi_wdata(m_axi_wdata), .m_axi_wlast(m_axi_wlast), .m_axi_wvalid(m_axi_wvalid), .m_axi_wready(m_axi_wready),
        .m_axi_bvalid(m_axi_bvalid), .m_axi_bready(m_axi_bready)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) dma_irq <= 0;
        else if (status_done || security_violation) dma_irq <= 1;
        else if (clear_irq) dma_irq <= 0;
    end

endmodule