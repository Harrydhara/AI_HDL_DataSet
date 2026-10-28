`default_nettype none
// ---------------------------------------------------------------------------
// systolic_2x2  –  2×2 Systolic Matrix Multiply + ReLU activation
// Matrix layout (row-major):
//   A = [a0 a1]    B = [b0 b1]    C = [c00 c01]
//       [a2 a3]        [b2 b3]        [c10 c11]
//
// ---------------------------------------------------------------------------
module systolic_2x2 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        cs,
    input  wire        we,
    input  wire [5:0]  addr,
    input  wire [31:0] wdata,
    output reg  [31:0] rdata
);

    // ------------------------------------------------------------------
    // Input registers
    // ------------------------------------------------------------------
    reg [31:0] a0, a1, a2, a3;
    reg [31:0] b0, b1, b2, b3;
    reg        start;
    reg        done;

    // ------------------------------------------------------------------
    // PE interconnect wires (a_out/b_out are now just wires in pe_macc)
    // ------------------------------------------------------------------
    // Row 0
    wire [31:0] acc00_out, acc01_out;
    // Row 1
    wire [31:0] acc10_out, acc11_out;

    // ------------------------------------------------------------------
    // PE Grid (2×2)
    //
    //        col0     col1
    // row0:  PE00 --> PE01
    //        |         |
    //        v         v
    // row1:  PE10 --> PE11
    //
    // A flows left→right; B flows top→bottom.
    // acc_in is 0 (single outer-product step, no accumulation chain).
    // ------------------------------------------------------------------

    // Intermediate wires for A pass-through (row 0 → row 1 not needed here;
    // each PE row takes its own A row directly)
    wire [31:0] a00_pass;   // a0 passed through PE00 to PE01
    wire [31:0] a10_pass;   // a2 passed through PE10 to PE11

    // B column wires (top row PEs pass B downward)
    wire [31:0] b00_pass;   // b0 passed through PE00 to PE10
    wire [31:0] b01_pass;   // b1 passed through PE01 to PE11

    // Row 0, Col 0
    pe_macc PE00 (
        .clk(clk), .rst_n(rst_n),
        .a_in(a0),       .b_in(b0),   .acc_in(32'd0),
        .a_out(a00_pass), .b_out(b00_pass), .acc_out(acc00_out)
    );

    // Row 0, Col 1
    pe_macc PE01 (
        .clk(clk), .rst_n(rst_n),
        .a_in(a00_pass), .b_in(b1),   .acc_in(32'd0),
        .a_out(/* unused */), .b_out(b01_pass), .acc_out(acc01_out)
    );

    // Row 1, Col 0  — NOTE: b_in = b2 (column 0, row 1), not b0
    pe_macc PE10 (
        .clk(clk), .rst_n(rst_n),
        .a_in(a2),       .b_in(b2),   .acc_in(32'd0),
        .a_out(a10_pass), .b_out(/* unused */), .acc_out(acc10_out)
    );

    // Row 1, Col 1  — NOTE: b_in = b3 (column 1, row 1), not b1
    pe_macc PE11 (
        .clk(clk), .rst_n(rst_n),
        .a_in(a10_pass), .b_in(b3),   .acc_in(32'd0),
        .a_out(/* unused */), .b_out(/* unused */), .acc_out(acc11_out)
    );

    // ------------------------------------------------------------------
    // Activation (ReLU) – combinational, zero flip-flops
    // ------------------------------------------------------------------
    wire [31:0] c00, c01, c10, c11;

    pe_activation ACT00 (.acc_in(acc00_out), .acc_out(c00));
    pe_activation ACT01 (.acc_in(acc01_out), .acc_out(c01));
    pe_activation ACT10 (.acc_in(acc10_out), .acc_out(c10));
    pe_activation ACT11 (.acc_in(acc11_out), .acc_out(c11));

    // ------------------------------------------------------------------
    // MMIO Write + control
    // ------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a0 <= 0; a1 <= 0; a2 <= 0; a3 <= 0;
            b0 <= 0; b1 <= 0; b2 <= 0; b3 <= 0;
            start <= 1'b0;
            done  <= 1'b0;
        end else begin
            start <= 1'b0;          // self-clearing

            if (cs && we) begin
                case (addr)
                    6'h50: a0    <= wdata;
                    6'h51: a1    <= wdata;
                    6'h52: a2    <= wdata;
                    6'h53: a3    <= wdata;
                    6'h54: b0    <= wdata;
                    6'h55: b1    <= wdata;
                    6'h56: b2    <= wdata;
                    6'h57: b3    <= wdata;
                    6'h58: start <= wdata[0];
                    default: ;
                endcase
            end

            // done is 1 exactly one cycle after start is asserted
            // (matches pe_macc pipeline latency of 1 cycle)
            done <= start;
        end
    end

    // ------------------------------------------------------------------
    // MMIO Read – purely combinational
    // ------------------------------------------------------------------
    always @(*) begin
        rdata = 32'd0;
        if (cs) begin
            case (addr)
                6'h50: rdata = a0;
                6'h51: rdata = a1;
                6'h52: rdata = a2;
                6'h53: rdata = a3;
                6'h54: rdata = b0;
                6'h55: rdata = b1;
                6'h56: rdata = b2;
                6'h57: rdata = b3;
                6'h58: rdata = {31'd0, start};
                6'h59: rdata = {31'd0, done};
                6'h5A: rdata = c00;
                6'h5B: rdata = c01;
                6'h5C: rdata = c10;
                6'h5D: rdata = c11;
                default: rdata = 32'd0;
            endcase
        end
    end

endmodule