`default_nettype none

module systolic_2x2 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        cs,
    input  wire        we,
    input  wire [5:0]  addr,
    input  wire [31:0] wdata,
    output reg  [31:0] rdata
);

    // Input Registers (A and B matrices)
    // A = [a0 a1; a2 a3]
    // B = [b0 b1; b2 b3]
    reg [31:0] a0, a1, a2, a3;
    reg [31:0] b0, b1, b2, b3;

    reg        start;
    reg        done;

    // PE Outputs
    wire [31:0] a00_out, b00_out, acc00_out;
    wire [31:0] a01_out, b01_out, acc01_out;
    wire [31:0] a10_out, b10_out, acc10_out;
    wire [31:0] a11_out, b11_out, acc11_out;

    // Accumulators start at zero (single‑cycle outer product)
    wire [31:0] acc00_in = 32'd0;
    wire [31:0] acc01_in = 32'd0;
    wire [31:0] acc10_in = 32'd0;
    wire [31:0] acc11_in = 32'd0;

    // PE Grid (2×2)
    // Row 0
    pe_macc PE00 (
        .clk(clk), .rst_n(rst_n),
        .a_in(a0), .b_in(b0), .acc_in(acc00_in),
        .a_out(a00_out), .b_out(b00_out), .acc_out(acc00_out)
    );

    pe_macc PE01 (
        .clk(clk), .rst_n(rst_n),
        .a_in(a00_out), .b_in(b1), .acc_in(acc01_in),
        .a_out(a01_out), .b_out(b01_out), .acc_out(acc01_out)
    );

    // Row 1
    pe_macc PE10 (
        .clk(clk), .rst_n(rst_n),
        .a_in(a2), .b_in(b0), .acc_in(acc10_in),
        .a_out(a10_out), .b_out(b10_out), .acc_out(acc10_out)
    );

    pe_macc PE11 (
        .clk(clk), .rst_n(rst_n),
        .a_in(a10_out), .b_in(b1), .acc_in(acc11_in),
        .a_out(a11_out), .b_out(b11_out), .acc_out(acc11_out)
    );

    // Activation (ReLU)
    wire [31:0] c00, c01, c10, c11;

    pe_activation ACT00 (.clk(clk), .rst_n(rst_n), .acc_in(acc00_out), .acc_out(c00));
    pe_activation ACT01 (.clk(clk), .rst_n(rst_n), .acc_in(acc01_out), .acc_out(c01));
    pe_activation ACT10 (.clk(clk), .rst_n(rst_n), .acc_in(acc10_out), .acc_out(c10));
    pe_activation ACT11 (.clk(clk), .rst_n(rst_n), .acc_in(acc11_out), .acc_out(c11));

    // MMIO Write Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a0 <= 0; a1 <= 0; a2 <= 0; a3 <= 0;
            b0 <= 0; b1 <= 0; b2 <= 0; b3 <= 0;
            start <= 1'b0;
            done  <= 1'b0;
        end else begin
            start <= 1'b0;
            done  <= 1'b0;

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
                endcase
            end

            if (start)
                done <= 1'b1;
        end
    end

    // MMIO Read Logic
    always @(*) begin
        rdata = 32'd0;

        if (cs) begin
            case (addr)
                // Inputs
                6'h50: rdata = a0;
                6'h51: rdata = a1;
                6'h52: rdata = a2;
                6'h53: rdata = a3;
                6'h54: rdata = b0;
                6'h55: rdata = b1;
                6'h56: rdata = b2;
                6'h57: rdata = b3;

                // Control
                6'h58: rdata = {31'd0, start};
                6'h59: rdata = {31'd0, done};

                // Outputs (activated)
                // You can remap these if desired
                6'h5A: rdata = c00;
                6'h5B: rdata = c01;
                6'h5C: rdata = c10;
                6'h5D: rdata = c11;

                default: rdata = 32'd0;
            endcase
        end
    end

endmodule
