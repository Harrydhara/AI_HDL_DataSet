`default_nettype none
// ---------------------------------------------------------------------------
// vpu  –  4-Element Vector Dot-Product Unit  (optimized)
// ---------------------------------------------------------------------------
module vpu (
    input  wire        clk,
    input  wire        rst_n,

    // MMIO interface
    input  wire        cs,
    input  wire        we,
    input  wire [3:0]  addr,
    input  wire [31:0] wdata,
    output reg  [31:0] rdata,

    // Direct interface for MVU instantiation
    input  wire        use_direct,
    input  wire [31:0] a_direct_0, a_direct_1, a_direct_2, a_direct_3,
    input  wire [31:0] b_direct_0, b_direct_1, b_direct_2, b_direct_3,
    input  wire        start_direct,
    output wire [31:0] result_direct,
    output wire        done_direct
);

    // ------------------------------------------------------------------
    // MMIO input registers (only written in MMIO mode)
    // ------------------------------------------------------------------
    reg [31:0] a0, a1, a2, a3;
    reg [31:0] b0, b1, b2, b3;
    reg        start;
    reg        start_d1;
    reg        done;
    reg [31:0] result;

    // ------------------------------------------------------------------
    // OPT-3: Input mux — one LUT layer, not a priority tree
    // ------------------------------------------------------------------
    wire [31:0] pa0 = use_direct ? a_direct_0 : a0;
    wire [31:0] pa1 = use_direct ? a_direct_1 : a1;
    wire [31:0] pa2 = use_direct ? a_direct_2 : a2;
    wire [31:0] pa3 = use_direct ? a_direct_3 : a3;
    wire [31:0] pb0 = use_direct ? b_direct_0 : b0;
    wire [31:0] pb1 = use_direct ? b_direct_1 : b1;
    wire [31:0] pb2 = use_direct ? b_direct_2 : b2;
    wire [31:0] pb3 = use_direct ? b_direct_3 : b3;
    wire        go   = use_direct ? start_direct : start;

    // ------------------------------------------------------------------
    // OPT-1: pe_macc instantiation without dummy a_out/b_out wires
    // ------------------------------------------------------------------
    wire [31:0] prod0, prod1, prod2, prod3;

    pe_macc u_pe0 (.clk(clk), .rst_n(rst_n),
        .a_in(pa0), .b_in(pb0), .acc_in(32'd0),
        .a_out(), .b_out(), .acc_out(prod0));

    pe_macc u_pe1 (.clk(clk), .rst_n(rst_n),
        .a_in(pa1), .b_in(pb1), .acc_in(32'd0),
        .a_out(), .b_out(), .acc_out(prod1));

    pe_macc u_pe2 (.clk(clk), .rst_n(rst_n),
        .a_in(pa2), .b_in(pb2), .acc_in(32'd0),
        .a_out(), .b_out(), .acc_out(prod2));

    pe_macc u_pe3 (.clk(clk), .rst_n(rst_n),
        .a_in(pa3), .b_in(pb3), .acc_in(32'd0),
        .a_out(), .b_out(), .acc_out(prod3));

    // ------------------------------------------------------------------
    // OPT-4: Balanced 3-adder tree (depth 2) instead of linear chain
    //   Linear:  ((p0+p1)+p2)+p3  → depth 3 carry chains
    //   Balanced: (p0+p1)+(p2+p3) → depth 2 carry chains
    // ------------------------------------------------------------------
    wire [31:0] sum01 = prod0 + prod1;
    wire [31:0] sum23 = prod2 + prod3;
    wire [31:0] sum_comb = sum01 + sum23;

    // ------------------------------------------------------------------
    // Control sequencer
    // OPT-5: 'done' = start_d1 from previous cycle (no extra FF)
    // OPT-7: 'clear' register removed; handled as inline priority
    // ------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a0 <= 0; a1 <= 0; a2 <= 0; a3 <= 0;
            b0 <= 0; b1 <= 0; b2 <= 0; b3 <= 0;
            start    <= 1'b0;
            start_d1 <= 1'b0;
            done     <= 1'b0;
            result   <= 32'd0;
        end else begin
            start    <= 1'b0;       // self-clearing
            start_d1 <= go;
            done     <= start_d1;

            // Latch sum exactly when products are valid
            if (start_d1)
                result <= sum_comb;

            // MMIO writes (ignored in direct mode; cs==0 from instantiator)
            if (cs && we) begin
                case (addr)
                    4'h0: a0 <= wdata;
                    4'h1: a1 <= wdata;
                    4'h2: a2 <= wdata;
                    4'h3: a3 <= wdata;
                    4'h4: b0 <= wdata;
                    4'h5: b1 <= wdata;
                    4'h6: b2 <= wdata;
                    4'h7: b3 <= wdata;
                    // OPT-7: inline clear; bit1=clear takes priority over latch
                    4'h9: begin
                        start  <= wdata[0];
                        if (wdata[1]) result <= 32'd0;
                    end
                    default: ;
                endcase
            end
        end
    end

    // ------------------------------------------------------------------
    // Direct output ports
    // ------------------------------------------------------------------
    assign result_direct = result;
    assign done_direct   = done;

    // OPT-6: MMIO read — gate on cs only (use_direct→cs==0 from caller)
    always @(*) begin
        rdata = 32'd0;
        if (cs) begin
            case (addr)
                4'h0: rdata = a0;
                4'h1: rdata = a1;
                4'h2: rdata = a2;
                4'h3: rdata = a3;
                4'h4: rdata = b0;
                4'h5: rdata = b1;
                4'h6: rdata = b2;
                4'h7: rdata = b3;
                4'h8: rdata = result;
                4'h9: rdata = {31'd0, start};
                4'hA: rdata = {31'd0, done};
                default: rdata = 32'd0;
            endcase
        end
    end

endmodule
