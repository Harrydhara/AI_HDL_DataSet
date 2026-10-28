module dma_apb_slave (
    input  wire        pclk,
    input  wire        presetn,
    
    // APB Interface
    input  wire        psel,
    input  wire        penable,
    input  wire        pwrite,
    input  wire [31:0] paddr,
    input  wire [31:0] pwdata,
  
    output reg  [31:0] prdata,
    output wire        pready,
    output wire        pslverr,

    // Interface to DMA Core
    output reg  [31:0] cfg_src_addr,
    output reg  [31:0] cfg_dst_addr,
    output reg  [31:0] cfg_byte_len,
    output reg         cfg_start,
    input  wire        status_done,
    input  wire        status_busy,
    output reg         clear_irq
);

    // APB Handshake
    assign pready  = 1'b1;
    assign pslverr = 1'b0;

    // Write Logic
    always @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            cfg_src_addr <= 0;
            cfg_dst_addr <= 0;
            cfg_byte_len <= 0;
            cfg_start    <= 0;
            clear_irq    <= 0;
        end else begin
            cfg_start <= 0;
            clear_irq <= 0;

            if (psel && penable && pwrite) begin
                case (paddr[7:0])
                    8'h00: begin
                        cfg_start <= pwdata[0];
                        clear_irq <= pwdata[1];
                    end
                    8'h04: cfg_src_addr <= pwdata;
                    8'h08: cfg_dst_addr <= pwdata;
                    8'h0C: cfg_byte_len <= pwdata;
                endcase
            end
        end
    end

    // Read Logic - Khôi phục dạng tổ hợp gốc 100% để bảo toàn Area
    always @(*) begin
        prdata = 32'b0;
        if (psel && !pwrite) begin // Read phase
            case (paddr[7:0])
                8'h00: prdata = {30'b0, clear_irq, cfg_start};
                8'h04: prdata = cfg_src_addr;
                8'h08: prdata = cfg_dst_addr;
                8'h0C: prdata = cfg_byte_len;
                8'h10: prdata = {30'b0, status_done, status_busy};
            endcase
        end
    end
endmodule