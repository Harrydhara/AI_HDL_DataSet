`default_nettype none

/**
 * UART FIFO Buffer
 * 
 * Configurable depth FIFO for UART TX/RX data buffering.
 * Default 16-byte depth with watermark detection.
 * 
 * Features:
 * - Dual-pointer (read/write) circular buffer
 * - Status flags: full, empty, watermark
 * - Overflow/underflow protection
 * - Watermark threshold (default 14 bytes for flow control)
 * 
 * Operation:
 * - Write: Assert wr_en with wr_data when !full
 * - Read:  Assert rd_en when !empty, data available next cycle
 * - Watermark: Asserts when count >= watermark threshold
 * 
 * Timing:
 * - Write: Data stored on posedge clk if wr_en && !full
 * - Read:  Data available on rd_data output on posedge clk if rd_en && !empty
 * - Flags update synchronously with read/write operations
 */
module uart_fifo #(
    parameter DEPTH = 16,              // FIFO depth (must be power of 2)
    parameter DATA_WIDTH = 8,          // Data width in bits
    parameter WATERMARK = 14           // Watermark threshold for flow control
)(
    input  wire                  clk,         // System clock
    input  wire                  rst_n,       // Active-low reset
    
    // Write interface
    input  wire [DATA_WIDTH-1:0] wr_data,     // Data to write
    input  wire                  wr_en,       // Write enable
    
    // Read interface
    output reg  [DATA_WIDTH-1:0] rd_data,     // Data read output
    input  wire                  rd_en,       // Read enable
    
    // Status flags
    output wire                  full,        // FIFO full
    output wire                  empty,       // FIFO empty
    output wire                  watermark,   // Count >= WATERMARK
    output wire [4:0]            count        // Current data count (0-16)
);

    // Address width based on depth
    localparam ADDR_WIDTH = $clog2(DEPTH);
    
    // Internal memory array
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    integer i;  // For initialization loop
    
    // Read and write pointers
    reg [ADDR_WIDTH:0] wr_ptr;  // Extra bit for full/empty distinction
    reg [ADDR_WIDTH:0] rd_ptr;  // Extra bit for full/empty distinction
    
    // Internal count register
    reg [ADDR_WIDTH:0] fifo_count;
    
    // Status flag generation
    assign full  = (fifo_count == DEPTH);
    assign empty = (fifo_count == 0);
    assign watermark = (fifo_count >= WATERMARK);
    assign count = fifo_count;
    
    // Write operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= {(ADDR_WIDTH+1){1'b0}};
            // Initialize memory to prevent X/Z values
            for (i = 0; i < DEPTH; i = i + 1) begin
                mem[i] <= {DATA_WIDTH{1'b0}};
            end
        end else begin
            if (wr_en && !full) begin
                mem[wr_ptr[ADDR_WIDTH-1:0]] <= wr_data;
                wr_ptr <= wr_ptr + 1'b1;
            end
        end
    end
    
    // Read operation - combinational data output with registered pointer
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr <= {(ADDR_WIDTH+1){1'b0}};
        end else begin
            if (rd_en && !empty) begin
                rd_ptr <= rd_ptr + 1'b1;
            end
        end
    end
    
    // Combinational read data
    always @(*) begin
        rd_data = mem[rd_ptr[ADDR_WIDTH-1:0]];
    end
    
    // FIFO count tracking
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fifo_count <= {(ADDR_WIDTH+1){1'b0}};
        end else begin
            case ({wr_en && !full, rd_en && !empty})
                2'b10: fifo_count <= fifo_count + 1'b1;  // Write only
                2'b01: fifo_count <= fifo_count - 1'b1;  // Read only
                2'b11: fifo_count <= fifo_count;         // Simultaneous read/write
                default: fifo_count <= fifo_count;       // No operation
            endcase
        end
    end
    
    // Synthesis assertions (commented out for simulation compatibility)
    // These help catch configuration errors during synthesis
    // synthesis translate_off
    initial begin
        if (DEPTH != (1 << $clog2(DEPTH))) begin
            $display("ERROR: FIFO DEPTH must be a power of 2");
            $finish;
        end
        if (WATERMARK >= DEPTH) begin
            $display("ERROR: WATERMARK must be less than DEPTH");
            $finish;
        end
    end
    // synthesis translate_on

endmodule

`default_nettype wire
