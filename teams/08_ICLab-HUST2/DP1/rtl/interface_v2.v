/* verilator lint_off DECLFILENAME */
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
    localparam STATUS_BUSY_BIT = 0;
    localparam STATUS_DONE_BIT = 1;

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
                if (is_ctrl) ctrl_reg <= data_in;
                else if (is_config) config_reg <= data_in;
                else if (is_input_idx) input_wr_idx <= data_in[3:0];
                else if (is_input_data) begin
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
                end else if (is_filter_idx) filter_wr_idx <= data_in[3:0];
                else if (is_filter_data) begin
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
            end
        end
    end

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin data_out <= 32'h0; data_ready <= 1'b0;
        end else begin
            data_ready <= 1'b0;
            if (read_req) begin
                data_ready <= 1'b1;
                case (address)
                    6'h00: data_out <= ctrl_reg;
                    6'h04: data_out <= status_reg;
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
                            default: data_out <= 32'hDEADBEEF;
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
                            default: data_out <= 32'hDEADBEEF;
                        endcase
                    end
                    6'h1C: data_out <= output_buffer_0; 6'h20: data_out <= output_buffer_1;
                    6'h24: data_out <= output_buffer_2; 6'h28: data_out <= output_buffer_3;
                    6'h2C: data_out <= acc_buffer_0;    6'h30: data_out <= acc_buffer_1;
                    6'h34: data_out <= acc_buffer_2;    6'h38: data_out <= acc_buffer_3;
                    default: data_out <= 32'hDEADBEEF;
                endcase
            end
        end
    end

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

    always @(posedge clk or negedge rstn) begin
        if (!rstn) wino_done_latched <= 1'b0;
        else begin
            if (wino_done) wino_done_latched <= 1'b1;
            else if (write_req && is_status) wino_done_latched <= 1'b0;
            else if (ctrl_reg[CTRL_START_BIT]) wino_done_latched <= 1'b0;
        end
    end

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

    always @(posedge clk or negedge rstn) begin
        if (!rstn) status_reg <= 32'h0;
        else begin
            status_reg[STATUS_BUSY_BIT] <= feed_active;
            status_reg[STATUS_DONE_BIT] <= wino_done_latched;
        end
    end

    always @(posedge clk or negedge rstn) begin
        if (!rstn) winograd_irq <= 1'b0;
        else begin
            if (ctrl_reg[CTRL_IRQ_EN_BIT] && wino_done_latched) winograd_irq <= 1'b1;
            else if (write_req && is_status) winograd_irq <= 1'b0;
        end
    end

endmodule