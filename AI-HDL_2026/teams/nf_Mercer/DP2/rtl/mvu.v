`default_nettype none
// ---------------------------------------------------------------------------
// mvu  –  4×4 Matrix-Vector Unit  (optimized)
//
// ---------------------------------------------------------------------------
module mvu (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        cs,
    input  wire        we,
    input  wire [6:0]  addr,
    input  wire [31:0] wdata,
    output reg  [31:0] rdata
);

    // ------------------------------------------------------------------
    // OPT-1: 2-D weight array — 16 registers, same silicon, far less code
    // ------------------------------------------------------------------
    reg [31:0] x [0:3];
    reg [31:0] w [0:3][0:3];

    reg        start;
    reg        done;

    // ------------------------------------------------------------------
    // VPU result wires
    // ------------------------------------------------------------------
    wire [31:0] res [0:3];
    wire        vpu_done [0:3];

    // ------------------------------------------------------------------
    // OPT-6: y outputs are combinational wires from vpu results
    //   Removes 4×32 = 128 flip-flops at no timing cost (vpu already
    //   registers internally; done pulse is the valid indicator).
    // ------------------------------------------------------------------
    wire [31:0] y0 = res[0];
    wire [31:0] y1 = res[1];
    wire [31:0] y2 = res[2];
    wire [31:0] y3 = res[3];

    // ------------------------------------------------------------------
    // OPT-8: constant tie for unused vpu MMIO ports
    // ------------------------------------------------------------------
    localparam [31:0] VPU_WDATA_TIE = 32'd0;
    localparam [3:0]  VPU_ADDR_TIE  = 4'h0;

    // ------------------------------------------------------------------
    // 4x VPU instances — each computes one row dot product
    // use_direct=1: MMIO ports are constant-tied (cs=0 kills all paths)
    // ------------------------------------------------------------------
    genvar r;
    generate
        for (r = 0; r < 4; r = r + 1) begin : vpu_row
            vpu u_vpu (
                .clk(clk), .rst_n(rst_n),
                // OPT-3: MMIO ports constant-tied (cs=0 prunes all FF writes)
                .cs(1'b0), .we(1'b0),
                .addr(VPU_ADDR_TIE), .wdata(VPU_WDATA_TIE), .rdata(),
                .use_direct(1'b1),
                .a_direct_0(w[r][0]), .a_direct_1(w[r][1]),
                .a_direct_2(w[r][2]), .a_direct_3(w[r][3]),
                .b_direct_0(x[0]),    .b_direct_1(x[1]),
                .b_direct_2(x[2]),    .b_direct_3(x[3]),
                .start_direct(start),
                .result_direct(res[r]), .done_direct(vpu_done[r])
            );
        end
    endgenerate

    // ------------------------------------------------------------------
    // OPT-4: Write address decode with array indexing
    // Weight range: addr 0x34–0x43 → offset = addr - 0x34 (0..15)
    //   row = offset[3:2], col = offset[1:0]
    // x range: addr 0x30–0x33 → x[addr[1:0]]
    // ------------------------------------------------------------------
    wire [6:0] w_offset = addr - 7'h34;
    wire       w_sel    = (addr >= 7'h34) && (addr <= 7'h43);
    wire       x_sel    = (addr >= 7'h30) && (addr <= 7'h33);

    integer i, j;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x[0] <= 0; x[1] <= 0; x[2] <= 0; x[3] <= 0;
            for (i = 0; i < 4; i = i + 1)
                for (j = 0; j < 4; j = j + 1)
                    w[i][j] <= 32'd0;
            start <= 1'b0;
            done  <= 1'b0;
        end else begin
            start <= 1'b0;

            // OPT-5: single-cycle done pulse (defensive against sustained vpu_done)
            done  <= vpu_done[0] && !done;

            if (cs && we) begin
                if (x_sel)
                    x[addr[1:0]] <= wdata;
                else if (w_sel)
                    w[w_offset[3:2]][w_offset[1:0]] <= wdata;
                else if (addr == 7'h44)
                    start <= wdata[0];
            end
        end
    end

    // ------------------------------------------------------------------
    // MMIO read — combinational
    // ------------------------------------------------------------------
    always @(*) begin
        rdata = 32'd0;
        if (cs) begin
            casez (addr)
                7'h3?: rdata = x[addr[1:0]];           // 0x30–0x33
                7'h4?: begin                             // 0x40–0x4F
                    if (w_sel)
                        rdata = w[w_offset[3:2]][w_offset[1:0]];
                    else case (addr)
                        7'h44: rdata = {31'd0, start};
                        7'h45: rdata = {31'd0, done};
                        7'h46: rdata = y0;
                        7'h47: rdata = y1;
                        7'h48: rdata = y2;
                        7'h49: rdata = y3;
                        default: rdata = 32'd0;
                    endcase
                end
                default: rdata = 32'd0;
            endcase
        end
    end

endmodule