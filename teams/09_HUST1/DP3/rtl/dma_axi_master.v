module dma_axi_master (
    input  wire         aclk,
    input  wire         aresetn,

    // Configuration
    input  wire [31:0]  cfg_src_addr,
    input  wire [31:0]  cfg_dst_addr,
    input  wire [31:0]  cfg_byte_len,
    input  wire         cfg_start,
    
    // Status
    output reg          status_busy,
    output reg          status_done,

    // FIFO Interface
    input  wire         fifo_full,
    input  wire         fifo_empty,
    output reg          fifo_wr_en,
    output reg  [31:0]  fifo_wdata,
    output reg          fifo_rd_en,
    input  wire [31:0]  fifo_rdata,

    // AXI4 Read Channel
    output reg  [31:0]  m_axi_araddr,
    output reg  [7:0]   m_axi_arlen,
    output wire [2:0]   m_axi_arsize,
    output wire [1:0]   m_axi_arburst,
    output reg          m_axi_arvalid,
    input  wire         m_axi_arready,
    input  wire [31:0]  m_axi_rdata,
    input  wire         m_axi_rlast,
    input  wire         m_axi_rvalid,
    output reg          m_axi_rready,

    // AXI4 Write Channel
    output reg  [31:0]  m_axi_awaddr,
    output reg  [7:0]   m_axi_awlen,
    output wire [2:0]   m_axi_awsize,
    output wire [1:0]   m_axi_awburst,
    output reg          m_axi_awvalid,
    input  wire         m_axi_awready,
    output reg  [31:0]  m_axi_wdata,
    output reg          m_axi_wlast,
    output reg          m_axi_wvalid,
    input  wire         m_axi_wready,
    input  wire         m_axi_bvalid,
    output reg          m_axi_bready
);

    assign m_axi_arsize  = 3'b010;
    assign m_axi_arburst = 2'b01; 
    assign m_axi_awsize  = 3'b010;
    assign m_axi_awburst = 2'b01;

    reg [31:0] read_addr_ptr, write_addr_ptr;
    reg [31:0] read_bytes_left, write_bytes_left;
    reg read_active, write_active;

    localparam BURST_LEN = 8'd15;
    localparam BYTES_PER_BURST = 64;

    // 1. READ ENGINE - GRAY CODE FSM
    localparam R_IDLE = 2'b00, R_ADDR = 2'b01, R_DATA = 2'b11;
    reg [1:0] r_state;

    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            r_state <= R_IDLE;
            m_axi_arvalid <= 0;
            m_axi_rready  <= 0;
            read_bytes_left <= 0;
            read_active <= 0;
            fifo_wr_en <= 0;
        end else begin
            fifo_wr_en <= 0;
            case (r_state)
                R_IDLE: begin
                    if (cfg_start) begin
                        read_addr_ptr <= cfg_src_addr;
                        read_bytes_left <= cfg_byte_len;
                        read_active <= 1;
                        r_state <= R_ADDR;
                    end
                end
                R_ADDR: begin
                    if (read_bytes_left == 0) begin
                        read_active <= 0;
                        r_state <= R_IDLE;
                    end else if (!fifo_full) begin 
                        m_axi_araddr  <= read_addr_ptr;
                        if (read_bytes_left > BYTES_PER_BURST)
                            m_axi_arlen <= BURST_LEN;
                        else
                            m_axi_arlen <= (read_bytes_left >> 2) - 1;
                        m_axi_arvalid <= 1;
                        r_state <= R_DATA;
                    end
                end
                R_DATA: begin
                    if (m_axi_arready && m_axi_arvalid) begin
                        m_axi_arvalid <= 0;
                    end
                    m_axi_rready <= 1;
                    if (m_axi_rvalid && m_axi_rready) begin
                        fifo_wdata <= m_axi_rdata;
                        fifo_wr_en <= 1;
                        if (m_axi_rlast) begin
                            read_addr_ptr <= read_addr_ptr + ((m_axi_arlen + 1) << 2);
                            read_bytes_left <= read_bytes_left - ((m_axi_arlen + 1) << 2);
                            r_state <= R_ADDR;
                            m_axi_rready <= 0;
                        end
                    end
                end
            endcase
        end
    end

    // 2. WRITE ENGINE - GRAY CODE FSM
    localparam W_IDLE = 2'b00, W_ADDR = 2'b01, W_DATA = 2'b11, W_RESP = 2'b10;
    reg [1:0] w_state;
    reg [7:0] w_burst_cnt;

    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            w_state <= W_IDLE;
            m_axi_awvalid <= 0;
            m_axi_wvalid <= 0;
            m_axi_bready <= 0;
            write_bytes_left <= 0;
            write_active <= 0;
            status_done <= 0;
            fifo_rd_en <= 0;
        end else begin
            fifo_rd_en <= 0;
            status_done <= 0;
            case (w_state)
                W_IDLE: begin
                    if (cfg_start) begin
                        write_addr_ptr <= cfg_dst_addr;
                        write_bytes_left <= cfg_byte_len;
                        write_active <= 1;
                        status_busy <= 1;
                        w_state <= W_ADDR;
                    end else if (!write_active) begin
                        status_busy <= 0;
                    end
                end
                W_ADDR: begin
                    if (write_bytes_left == 0) begin
                        write_active <= 0;
                        status_done <= 1; 
                        w_state <= W_IDLE;
                    end else if (!fifo_empty) begin 
                        m_axi_awaddr <= write_addr_ptr;
                        if (write_bytes_left > BYTES_PER_BURST)
                            m_axi_awlen <= BURST_LEN;
                        else
                            m_axi_awlen <= (write_bytes_left >> 2) - 1;
                        m_axi_awvalid <= 1;
                        w_burst_cnt <= 0;
                        w_state <= W_DATA;
                    end
                end
                W_DATA: begin
                    if (m_axi_awready && m_axi_awvalid) begin
                        m_axi_awvalid <= 0;
                    end
                    if (!fifo_empty) begin
                        m_axi_wvalid <= 1;
                        m_axi_wdata  <= fifo_rdata;
                        if (w_burst_cnt == m_axi_awlen) m_axi_wlast <= 1;
                        else m_axi_wlast <= 0;
                    end
                    if (m_axi_wready && m_axi_wvalid) begin
                         fifo_rd_en <= 1;
                         w_burst_cnt <= w_burst_cnt + 1;
                         if (m_axi_wlast) begin
                             m_axi_wvalid <= 0;
                             m_axi_wlast <= 0;
                             w_state <= W_RESP;
                         end
                    end
                end
                W_RESP: begin
                    m_axi_bready <= 1;
                    if (m_axi_bvalid && m_axi_bready) begin
                        m_axi_bready <= 0;
                        write_addr_ptr <= write_addr_ptr + ((m_axi_awlen + 1) << 2);
                        write_bytes_left <= write_bytes_left - ((m_axi_awlen + 1) << 2);
                        w_state <= W_ADDR;
                    end
                end
            endcase
        end
    end
endmodule