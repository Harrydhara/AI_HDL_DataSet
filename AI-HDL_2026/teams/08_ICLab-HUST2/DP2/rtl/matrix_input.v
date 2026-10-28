// File: matrix_input.v  (module: winograd_input_transform)
// DP2 Optimization PW-1 v3: Gate only register array writes, not FSM
// FSM runs normally every cycle.
// d_matrix/temp_matrix/v_matrix writes guarded by per-state enable.
/* verilator lint_off DECLFILENAME */
module winograd_input_transform #(
    parameter DATA_WIDTH = 32
)(
    input  wire                     clk,
    input  wire                     rstn,
    input  wire                     start,
    input  wire [DATA_WIDTH-1:0]    d_in,
    input  wire [3:0]               d_count,
    output reg                      done,
    output reg                      v_valid,
    output reg  [DATA_WIDTH-1:0]    v_out,
    output reg  [3:0]               v_count
);
/* verilator lint_on DECLFILENAME */

    reg [DATA_WIDTH-1:0] d_matrix    [0:3][0:3];
    reg [DATA_WIDTH-1:0] temp_matrix [0:3][0:3];
    reg [DATA_WIDTH-1:0] v_matrix    [0:3][0:3];

    reg [2:0] state;
    reg [1:0] row, col;

    localparam IDLE         = 3'd0;
    localparam LOAD         = 3'd1;
    localparam COMPUTE_BTD  = 3'd2;
    localparam COMPUTE_BTDB = 3'd3;
    localparam OUTPUT       = 3'd4;

    integer i, j;

    // ── FSM: runs every cycle, unchanged from original ───────────────────
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            state   <= IDLE;
            done    <= 1'b0;
            row     <= 2'd0;
            col     <= 2'd0;
            v_count <= 4'd0;
            v_valid <= 1'b0;
            v_out   <= {DATA_WIDTH{1'b0}};
        end else begin
            case (state)
                IDLE: begin
                    done    <= 1'b0;
                    v_valid <= 1'b0;
                    v_count <= 4'd0;
                    if (start) begin
                        state <= LOAD;
                        row   <= 2'd0;
                        col   <= 2'd0;
                    end
                end
                LOAD: begin
                    if (d_count == 4'd15) begin
                        state <= COMPUTE_BTD;
                        row   <= 2'd0;
                        col   <= 2'd0;
                    end
                end
                COMPUTE_BTD: begin
                    if (col == 2'd3) begin
                        col <= 2'd0;
                        if (row == 2'd3) begin row <= 2'd0; state <= COMPUTE_BTDB;
                        end else row <= row + 2'd1;
                    end else col <= col + 2'd1;
                end
                COMPUTE_BTDB: begin
                    if (col == 2'd3) begin
                        col <= 2'd0;
                        if (row == 2'd3) begin
                            row <= 2'd0; state <= OUTPUT; v_count <= 4'd0;
                        end else row <= row + 2'd1;
                    end else col <= col + 2'd1;
                end
                OUTPUT: begin
                    v_valid <= 1'b1;
                    v_out   <= v_matrix[v_count[3:2]][v_count[1:0]];
                    if (v_count == 4'd15) begin
                        v_valid <= 1'b0; done <= 1'b1;
                        state <= IDLE; v_count <= 4'd0;
                    end else v_count <= v_count + 4'd1;
                end
                default: state <= IDLE;
            endcase
        end
    end

    // ── PW-1: d_matrix — only written in IDLE(start) and LOAD ───────────
    // Synthesis infers ICG: d_we gates this block's clock
    wire d_we = ((state == IDLE) && start) || (state == LOAD);

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (i = 0; i < 4; i = i + 1)
                for (j = 0; j < 4; j = j + 1)
                    d_matrix[i][j] <= {DATA_WIDTH{1'b0}};
        end else if (d_we) begin
            if (state == IDLE && start)
                d_matrix[0][0] <= d_in;
            else if (d_count >= 4'd1)
                d_matrix[d_count[3:2]][d_count[1:0]] <= d_in;
        end
    end

    // ── PW-1: temp_matrix — only written in COMPUTE_BTD ─────────────────
    wire tmp_we = (state == COMPUTE_BTD);

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (i = 0; i < 4; i = i + 1)
                for (j = 0; j < 4; j = j + 1)
                    temp_matrix[i][j] <= {DATA_WIDTH{1'b0}};
        end else if (tmp_we) begin
            /* verilator lint_off WIDTH */
            case (row)
                2'd0: temp_matrix[0][col] <=
                          $signed(d_matrix[0][col]) - $signed(d_matrix[2][col]);
                2'd1: temp_matrix[1][col] <=
                          $signed(d_matrix[1][col]) + $signed(d_matrix[2][col]);
                2'd2: temp_matrix[2][col] <=
                          $signed(d_matrix[2][col]) - $signed(d_matrix[1][col]);
                2'd3: temp_matrix[3][col] <=
                          $signed(d_matrix[1][col]) - $signed(d_matrix[3][col]);
                default: ;
            endcase
            /* verilator lint_on WIDTH */
        end
    end

    // ── PW-1: v_matrix — only written in COMPUTE_BTDB ───────────────────
    wire v_we = (state == COMPUTE_BTDB);

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (i = 0; i < 4; i = i + 1)
                for (j = 0; j < 4; j = j + 1)
                    v_matrix[i][j] <= {DATA_WIDTH{1'b0}};
        end else if (v_we) begin
            /* verilator lint_off WIDTH */
            case (col)
                2'd0: v_matrix[row][0] <=
                          $signed(temp_matrix[row][0]) - $signed(temp_matrix[row][2]);
                2'd1: v_matrix[row][1] <=
                          $signed(temp_matrix[row][1]) + $signed(temp_matrix[row][2]);
                2'd2: v_matrix[row][2] <=
                          $signed(temp_matrix[row][2]) - $signed(temp_matrix[row][1]);
                2'd3: v_matrix[row][3] <=
                          $signed(temp_matrix[row][1]) - $signed(temp_matrix[row][3]);
                default: ;
            endcase
            /* verilator lint_on WIDTH */
        end
    end

endmodule