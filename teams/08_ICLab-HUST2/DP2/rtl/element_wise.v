// File: winograd_elementwise.v
//
// DP2 Optimization:
//   PERFORMANCE OPT: Register fp_mult output to break longest critical path.
//   fp_mult (32x32 signed multiply) is computed in stage 1 and stored in
//   fp_mult_reg. Stage 2 reads fp_mult_reg to accumulate into m_buffer.
//   This splits the long path [multiply → add → m_buffer] into two shorter
//   paths across 2 clock cycles. Cost: +1 cycle latency per element.
//
// Original bug fixes preserved (BUG FIX #6).

/* verilator lint_off DECLFILENAME */
module winograd_elementwise #(
    parameter DATA_WIDTH   = 32,
    parameter FRAC_BITS    = 16,
    parameter NUM_ELEMENTS = 16
)(
    input  wire                  clk,
    input  wire                  rstn,
    input  wire                  start,
    input  wire [DATA_WIDTH-1:0] u_in,
    input  wire [DATA_WIDTH-1:0] v_in,
    input  wire [3:0]            elem_idx,
    input  wire [7:0]            ch_idx,
    input  wire [7:0]            num_ch,
    input  wire [3:0]            read_idx,
    output reg  [DATA_WIDTH-1:0] m_out,
    output reg                   valid_out,
    output wire                  all_done
);
/* verilator lint_on DECLFILENAME */

    reg [DATA_WIDTH-1:0]   m_buffer     [0:NUM_ELEMENTS-1];
    reg [NUM_ELEMENTS-1:0] elem_complete;

    // Q16.16 fixed-point multiply
    /* verilator lint_off UNUSED */
    function [DATA_WIDTH-1:0] fp_mult;
        input signed [DATA_WIDTH-1:0] a, b;
        reg   signed [2*DATA_WIDTH-1:0] tmp;
        begin
            tmp     = $signed(a) * $signed(b);
            fp_mult = tmp[DATA_WIDTH+FRAC_BITS-1:FRAC_BITS];
        end
    endfunction
    /* verilator lint_on UNUSED */

    // PERFORMANCE OPT: pipeline registers
    // Stage 1 → Stage 2 delay registers for control signals
    reg [DATA_WIDTH-1:0] fp_mult_reg; // registered multiply result
    reg [3:0]            elem_idx_r;  // elem_idx delayed 1 cycle
    reg [7:0]            ch_idx_r;    // ch_idx delayed 1 cycle
    reg [7:0]            num_ch_r;    // num_ch delayed 1 cycle
    reg                  start_r;     // start delayed 1 cycle

    integer i;

    // Combinational read — unchanged
    always @(*) m_out = m_buffer[read_idx];

    assign all_done = &elem_complete;

    // Stage 1: compute fp_mult and register result + control signals
    // Critical path: u_in/v_in → 32×32 multiply → fp_mult_reg
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            fp_mult_reg <= {DATA_WIDTH{1'b0}};
            elem_idx_r  <= 4'd0;
            ch_idx_r    <= 8'd0;
            num_ch_r    <= 8'd0;
            start_r     <= 1'b0;
        end else begin
            start_r    <= start;
            elem_idx_r <= elem_idx;
            ch_idx_r   <= ch_idx;
            num_ch_r   <= num_ch;
            if (start)
                fp_mult_reg <= fp_mult(u_in, v_in);
        end
    end

    // Stage 2: accumulate using registered multiply result
    // Critical path: fp_mult_reg → adder → m_buffer  (short)
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            valid_out     <= 1'b0;
            elem_complete <= {NUM_ELEMENTS{1'b0}};
            for (i = 0; i < NUM_ELEMENTS; i = i + 1)
                m_buffer[i] <= {DATA_WIDTH{1'b0}};
        end else begin
            valid_out <= 1'b0;

            if (start_r) begin
                if (ch_idx_r == 8'd0) begin
                    // FIX BUG #6: reset complete flag on first channel
                    elem_complete[elem_idx_r] <= 1'b0;
                    m_buffer[elem_idx_r]      <= fp_mult_reg;
                end else begin
                    m_buffer[elem_idx_r] <= m_buffer[elem_idx_r] + fp_mult_reg;
                end

                if (ch_idx_r == num_ch_r - 8'd1) begin
                    elem_complete[elem_idx_r] <= 1'b1;
                    valid_out                 <= 1'b1;
                end
            end
        end
    end

endmodule