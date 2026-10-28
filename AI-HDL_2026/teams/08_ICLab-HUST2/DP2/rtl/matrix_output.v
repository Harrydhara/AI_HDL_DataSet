// File: matrix_output.v  (module: winograd_output_transform)
// DP2 Optimization PW-1 v3: Separate FSM block + gated register blocks
// FSM runs every cycle (unchanged). Register arrays gated by state.

// A^T = | 1  1  1  0 |
//       | 0  1 -1 -1 |

/* verilator lint_off DECLFILENAME */
module winograd_output_transform #(
    parameter DATA_WIDTH = 32
)(
    input  wire                  clk,
    input  wire                  rstn,
    input  wire                  start,
    input  wire [DATA_WIDTH-1:0] m_in,
    input  wire [3:0]            m_count,
    output reg                   done,
    output reg                   y_valid,
    output reg  [DATA_WIDTH-1:0] y_out,
    output reg  [1:0]            y_count
);
/* verilator lint_on DECLFILENAME */

    reg signed [DATA_WIDTH-1:0] m_matrix    [0:3][0:3];
    reg signed [DATA_WIDTH-1:0] temp_matrix [0:1][0:3];
    reg signed [DATA_WIDTH-1:0] y_matrix    [0:1][0:1];

    reg [2:0] state;
    reg [1:0] row, col;

    localparam IDLE         = 3'd0;
    localparam LOAD         = 3'd1;
    localparam COMPUTE_ATM  = 3'd2;
    localparam COMPUTE_ATMA = 3'd3;
    localparam PRE_OUTPUT   = 3'd4;
    localparam OUTPUT       = 3'd5;

    integer r, c;

    // ── FSM: runs every cycle, unchanged from original ───────────────────
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            state   <= IDLE;
            done    <= 1'b0;
            y_valid <= 1'b0;
            row     <= 2'd0;
            col     <= 2'd0;
            y_count <= 2'd0;
            y_out   <= {DATA_WIDTH{1'b0}};
        end else begin
            done    <= 1'b0;
            y_valid <= 1'b0;
            case (state)
                IDLE: begin
                    y_count <= 2'd0;
                    if (start) begin state <= LOAD; row <= 2'd0; col <= 2'd0; end
                end
                LOAD: begin
                    if (m_count == 4'd15) begin
                        state <= COMPUTE_ATM; row <= 2'd0; col <= 2'd0;
                    end
                end
                COMPUTE_ATM: begin
                    if (col == 2'd3) begin
                        col <= 2'd0;
                        if (row == 2'd1) begin row <= 2'd0; state <= COMPUTE_ATMA;
                        end else row <= row + 2'd1;
                    end else col <= col + 2'd1;
                end
                COMPUTE_ATMA: begin
                    if (col == 2'd1) begin
                        col <= 2'd0;
                        if (row == 2'd1) begin
                            state <= PRE_OUTPUT; row <= 2'd0; col <= 2'd0; y_count <= 2'd0;
                        end else row <= row + 2'd1;
                    end else col <= col + 2'd1;
                end
                PRE_OUTPUT: begin state <= OUTPUT; end
                OUTPUT: begin
                    /* verilator lint_off WIDTH */
                    y_out   <= y_matrix[row][col];
                    /* verilator lint_on WIDTH */
                    y_valid <= 1'b1;
                    if (y_count == 2'd3) begin
                        done <= 1'b1; y_valid <= 1'b0; state <= IDLE;
                    end else begin
                        y_count <= y_count + 2'd1;
                        if (col == 2'd1) begin col <= 2'd0; row <= row + 2'd1;
                        end else col <= col + 2'd1;
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end

    // ── PW-1: m_matrix — only written in LOAD ────────────────────────────
    wire m_we = (state == LOAD);

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (r = 0; r < 4; r = r + 1)
                for (c = 0; c < 4; c = c + 1)
                    m_matrix[r][c] <= {DATA_WIDTH{1'b0}};
        end else if (m_we)
            m_matrix[m_count[3:2]][m_count[1:0]] <= m_in;
    end

    // ── PW-1: temp_matrix — only written in COMPUTE_ATM ──────────────────
    wire tmp_we = (state == COMPUTE_ATM);

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (r = 0; r < 2; r = r + 1)
                for (c = 0; c < 4; c = c + 1)
                    temp_matrix[r][c] <= {DATA_WIDTH{1'b0}};
        end else if (tmp_we) begin
            /* verilator lint_off WIDTH */
            case (row)
                2'd0: temp_matrix[0][col] <=
                          $signed(m_matrix[0][col])
                        + $signed(m_matrix[1][col])
                        + $signed(m_matrix[2][col]);
                2'd1: temp_matrix[1][col] <=
                          $signed(m_matrix[1][col])
                        - $signed(m_matrix[2][col])
                        - $signed(m_matrix[3][col]);
                default: ;
            endcase
            /* verilator lint_on WIDTH */
        end
    end

    // ── PW-1: y_matrix — only written in COMPUTE_ATMA ────────────────────
    wire y_we = (state == COMPUTE_ATMA);

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (r = 0; r < 2; r = r + 1)
                for (c = 0; c < 2; c = c + 1)
                    y_matrix[r][c] <= {DATA_WIDTH{1'b0}};
        end else if (y_we) begin
            /* verilator lint_off WIDTH */
            case (col)
                2'd0: y_matrix[row][0] <=
                          $signed(temp_matrix[row][0])
                        + $signed(temp_matrix[row][1])
                        + $signed(temp_matrix[row][2]);
                2'd1: y_matrix[row][1] <=
                          $signed(temp_matrix[row][1])
                        - $signed(temp_matrix[row][2])
                        - $signed(temp_matrix[row][3]);
                default: ;
            endcase
            /* verilator lint_on WIDTH */
        end
    end

endmodule