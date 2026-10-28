`default_nettype none
// ---------------------------------------------------------------------------
// systolic_2x2  –  2×2 Systolic Matrix Multiply + ReLU activation
//
// Computes C = ReLU(A × B) where A,B are 2×2 matrices of 32-bit integers.
//
// Matrix layout (row-major):
//   A = [a0 a1]    B = [b0 b1]    C = [c00 c01]
//       [a2 a3]        [b2 b3]        [c10 c11]
// ---------------------------------------------------------------------------
module systolic_2x2 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        cs,
    input  wire        we,
    input  wire [6:0]  addr,
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
    // Combinational partial products (first term of each dot product).
    // These feed acc_in of the pe_macc that computes the second term and
    // accumulates — all in a single registered cycle.
    //
    //   c00 = a0*b0 + a1*b2  →  pp_c00 = a0*b0 (comb), pe_macc(a1,b2,pp_c00)
    //   c01 = a0*b1 + a1*b3  →  pp_c01 = a0*b1 (comb), pe_macc(a1,b3,pp_c01)
    //   c10 = a2*b0 + a3*b2  →  pp_c10 = a2*b0 (comb), pe_macc(a3,b2,pp_c10)
    //   c11 = a2*b1 + a3*b3  →  pp_c11 = a2*b1 (comb), pe_macc(a3,b3,pp_c11)
    // ------------------------------------------------------------------
    wire [31:0] pp_c00 = a0 * b0;
    wire [31:0] pp_c01 = a0 * b1;
    wire [31:0] pp_c10 = a2 * b0;
    wire [31:0] pp_c11 = a2 * b1;

    // ------------------------------------------------------------------
    // PE instances — each computes second partial product + accumulates
    // into a single registered output.  1-cycle latency total.
    // ------------------------------------------------------------------
    wire [31:0] acc00_out, acc01_out, acc10_out, acc11_out;

    // c00 = a1*b2 + (a0*b0)
    pe_macc PE00 (
        .clk(clk), .rst_n(rst_n),
        .a_in(a1), .b_in(b2), .acc_in(pp_c00),
        .a_out(), .b_out(), .acc_out(acc00_out)
    );

    // c01 = a1*b3 + (a0*b1)
    pe_macc PE01 (
        .clk(clk), .rst_n(rst_n),
        .a_in(a1), .b_in(b3), .acc_in(pp_c01),
        .a_out(), .b_out(), .acc_out(acc01_out)
    );

    // c10 = a3*b2 + (a2*b0)
    pe_macc PE10 (
        .clk(clk), .rst_n(rst_n),
        .a_in(a3), .b_in(b2), .acc_in(pp_c10),
        .a_out(), .b_out(), .acc_out(acc10_out)
    );

    // c11 = a3*b3 + (a2*b1)
    pe_macc PE11 (
        .clk(clk), .rst_n(rst_n),
        .a_in(a3), .b_in(b3), .acc_in(pp_c11),
        .a_out(), .b_out(), .acc_out(acc11_out)
    );

    // ------------------------------------------------------------------
    // ReLU activation — combinational
    // ------------------------------------------------------------------
    wire [31:0] c00, c01, c10, c11;

    pe_activation ACT00 (.acc_in(acc00_out), .acc_out(c00));
    pe_activation ACT01 (.acc_in(acc01_out), .acc_out(c01));
    pe_activation ACT10 (.acc_in(acc10_out), .acc_out(c10));
    pe_activation ACT11 (.acc_in(acc11_out), .acc_out(c11));

    // ------------------------------------------------------------------
    // MMIO Write + control
    // ------------------------------------------------------------------
    wire new_start_write = cs && we && (addr == 7'h58);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a0 <= 0; a1 <= 0; a2 <= 0; a3 <= 0;
            b0 <= 0; b1 <= 0; b2 <= 0; b3 <= 0;
            start <= 1'b0;
            done  <= 1'b0;
        end else begin
            // Self-clearing start: captured for exactly one cycle
            start <= new_start_write ? wdata[0] : 1'b0;

            if (cs && we) begin
                case (addr)
                    7'h50: a0 <= wdata;
                    7'h51: a1 <= wdata;
                    7'h52: a2 <= wdata;
                    7'h53: a3 <= wdata;
                    7'h54: b0 <= wdata;
                    7'h55: b1 <= wdata;
                    7'h56: b2 <= wdata;
                    7'h57: b3 <= wdata;
                    default: ;
                endcase
            end

            // done: set one cycle after start (pe_macc output valid),
            //       cleared immediately when a new start write arrives.
            if (new_start_write)
                done <= 1'b0;          // clear on new operation
            else if (start)
                done <= 1'b1;          // set when pe_macc outputs land
        end
    end

    // ------------------------------------------------------------------
    // MMIO Read — combinational
    // ------------------------------------------------------------------
    always @(*) begin
        rdata = 32'd0;
        if (cs) begin
            case (addr)
                7'h50: rdata = a0;
                7'h51: rdata = a1;
                7'h52: rdata = a2;
                7'h53: rdata = a3;
                7'h54: rdata = b0;
                7'h55: rdata = b1;
                7'h56: rdata = b2;
                7'h57: rdata = b3;
                7'h58: rdata = {31'd0, start};
                7'h59: rdata = {31'd0, done};
                7'h5A: rdata = c00;
                7'h5B: rdata = c01;
                7'h5C: rdata = c10;
                7'h5D: rdata = c11;
                default: rdata = 32'd0;
            endcase
        end
    end

endmodule