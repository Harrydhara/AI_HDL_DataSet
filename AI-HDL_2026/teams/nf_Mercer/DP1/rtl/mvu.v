`default_nettype none
// ---------------------------------------------------------------------------
// mvu  –  4×4 Matrix-Vector Unit
// ---------------------------------------------------------------------------
module mvu (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        cs,
    input  wire        we,
    input  wire [5:0]  addr,
    input  wire [31:0] wdata,
    output reg  [31:0] rdata
);

    // ------------------------------------------------------------------
    // Input vector and weight matrix registers
    // ------------------------------------------------------------------
    reg [31:0] x0, x1, x2, x3;

    reg [31:0] w00, w01, w02, w03;
    reg [31:0] w10, w11, w12, w13;
    reg [31:0] w20, w21, w22, w23;
    reg [31:0] w30, w31, w32, w33;

    reg        start;
    reg        done;

    // ------------------------------------------------------------------
    // Output vector registers (latched from vpu results)
    // ------------------------------------------------------------------
    reg [31:0] y0, y1, y2, y3;

    // ------------------------------------------------------------------
    // VPU result wires
    // ------------------------------------------------------------------
    wire [31:0] res0, res1, res2, res3;
    wire        vpu_done0, vpu_done1, vpu_done2, vpu_done3;

    // ------------------------------------------------------------------
    // 4x VPU instances — each computes one row dot product
    // use_direct=1: MMIO ports tied off, direct wires used
    // ------------------------------------------------------------------

    // Row 0: y0 = w[0] · x
    vpu u_vpu0 (
        .clk(clk), .rst_n(rst_n),
        .cs(1'b0), .we(1'b0), .addr(4'h0), .wdata(32'd0), .rdata(),
        .use_direct(1'b1),
        .a_direct_0(w00), .a_direct_1(w01),
        .a_direct_2(w02), .a_direct_3(w03),
        .b_direct_0(x0),  .b_direct_1(x1),
        .b_direct_2(x2),  .b_direct_3(x3),
        .start_direct(start),
        .result_direct(res0), .done_direct(vpu_done0)
    );

    // Row 1: y1 = w[1] · x
    vpu u_vpu1 (
        .clk(clk), .rst_n(rst_n),
        .cs(1'b0), .we(1'b0), .addr(4'h0), .wdata(32'd0), .rdata(),
        .use_direct(1'b1),
        .a_direct_0(w10), .a_direct_1(w11),
        .a_direct_2(w12), .a_direct_3(w13),
        .b_direct_0(x0),  .b_direct_1(x1),
        .b_direct_2(x2),  .b_direct_3(x3),
        .start_direct(start),
        .result_direct(res1), .done_direct(vpu_done1)
    );

    // Row 2: y2 = w[2] · x
    vpu u_vpu2 (
        .clk(clk), .rst_n(rst_n),
        .cs(1'b0), .we(1'b0), .addr(4'h0), .wdata(32'd0), .rdata(),
        .use_direct(1'b1),
        .a_direct_0(w20), .a_direct_1(w21),
        .a_direct_2(w22), .a_direct_3(w23),
        .b_direct_0(x0),  .b_direct_1(x1),
        .b_direct_2(x2),  .b_direct_3(x3),
        .start_direct(start),
        .result_direct(res2), .done_direct(vpu_done2)
    );

    // Row 3: y3 = w[3] · x
    vpu u_vpu3 (
        .clk(clk), .rst_n(rst_n),
        .cs(1'b0), .we(1'b0), .addr(4'h0), .wdata(32'd0), .rdata(),
        .use_direct(1'b1),
        .a_direct_0(w30), .a_direct_1(w31),
        .a_direct_2(w32), .a_direct_3(w33),
        .b_direct_0(x0),  .b_direct_1(x1),
        .b_direct_2(x2),  .b_direct_3(x3),
        .start_direct(start),
        .result_direct(res3), .done_direct(vpu_done3)
    );

    // ------------------------------------------------------------------
    // Write + control logic
    // done = vpu_done0 (all 4 VPUs finish simultaneously since same start)
    // y[0..3] latched when vpu_done asserts
    // ------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x0 <= 0; x1 <= 0; x2 <= 0; x3 <= 0;
            w00<=0; w01<=0; w02<=0; w03<=0;
            w10<=0; w11<=0; w12<=0; w13<=0;
            w20<=0; w21<=0; w22<=0; w23<=0;
            w30<=0; w31<=0; w32<=0; w33<=0;
            start <= 1'b0;
            done  <= 1'b0;
            y0 <= 0; y1 <= 0; y2 <= 0; y3 <= 0;
        end else begin
            start <= 1'b0;          // self-clearing
            done  <= vpu_done0;     // all VPUs finish together

            if (cs && we) begin
                case (addr)
                    // Input vector
                    6'h30: x0 <= wdata;
                    6'h31: x1 <= wdata;
                    6'h32: x2 <= wdata;
                    6'h33: x3 <= wdata;
                    // Row 0
                    6'h34: w00 <= wdata; 6'h35: w01 <= wdata;
                    6'h36: w02 <= wdata; 6'h37: w03 <= wdata;
                    // Row 1
                    6'h38: w10 <= wdata; 6'h39: w11 <= wdata;
                    6'h3A: w12 <= wdata; 6'h3B: w13 <= wdata;
                    // Row 2
                    6'h3C: w20 <= wdata; 6'h3D: w21 <= wdata;
                    6'h3E: w22 <= wdata; 6'h3F: w23 <= wdata;
                    // Row 3
                    6'h40: w30 <= wdata; 6'h41: w31 <= wdata;
                    6'h42: w32 <= wdata; 6'h43: w33 <= wdata;
                    // Control
                    6'h44: start <= wdata[0];
                    default: ;
                endcase
            end

            // Latch VPU results when they become valid
            if (vpu_done0) begin
                y0 <= res0;
                y1 <= res1;
                y2 <= res2;
                y3 <= res3;
            end
        end
    end

    // ------------------------------------------------------------------
    // MMIO read — combinational
    // ------------------------------------------------------------------
    always @(*) begin
        rdata = 32'd0;
        if (cs) begin
            case (addr)
                6'h30: rdata = x0;
                6'h31: rdata = x1;
                6'h32: rdata = x2;
                6'h33: rdata = x3;
                6'h34: rdata = w00; 6'h35: rdata = w01;
                6'h36: rdata = w02; 6'h37: rdata = w03;
                6'h38: rdata = w10; 6'h39: rdata = w11;
                6'h3A: rdata = w12; 6'h3B: rdata = w13;
                6'h3C: rdata = w20; 6'h3D: rdata = w21;
                6'h3E: rdata = w22; 6'h3F: rdata = w23;
                6'h40: rdata = w30; 6'h41: rdata = w31;
                6'h42: rdata = w32; 6'h43: rdata = w33;
                6'h44: rdata = {31'd0, start};
                6'h45: rdata = {31'd0, done};
                6'h46: rdata = y0;
                6'h47: rdata = y1;
                6'h48: rdata = y2;
                6'h49: rdata = y3;
                default: rdata = 32'd0;
            endcase
        end
    end

endmodule
