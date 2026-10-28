module dma_fifo_latch (
    input  wire        clk,          // System Clock
    input  wire        rst_n,        // Active low reset
    input  wire        wr_en,
    input  wire [31:0] wdata,
    input  wire        rd_en,
    output wire [31:0] rdata,
    output wire        full,
    output wire        empty
);

    parameter DEPTH = 16;
    parameter PTR_WIDTH = 4;

    // --- 1. Gray Code Pointers (Low Power Switching) ---
    reg [PTR_WIDTH:0] w_ptr_bin, w_ptr_gray;
    reg [PTR_WIDTH:0] r_ptr_bin, r_ptr_gray;
    
    // Logic Dual-port (giả lập cho Latch array)
    reg [31:0] mem_array [0:DEPTH-1];

    // --- 2. Clock Gating Logic (Manual Implementation) ---
    // Trong ASIC thực tế, bạn nên dùng cell thư viện (ví dụ: ICG_X1)
    // Logic: Clock chỉ bật khi có lệnh GHI và FIFO chưa đầy.
    wire gclk;
    assign gclk = clk & (wr_en & !full); 

    // --- 3. Latch-based Memory Array ---
    // Sử dụng cơ chế Transparent Latch: Dữ liệu đi qua khi Clock mức cao
    // Lưu ý: Cần constraints thời gian (STA) kỹ lưỡng cho Latch.
    integer i;
    always @(*) begin
        if (gclk) begin
            mem_array[w_ptr_bin[PTR_WIDTH-1:0]] = wdata;
        end
    end

    // Read Data (Continuous read - Latch output is always valid)
    assign rdata = mem_array[r_ptr_bin[PTR_WIDTH-1:0]];

    // --- Pointer Logic (Standard FIFO) ---
    wire [PTR_WIDTH:0] w_ptr_gray_next, w_ptr_bin_next;
    wire [PTR_WIDTH:0] r_ptr_gray_next, r_ptr_bin_next;

    // Bin to Gray
    assign w_ptr_bin_next = w_ptr_bin + 1;
    assign w_ptr_gray_next = (w_ptr_bin_next >> 1) ^ w_ptr_bin_next;
    
    assign r_ptr_bin_next = r_ptr_bin + 1;
    assign r_ptr_gray_next = (r_ptr_bin_next >> 1) ^ r_ptr_bin_next;

    // Write Pointer Update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            w_ptr_bin <= 0;
            w_ptr_gray <= 0;
        end else if (wr_en && !full) begin
            w_ptr_bin <= w_ptr_bin_next;
            w_ptr_gray <= w_ptr_gray_next;
        end
    end

    // Read Pointer Update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_ptr_bin <= 0;
            r_ptr_gray <= 0;
        end else if (rd_en && !empty) begin
            r_ptr_bin <= r_ptr_bin_next;
            r_ptr_gray <= r_ptr_gray_next;
        end
    end

    // --- Full/Empty Flag Generation (Async comparison) ---
    // Empty: Gray pointers identical
    assign empty = (w_ptr_gray == r_ptr_gray);
    
    // Full: MSB distinct, 2nd MSB distinct, rest identical
    assign full = (w_ptr_gray[PTR_WIDTH] != r_ptr_gray[PTR_WIDTH]) &&
                  (w_ptr_gray[PTR_WIDTH-1] != r_ptr_gray[PTR_WIDTH-1]) &&
                  (w_ptr_gray[PTR_WIDTH-2:0] == r_ptr_gray[PTR_WIDTH-2:0]);

endmodule