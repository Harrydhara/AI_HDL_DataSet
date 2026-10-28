/* verilator lint_off DECLFILENAME */
// =============================================================================
// File: interface.v  (module: winograd_peripheral)
//
// DP2 Optimizations (preserved from challenge-2):
//   - PW-1 v3: clock gating on matrix_input/matrix_output register arrays
//   - PIPELINE_WAIT stage in matrix_filter.v
//   - 2-stage fp_mult_reg pipeline in element_wise.v
//
// DP3 Security Hardening (added in challenge-3):
//   CM-1: Write-While-Busy Protection
//         - input_buffer and filter_buffer are locked when STATUS_BUSY=1
//         - CTRL[START] bit is blocked when STATUS_BUSY=1
//         - Any blocked write attempt sets STATUS[SEC_VIO_BIT] (bit 2)
//         - sec_violation_flag auto-clears when CPU reads STATUS register
//   CM-2: Debug Sentinel Removal
//         - Default read path now returns 32'h0 instead of 32'hDEADBEEF
//         - Prevents information disclosure about register map boundaries
// =============================================================================
module winograd_peripheral #(
    parameter DATA_WIDTH = 32,
    parameter FRAC_BITS  = 16
)(
    input  wire                  clk,
    input  wire                  rstn,
    input  wire [5:0]            address,
    input  wire [1:0]            data_write_n,
    input  wire [1:0]            data_read_n,
    input  wire [DATA_WIDTH-1:0] data_in,
    output reg  [DATA_WIDTH-1:0] data_out,
    output reg                   data_ready,
    output reg                   winograd_irq
);
/* verilator lint_on DECLFILENAME */

    wire is_ctrl        = (address == 6'h00);
    wire is_status      = (address == 6'h04);
    wire is_config      = (address == 6'h08);
    wire is_input_idx   = (address == 6'h0C);
    wire is_input_data  = (address == 6'h10);
    wire is_filter_idx  = (address == 6'h14);
    wire is_filter_data = (address == 6'h18);

    wire write_req = (data_write_n != 2'b11);
    wire read_req  = (data_read_n  != 2'b11);

    reg [DATA_WIDTH-1:0] ctrl_reg;
    reg [DATA_WIDTH-1:0] status_reg;
    reg [DATA_WIDTH-1:0] config_reg;

    localparam CTRL_START_BIT     = 0;
    localparam CTRL_ACCUM_EN_BIT  = 3;
    localparam CTRL_CLEAR_ACC_BIT = 4;
    localparam CTRL_IRQ_EN_BIT    = 5;
    localparam STATUS_BUSY_BIT    = 0;
    localparam STATUS_DONE_BIT    = 1;
    // DP3 CM-1: Security violation flag bit in STATUS register
    localparam STATUS_SEC_VIO_BIT = 2;

    // DP3 CM-1: busy_guard — high when accelerator is actively computing
    // Blocks writes to input_buffer, filter_buffer, and CTRL[START]
    wire busy_guard = status_reg[STATUS_BUSY_BIT];

    // DP3 CM-1: security violation flag register
    // Set when a write is attempted while busy_guard=1
    // Cleared when CPU reads STATUS register (W1C via read)
    reg sec_violation_flag;

    reg [3:0] input_wr_idx;
    reg [3:0] filter_wr_idx;

    reg [DATA_WIDTH-1:0] input_buffer_0,  input_buffer_1,  input_buffer_2,  input_buffer_3;
    reg [DATA_WIDTH-1:0] input_buffer_4,  input_buffer_5,  input_buffer_6,  input_buffer_7;
    reg [DATA_WIDTH-1:0] input_buffer_8,  input_buffer_9,  input_buffer_10, input_buffer_11;
    reg [DATA_WIDTH-1:0] input_buffer_12, input_buffer_13, input_buffer_14, input_buffer_15;
    reg [DATA_WIDTH-1:0] filter_buffer_0, filter_buffer_1, filter_buffer_2;
    reg [DATA_WIDTH-1:0] filter_buffer_3, filter_buffer_4, filter_buffer_5;
    reg [DATA_WIDTH-1:0] filter_buffer_6, filter_buffer_7, filter_buffer_8;
    reg [DATA_WIDTH-1:0] output_buffer_0, output_buffer_1, output_buffer_2, output_buffer_3;
    reg [DATA_WIDTH-1:0] acc_buffer_0, acc_buffer_1, acc_buffer_2, acc_buffer_3;

    wire wino_start        = (feed_state == FEED_START);
    wire wino_filter_valid = (feed_state == FEED_FILTER);
    wire wino_data_valid   = (feed_state == FEED_INPUT);
    wire wino_done;
    /* verilator lint_off UNUSED */
    wire wino_ready;
    wire [3:0] wino_state;
    /* verilator lint_on UNUSED */
    wire wino_data_out_valid;
    wire [DATA_WIDTH-1:0] wino_data_out;

    reg [DATA_WIDTH-1:0] wino_filter_in;
    reg [DATA_WIDTH-1:0] wino_data_in;

    reg [2:0] feed_state;
    reg [3:0] feed_counter;
    reg       feed_active;
    reg       wino_done_latched;

    localparam FEED_IDLE    = 3'd0;
    localparam FEED_FILTER  = 3'd1;
    localparam FEED_INPUT   = 3'd2;
    localparam FEED_START   = 3'd3;
    localparam FEED_WAIT    = 3'd4;
    localparam FEED_COLLECT = 3'd5;



    winograd_conv_top #(.DATA_WIDTH(DATA_WIDTH), .FRAC_BITS(FRAC_BITS)) winograd_core (
        .clk(clk), .rstn(rstn),
        .start(wino_start), .ready(wino_ready), .done(wino_done),
        .num_channels(8'd1),
        .data_in(wino_data_in), .data_valid(wino_data_valid),
        .filter_in(wino_filter_in), .filter_valid(wino_filter_valid),
        .data_out(wino_data_out), .data_out_valid(wino_data_out_valid),
        .current_state(wino_state)
    );

    always @(*) begin
        case (feed_counter[3:0])
            4'd0: wino_filter_in = filter_buffer_0; 4'd1: wino_filter_in = filter_buffer_1;
            4'd2: wino_filter_in = filter_buffer_2; 4'd3: wino_filter_in = filter_buffer_3;
            4'd4: wino_filter_in = filter_buffer_4; 4'd5: wino_filter_in = filter_buffer_5;
            4'd6: wino_filter_in = filter_buffer_6; 4'd7: wino_filter_in = filter_buffer_7;
            4'd8: wino_filter_in = filter_buffer_8;
            default: wino_filter_in = {DATA_WIDTH{1'b0}};
        endcase
    end
    always @(*) begin
        case (feed_counter[3:0])
            4'd0:  wino_data_in = input_buffer_0;  4'd1:  wino_data_in = input_buffer_1;
            4'd2:  wino_data_in = input_buffer_2;  4'd3:  wino_data_in = input_buffer_3;
            4'd4:  wino_data_in = input_buffer_4;  4'd5:  wino_data_in = input_buffer_5;
            4'd6:  wino_data_in = input_buffer_6;  4'd7:  wino_data_in = input_buffer_7;
            4'd8:  wino_data_in = input_buffer_8;  4'd9:  wino_data_in = input_buffer_9;
            4'd10: wino_data_in = input_buffer_10; 4'd11: wino_data_in = input_buffer_11;
            4'd12: wino_data_in = input_buffer_12; 4'd13: wino_data_in = input_buffer_13;
            4'd14: wino_data_in = input_buffer_14; 4'd15: wino_data_in = input_buffer_15;
            default: wino_data_in = {DATA_WIDTH{1'b0}};
        endcase
    end

    // =========================================================================
    // Write Path — with DP3 CM-1 busy_guard protection
    // Changes vs DP2:
    //   (a) CTRL write: when busy_guard=1, force CTRL[START]=0 (mask out the
    //       START bit) so software cannot re-trigger computation mid-run.
    //       All other CTRL bits (ACCUM_EN, CLEAR_ACC, IRQ_EN) still writable.
    //   (b) INPUT_DATA write: fully blocked when busy_guard=1. The buffer
    //       content is preserved and the attempted write is silently dropped.
    //       (sec_violation_flag is set in a separate always block below.)
    //   (c) FILTER_DATA write: same as INPUT_DATA.
    //   (d) INPUT_IDX, FILTER_IDX, CONFIG: always allowed — these do not
    //       affect the in-progress computation pipeline.
    // =========================================================================
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            ctrl_reg <= 32'h0; config_reg <= 32'h0;
            input_wr_idx <= 4'd0; filter_wr_idx <= 4'd0;
            input_buffer_0  <= 32'h0; input_buffer_1  <= 32'h0; input_buffer_2  <= 32'h0; input_buffer_3  <= 32'h0;
            input_buffer_4  <= 32'h0; input_buffer_5  <= 32'h0; input_buffer_6  <= 32'h0; input_buffer_7  <= 32'h0;
            input_buffer_8  <= 32'h0; input_buffer_9  <= 32'h0; input_buffer_10 <= 32'h0; input_buffer_11 <= 32'h0;
            input_buffer_12 <= 32'h0; input_buffer_13 <= 32'h0; input_buffer_14 <= 32'h0; input_buffer_15 <= 32'h0;
            filter_buffer_0 <= 32'h0; filter_buffer_1 <= 32'h0; filter_buffer_2 <= 32'h0;
            filter_buffer_3 <= 32'h0; filter_buffer_4 <= 32'h0; filter_buffer_5 <= 32'h0;
            filter_buffer_6 <= 32'h0; filter_buffer_7 <= 32'h0; filter_buffer_8 <= 32'h0;
        end else begin
            if (ctrl_reg[CTRL_START_BIT] && feed_active) ctrl_reg[CTRL_START_BIT] <= 1'b0;
            if (ctrl_reg[CTRL_CLEAR_ACC_BIT]) ctrl_reg[CTRL_CLEAR_ACC_BIT] <= 1'b0;
            if (write_req) begin
                if (is_ctrl) begin
                    // DP3 CM-1: When busy, mask START bit to prevent re-trigger.
                    // All other CTRL bits (ACCUM_EN/CLEAR_ACC/IRQ_EN) still writable.
                    // If attacker attempts START=1 while BUSY, sec_violation_flag
                    // is set in the dedicated always block below.
                    ctrl_reg <= busy_guard
                        ? {data_in[DATA_WIDTH-1:1], 1'b0}   // mask START bit
                        : data_in;                           // normal write
                end
                else if (is_config) config_reg <= data_in;
                else if (is_input_idx) input_wr_idx <= data_in[3:0];
                else if (is_input_data) begin
                    // DP3 CM-1: Block INPUT_DATA writes when BUSY.
                    // Buffer content is fully preserved during computation.
                    if (!busy_guard) begin
                        case (input_wr_idx)
                            4'd0:  input_buffer_0  <= data_in; 4'd1:  input_buffer_1  <= data_in;
                            4'd2:  input_buffer_2  <= data_in; 4'd3:  input_buffer_3  <= data_in;
                            4'd4:  input_buffer_4  <= data_in; 4'd5:  input_buffer_5  <= data_in;
                            4'd6:  input_buffer_6  <= data_in; 4'd7:  input_buffer_7  <= data_in;
                            4'd8:  input_buffer_8  <= data_in; 4'd9:  input_buffer_9  <= data_in;
                            4'd10: input_buffer_10 <= data_in; 4'd11: input_buffer_11 <= data_in;
                            4'd12: input_buffer_12 <= data_in; 4'd13: input_buffer_13 <= data_in;
                            4'd14: input_buffer_14 <= data_in; 4'd15: input_buffer_15 <= data_in;
                            default: ;
                        endcase
                        input_wr_idx <= (input_wr_idx == 4'd15) ? 4'd15 : input_wr_idx + 4'd1;
                    end
                    // else: write silently dropped; sec_violation_flag set below
                end else if (is_filter_idx) filter_wr_idx <= data_in[3:0];
                else if (is_filter_data) begin
                    // DP3 CM-1: Block FILTER_DATA writes when BUSY.
                    // Filter weights are fully preserved during computation.
                    if (!busy_guard) begin
                        case (filter_wr_idx)
                            4'd0: filter_buffer_0 <= data_in; 4'd1: filter_buffer_1 <= data_in;
                            4'd2: filter_buffer_2 <= data_in; 4'd3: filter_buffer_3 <= data_in;
                            4'd4: filter_buffer_4 <= data_in; 4'd5: filter_buffer_5 <= data_in;
                            4'd6: filter_buffer_6 <= data_in; 4'd7: filter_buffer_7 <= data_in;
                            4'd8: filter_buffer_8 <= data_in;
                            default: ;
                        endcase
                        filter_wr_idx <= (filter_wr_idx == 4'd8) ? 4'd8 : filter_wr_idx + 4'd1;
                    end
                    // else: write silently dropped; sec_violation_flag set below
                end
            end
        end
    end

    // =========================================================================
    // Read Path — with DP3 CM-1 + CM-2 changes
    // CM-1 change: STATUS register bit 2 reflects sec_violation_flag live.
    //              Reading STATUS register clears sec_violation_flag (clear-on-read).
    // CM-2 change: Default read returns 32'h0 instead of 32'hDEADBEEF.
    //              This removes the debug sentinel that disclosed address map
    //              structure (CWE-200 information disclosure fix).
    // =========================================================================
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin data_out <= 32'h0; data_ready <= 1'b0;
        end else begin
            data_ready <= 1'b0;
            if (read_req) begin
                data_ready <= 1'b1;
                case (address)
                    6'h00: data_out <= ctrl_reg;
                    // DP3 CM-1: STATUS[2] = sec_violation_flag (live, clear-on-read)
                    6'h04: data_out <= {status_reg[DATA_WIDTH-1:3],
                                        sec_violation_flag,
                                        status_reg[1:0]};
                    6'h08: data_out <= config_reg;
                    6'h0C: data_out <= {28'h0, input_wr_idx};
                    6'h10: begin
                        case (input_wr_idx)
                            4'd0:  data_out <= input_buffer_0;  4'd1:  data_out <= input_buffer_1;
                            4'd2:  data_out <= input_buffer_2;  4'd3:  data_out <= input_buffer_3;
                            4'd4:  data_out <= input_buffer_4;  4'd5:  data_out <= input_buffer_5;
                            4'd6:  data_out <= input_buffer_6;  4'd7:  data_out <= input_buffer_7;
                            4'd8:  data_out <= input_buffer_8;  4'd9:  data_out <= input_buffer_9;
                            4'd10: data_out <= input_buffer_10; 4'd11: data_out <= input_buffer_11;
                            4'd12: data_out <= input_buffer_12; 4'd13: data_out <= input_buffer_13;
                            4'd14: data_out <= input_buffer_14; 4'd15: data_out <= input_buffer_15;
                            // DP3 CM-2: was 32'hDEADBEEF — now 32'h0
                            default: data_out <= 32'h00000000;
                        endcase
                    end
                    6'h14: data_out <= {28'h0, filter_wr_idx};
                    6'h18: begin
                        case (filter_wr_idx)
                            4'd0: data_out <= filter_buffer_0; 4'd1: data_out <= filter_buffer_1;
                            4'd2: data_out <= filter_buffer_2; 4'd3: data_out <= filter_buffer_3;
                            4'd4: data_out <= filter_buffer_4; 4'd5: data_out <= filter_buffer_5;
                            4'd6: data_out <= filter_buffer_6; 4'd7: data_out <= filter_buffer_7;
                            4'd8: data_out <= filter_buffer_8;
                            // DP3 CM-2: was 32'hDEADBEEF — now 32'h0
                            default: data_out <= 32'h00000000;
                        endcase
                    end
                    6'h1C: data_out <= output_buffer_0; 6'h20: data_out <= output_buffer_1;
                    6'h24: data_out <= output_buffer_2; 6'h28: data_out <= output_buffer_3;
                    6'h2C: data_out <= acc_buffer_0;    6'h30: data_out <= acc_buffer_1;
                    6'h34: data_out <= acc_buffer_2;    6'h38: data_out <= acc_buffer_3;
                    // DP3 CM-2: was 32'hDEADBEEF — now 32'h0
                    default: data_out <= 32'h00000000;
                endcase
            end
        end
    end

    // =========================================================================
    // DP3 CM-1: Security Violation Flag Management
    //
    // This dedicated always block is the sole driver of sec_violation_flag.
    // Priority (descending):
    //   1. Reset (rstn=0) → clear flag
    //   2. Blocked write detected → SET flag (sticky, stays until acknowledged)
    //   3. CPU reads STATUS register → CLEAR flag (clear-on-read acknowledgement)
    //
    // A "blocked write" is any of:
    //   (a) Write to INPUT_DATA while busy_guard=1
    //   (b) Write to FILTER_DATA while busy_guard=1
    //   (c) Write to CTRL with START=1 while busy_guard=1
    //
    // The flag remains set (sticky) if multiple violations occur before the
    // CPU reads STATUS — it records "at least one violation happened".
    // CPU must read STATUS to clear the flag and acknowledge the event.
    // =========================================================================
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            sec_violation_flag <= 1'b0;
        end else begin
            if (write_req && busy_guard &&
                    (is_input_data  ||
                     is_filter_data ||
                     (is_ctrl && data_in[CTRL_START_BIT]))) begin
                // Blocked write attempt detected — raise violation flag
                sec_violation_flag <= 1'b1;
            end else if (read_req && is_status) begin
                // CPU read STATUS — clear flag (acknowledgement)
                sec_violation_flag <= 1'b0;
            end
        end
    end

    // =========================================================================
    // Feed FSM — unchanged from DP2
    // =========================================================================
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin feed_state <= FEED_IDLE; feed_counter <= 4'd0; feed_active <= 1'b0;
        end else begin
            case (feed_state)
                FEED_IDLE: begin
                    feed_active <= 1'b0;
                    if (ctrl_reg[CTRL_START_BIT] && !status_reg[STATUS_BUSY_BIT]) begin
                        feed_state <= FEED_FILTER; feed_counter <= 4'd0; feed_active <= 1'b1;
                    end
                end
                FEED_FILTER: begin
                    if (feed_counter == 4'd8) begin feed_state <= FEED_INPUT; feed_counter <= 4'd0;
                    end else feed_counter <= feed_counter + 4'd1;
                end
                FEED_INPUT: begin
                    if (feed_counter == 4'd15) begin feed_state <= FEED_START; feed_counter <= 4'd0;
                    end else feed_counter <= feed_counter + 4'd1;
                end
                FEED_START: begin feed_state <= FEED_WAIT; end
                FEED_WAIT: begin
                    if (wino_data_out_valid) begin
                        case (feed_counter[1:0])
                            2'd0: output_buffer_0 <= wino_data_out; 2'd1: output_buffer_1 <= wino_data_out;
                            2'd2: output_buffer_2 <= wino_data_out; 2'd3: output_buffer_3 <= wino_data_out;
                            default: ;
                        endcase
                        feed_counter <= feed_counter + 4'd1;
                    end
                    if (wino_done) begin
                        feed_state <= FEED_COLLECT;
                    end
                end
                FEED_COLLECT: begin
                    if (wino_data_out_valid) begin
                        case (feed_counter[1:0])
                            2'd0: output_buffer_0 <= wino_data_out; 2'd1: output_buffer_1 <= wino_data_out;
                            2'd2: output_buffer_2 <= wino_data_out; 2'd3: output_buffer_3 <= wino_data_out;
                            default: ;
                        endcase
                        feed_counter <= feed_counter + 4'd1;
                    end
                    if (feed_counter[2] || (!wino_data_out_valid && wino_done_latched))
                        feed_state <= FEED_IDLE;
                end
                default: feed_state <= FEED_IDLE;
            endcase
        end
    end

    // =========================================================================
    // wino_done_latched — unchanged from DP2
    // =========================================================================
    always @(posedge clk or negedge rstn) begin
        if (!rstn) wino_done_latched <= 1'b0;
        else begin
            if (wino_done) wino_done_latched <= 1'b1;
            else if (write_req && is_status) wino_done_latched <= 1'b0;
            else if (ctrl_reg[CTRL_START_BIT]) wino_done_latched <= 1'b0;
        end
    end

    // =========================================================================
    // Accumulator — unchanged from DP2
    // =========================================================================
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            acc_buffer_0 <= {DATA_WIDTH{1'b0}}; acc_buffer_1 <= {DATA_WIDTH{1'b0}};
            acc_buffer_2 <= {DATA_WIDTH{1'b0}}; acc_buffer_3 <= {DATA_WIDTH{1'b0}};
        end else begin
            if (ctrl_reg[CTRL_CLEAR_ACC_BIT]) begin
                acc_buffer_0 <= {DATA_WIDTH{1'b0}}; acc_buffer_1 <= {DATA_WIDTH{1'b0}};
                acc_buffer_2 <= {DATA_WIDTH{1'b0}}; acc_buffer_3 <= {DATA_WIDTH{1'b0}};
            end else if (wino_data_out_valid
                && (feed_state == FEED_WAIT || feed_state == FEED_COLLECT)
                && ctrl_reg[CTRL_ACCUM_EN_BIT]) begin
                case (feed_counter[1:0])
                    2'd0: acc_buffer_0 <= $signed(acc_buffer_0) + $signed(wino_data_out);
                    2'd1: acc_buffer_1 <= $signed(acc_buffer_1) + $signed(wino_data_out);
                    2'd2: acc_buffer_2 <= $signed(acc_buffer_2) + $signed(wino_data_out);
                    2'd3: acc_buffer_3 <= $signed(acc_buffer_3) + $signed(wino_data_out);
                    default: ;
                endcase
            end
        end
    end

    // =========================================================================
    // STATUS register — unchanged from DP2
    // Note: STATUS[2] (sec_violation_flag) is inserted live in the read path
    //       above; it does NOT go through status_reg to avoid a 1-cycle lag.
    // =========================================================================
    always @(posedge clk or negedge rstn) begin
        if (!rstn) status_reg <= 32'h0;
        else begin
            status_reg[STATUS_BUSY_BIT] <= feed_active;
            status_reg[STATUS_DONE_BIT] <= wino_done_latched;
        end
    end

    // =========================================================================
    // IRQ — unchanged from DP2
    // =========================================================================
    always @(posedge clk or negedge rstn) begin
        if (!rstn) winograd_irq <= 1'b0;
        else begin
            if (ctrl_reg[CTRL_IRQ_EN_BIT] && wino_done_latched) winograd_irq <= 1'b1;
            else if (write_req && is_status) winograd_irq <= 1'b0;
        end
    end

endmodule
