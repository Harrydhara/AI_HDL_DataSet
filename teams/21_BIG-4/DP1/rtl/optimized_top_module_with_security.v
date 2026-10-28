module tensorbolt_ai_accelerator (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  ui_in,
    output wire [7:0]  uo_out,
    input  wire [5:0]  address,
    input  wire [31:0] data_in,
    input  wire [1:0]  data_write_n,
    input  wire [1:0]  data_read_n,
    output reg  [31:0] data_out,
    output wire        data_ready,
    output reg         user_interrupt,
    output reg         illegal_cmd_flag
);

integer i;

reg [31:0] op_a_reg;
reg [31:0] op_b_reg;
reg [63:0] acc_reg;

reg [31:0] a_buf0 [0:15];
reg [31:0] a_buf1 [0:15];
reg [31:0] b_buf0 [0:15];
reg [31:0] b_buf1 [0:15];

reg        load_bank_reg;
reg        exec_bank_reg;
reg [4:0]  vec_len_reg;
reg [2:0]  mode_reg;
reg [4:0]  count_a0_reg, count_a1_reg, count_b0_reg, count_b1_reg;
reg [4:0]  last_exec_count_reg;

reg        busy_reg;
reg        done_reg;
reg [1:0]  state;

reg        secure_unlocked_reg;
reg        auth_stage1_reg;
reg [1:0]  bad_count_reg;
reg        lockout_reg;

reg signed [17:0] dot_tmp;
reg signed [63:0] mul_tmp;

reg signed [17:0] d0,d1,d2,d3,d4,d5,d6,d7,d8,d9,d10,d11,d12,d13,d14,d15;
reg signed [31:0] sum_batch;

wire write_hit;
wire read_hit;
wire hw_enable;
wire parity_received;
wire parity_calc;
wire bad_parity;

localparam ST_IDLE = 2'b00;
localparam ST_EXEC = 2'b01;
localparam ST_DONE = 2'b10;

localparam MODE_MUL32     = 3'd0;
localparam MODE_DOT4      = 3'd1;
localparam MODE_VEC16_ACC = 3'd2;
localparam MODE_VEC16_CLR = 3'd3;

localparam AUTH0_MAGIC = 32'hC0DECAFE;
localparam AUTH1_MAGIC = 32'h5A5AA5A5;

assign write_hit       = (data_write_n == 2'b00);
assign read_hit        = (data_read_n  == 2'b00);
assign hw_enable       = ui_in[0];
assign parity_received = ui_in[7];
assign parity_calc     = ^data_in[7:0];
assign bad_parity      = write_hit & (parity_received != parity_calc);
assign data_ready      = write_hit | read_hit;

/* uo_out bit map:
   [7] lockout
   [6] illegal
   [5] irq
   [4] done
   [3] busy
   [2] load_bank
   [1:0] mode[1:0]
*/
assign uo_out = {lockout_reg, illegal_cmd_flag, user_interrupt, done_reg, busy_reg, load_bank_reg, mode_reg[1:0]};

function signed [17:0] dot4_int8;
    input [31:0] va;
    input [31:0] vb;
    reg signed [7:0] a0, a1, a2, a3;
    reg signed [7:0] b0, b1, b2, b3;
    reg signed [15:0] p0, p1, p2, p3;
    begin
        a0 = va[7:0];
        a1 = va[15:8];
        a2 = va[23:16];
        a3 = va[31:24];
        b0 = vb[7:0];
        b1 = vb[15:8];
        b2 = vb[23:16];
        b3 = vb[31:24];
        p0 = a0 * b0;
        p1 = a1 * b1;
        p2 = a2 * b2;
        p3 = a3 * b3;
        dot4_int8 = p0 + p1 + p2 + p3;
    end
endfunction

always @(*) begin
    data_out = 32'd0;
    case (address)
        6'h00: data_out = {21'b0, bad_count_reg, secure_unlocked_reg, lockout_reg, illegal_cmd_flag, user_interrupt, done_reg, busy_reg, load_bank_reg, mode_reg[1:0]};
        6'h04: data_out = {18'b0, 5'd16, last_exec_count_reg, vec_len_reg, mode_reg};
        6'h08: data_out = op_a_reg;
        6'h0C: data_out = op_b_reg;
        6'h18: data_out = acc_reg[31:0];
        6'h1C: data_out = acc_reg[63:32];
        6'h20: data_out = {22'b0, 5'd16, last_exec_count_reg};
        default: data_out = 32'd0;
    endcase
end

always @(*) begin
    d0=0; d1=0; d2=0; d3=0; d4=0; d5=0; d6=0; d7=0;
    d8=0; d9=0; d10=0; d11=0; d12=0; d13=0; d14=0; d15=0;

    if (exec_bank_reg == 1'b0) begin
        if (vec_len_reg > 5'd0)  d0  = dot4_int8(a_buf0[0],  b_buf0[0]);
        if (vec_len_reg > 5'd1)  d1  = dot4_int8(a_buf0[1],  b_buf0[1]);
        if (vec_len_reg > 5'd2)  d2  = dot4_int8(a_buf0[2],  b_buf0[2]);
        if (vec_len_reg > 5'd3)  d3  = dot4_int8(a_buf0[3],  b_buf0[3]);
        if (vec_len_reg > 5'd4)  d4  = dot4_int8(a_buf0[4],  b_buf0[4]);
        if (vec_len_reg > 5'd5)  d5  = dot4_int8(a_buf0[5],  b_buf0[5]);
        if (vec_len_reg > 5'd6)  d6  = dot4_int8(a_buf0[6],  b_buf0[6]);
        if (vec_len_reg > 5'd7)  d7  = dot4_int8(a_buf0[7],  b_buf0[7]);
        if (vec_len_reg > 5'd8)  d8  = dot4_int8(a_buf0[8],  b_buf0[8]);
        if (vec_len_reg > 5'd9)  d9  = dot4_int8(a_buf0[9],  b_buf0[9]);
        if (vec_len_reg > 5'd10) d10 = dot4_int8(a_buf0[10], b_buf0[10]);
        if (vec_len_reg > 5'd11) d11 = dot4_int8(a_buf0[11], b_buf0[11]);
        if (vec_len_reg > 5'd12) d12 = dot4_int8(a_buf0[12], b_buf0[12]);
        if (vec_len_reg > 5'd13) d13 = dot4_int8(a_buf0[13], b_buf0[13]);
        if (vec_len_reg > 5'd14) d14 = dot4_int8(a_buf0[14], b_buf0[14]);
        if (vec_len_reg > 5'd15) d15 = dot4_int8(a_buf0[15], b_buf0[15]);
    end else begin
        if (vec_len_reg > 5'd0)  d0  = dot4_int8(a_buf1[0],  b_buf1[0]);
        if (vec_len_reg > 5'd1)  d1  = dot4_int8(a_buf1[1],  b_buf1[1]);
        if (vec_len_reg > 5'd2)  d2  = dot4_int8(a_buf1[2],  b_buf1[2]);
        if (vec_len_reg > 5'd3)  d3  = dot4_int8(a_buf1[3],  b_buf1[3]);
        if (vec_len_reg > 5'd4)  d4  = dot4_int8(a_buf1[4],  b_buf1[4]);
        if (vec_len_reg > 5'd5)  d5  = dot4_int8(a_buf1[5],  b_buf1[5]);
        if (vec_len_reg > 5'd6)  d6  = dot4_int8(a_buf1[6],  b_buf1[6]);
        if (vec_len_reg > 5'd7)  d7  = dot4_int8(a_buf1[7],  b_buf1[7]);
        if (vec_len_reg > 5'd8)  d8  = dot4_int8(a_buf1[8],  b_buf1[8]);
        if (vec_len_reg > 5'd9)  d9  = dot4_int8(a_buf1[9],  b_buf1[9]);
        if (vec_len_reg > 5'd10) d10 = dot4_int8(a_buf1[10], b_buf1[10]);
        if (vec_len_reg > 5'd11) d11 = dot4_int8(a_buf1[11], b_buf1[11]);
        if (vec_len_reg > 5'd12) d12 = dot4_int8(a_buf1[12], b_buf1[12]);
        if (vec_len_reg > 5'd13) d13 = dot4_int8(a_buf1[13], b_buf1[13]);
        if (vec_len_reg > 5'd14) d14 = dot4_int8(a_buf1[14], b_buf1[14]);
        if (vec_len_reg > 5'd15) d15 = dot4_int8(a_buf1[15], b_buf1[15]);
    end

    sum_batch = d0+d1+d2+d3+d4+d5+d6+d7+d8+d9+d10+d11+d12+d13+d14+d15;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        op_a_reg <= 32'd0;
        op_b_reg <= 32'd0;
        acc_reg <= 64'd0;
        load_bank_reg <= 1'b0;
        exec_bank_reg <= 1'b0;
        vec_len_reg <= 5'd16;
        mode_reg <= MODE_MUL32;
        count_a0_reg <= 5'd0;
        count_a1_reg <= 5'd0;
        count_b0_reg <= 5'd0;
        count_b1_reg <= 5'd0;
        last_exec_count_reg <= 5'd0;
        busy_reg <= 1'b0;
        done_reg <= 1'b0;
        user_interrupt <= 1'b0;
        illegal_cmd_flag <= 1'b0;
        state <= ST_IDLE;
        secure_unlocked_reg <= 1'b0;
        auth_stage1_reg <= 1'b0;
        bad_count_reg <= 2'd0;
        lockout_reg <= 1'b0;
        dot_tmp <= 18'd0;
        mul_tmp <= 64'd0;
        for (i = 0; i < 16; i = i + 1) begin
            a_buf0[i] <= 32'd0;
            a_buf1[i] <= 32'd0;
            b_buf0[i] <= 32'd0;
            b_buf1[i] <= 32'd0;
        end
    end else begin
        dot_tmp = 18'd0;
        mul_tmp = 64'd0;

        if (bad_parity) begin
            illegal_cmd_flag <= 1'b1;
            secure_unlocked_reg <= 1'b0;
            auth_stage1_reg <= 1'b0;
            if (bad_count_reg != 2'b11)
                bad_count_reg <= bad_count_reg + 2'd1;
            if (bad_count_reg >= 2'd2)
                lockout_reg <= 1'b1;
        end else if (write_hit) begin
            if (lockout_reg) begin
                if ((address == 6'h00) && data_in[3]) begin
                    op_a_reg <= 32'd0;
                    op_b_reg <= 32'd0;
                    acc_reg <= 64'd0;
                    load_bank_reg <= 1'b0;
                    exec_bank_reg <= 1'b0;
                    vec_len_reg <= 5'd16;
                    mode_reg <= MODE_MUL32;
                    count_a0_reg <= 5'd0;
                    count_a1_reg <= 5'd0;
                    count_b0_reg <= 5'd0;
                    count_b1_reg <= 5'd0;
                    last_exec_count_reg <= 5'd0;
                    busy_reg <= 1'b0;
                    done_reg <= 1'b0;
                    user_interrupt <= 1'b0;
                    illegal_cmd_flag <= 1'b0;
                    state <= ST_IDLE;
                    secure_unlocked_reg <= 1'b0;
                    auth_stage1_reg <= 1'b0;
                    bad_count_reg <= 2'd0;
                    lockout_reg <= 1'b0;
                    for (i = 0; i < 16; i = i + 1) begin
                        a_buf0[i] <= 32'd0;
                        a_buf1[i] <= 32'd0;
                        b_buf0[i] <= 32'd0;
                        b_buf1[i] <= 32'd0;
                    end
                end
            end else begin
                if (busy_reg && (address != 6'h00)) begin
                    illegal_cmd_flag <= 1'b1;
                    secure_unlocked_reg <= 1'b0;
                    auth_stage1_reg <= 1'b0;
                    if (bad_count_reg != 2'b11)
                        bad_count_reg <= bad_count_reg + 2'd1;
                end else begin
                    case (address)
                        6'h00: begin
                            if (data_in[3]) begin
                                op_a_reg <= 32'd0;
                                op_b_reg <= 32'd0;
                                acc_reg <= 64'd0;
                                load_bank_reg <= 1'b0;
                                exec_bank_reg <= 1'b0;
                                vec_len_reg <= 5'd16;
                                mode_reg <= MODE_MUL32;
                                count_a0_reg <= 5'd0;
                                count_a1_reg <= 5'd0;
                                count_b0_reg <= 5'd0;
                                count_b1_reg <= 5'd0;
                                last_exec_count_reg <= 5'd0;
                                busy_reg <= 1'b0;
                                done_reg <= 1'b0;
                                user_interrupt <= 1'b0;
                                illegal_cmd_flag <= 1'b0;
                                state <= ST_IDLE;
                                secure_unlocked_reg <= 1'b0;
                                auth_stage1_reg <= 1'b0;
                                bad_count_reg <= 2'd0;
                                lockout_reg <= 1'b0;
                                for (i = 0; i < 16; i = i + 1) begin
                                    a_buf0[i] <= 32'd0;
                                    a_buf1[i] <= 32'd0;
                                    b_buf0[i] <= 32'd0;
                                    b_buf1[i] <= 32'd0;
                                end
                            end else begin
                                if (data_in[1]) acc_reg <= 64'd0;
                                if (data_in[2]) begin
                                    done_reg <= 1'b0;
                                    user_interrupt <= 1'b0;
                                end
                                if (data_in[4]) begin
                                    if (load_bank_reg == 1'b0) begin
                                        count_a0_reg <= 5'd0;
                                        count_b0_reg <= 5'd0;
                                    end else begin
                                        count_a1_reg <= 5'd0;
                                        count_b1_reg <= 5'd0;
                                    end
                                end
                                if (data_in[0] && (state == ST_IDLE)) begin
                                    if (!hw_enable || !secure_unlocked_reg) begin
                                        illegal_cmd_flag <= 1'b1;
                                        secure_unlocked_reg <= 1'b0;
                                        auth_stage1_reg <= 1'b0;
                                        if (bad_count_reg != 2'b11)
                                            bad_count_reg <= bad_count_reg + 2'd1;
                                    end else if ((mode_reg == MODE_MUL32) || (mode_reg == MODE_DOT4)) begin
                                        busy_reg <= 1'b1;
                                        done_reg <= 1'b0;
                                        user_interrupt <= 1'b0;
                                        last_exec_count_reg <= 5'd1;
                                        secure_unlocked_reg <= 1'b0;
                                        auth_stage1_reg <= 1'b0;
                                        state <= ST_EXEC;
                                    end else if ((vec_len_reg == 5'd0) || (vec_len_reg > 5'd16)) begin
                                        illegal_cmd_flag <= 1'b1;
                                    end else if ((load_bank_reg == 1'b0) && ((count_a0_reg < vec_len_reg) || (count_b0_reg < vec_len_reg))) begin
                                        illegal_cmd_flag <= 1'b1;
                                    end else if ((load_bank_reg == 1'b1) && ((count_a1_reg < vec_len_reg) || (count_b1_reg < vec_len_reg))) begin
                                        illegal_cmd_flag <= 1'b1;
                                    end else begin
                                        if (mode_reg == MODE_VEC16_CLR)
                                            acc_reg <= 64'd0;
                                        exec_bank_reg <= load_bank_reg;
                                        busy_reg <= 1'b1;
                                        done_reg <= 1'b0;
                                        user_interrupt <= 1'b0;
                                        last_exec_count_reg <= vec_len_reg;
                                        secure_unlocked_reg <= 1'b0;
                                        auth_stage1_reg <= 1'b0;
                                        state <= ST_EXEC;
                                    end
                                end
                            end
                        end
                        6'h04: begin
                            mode_reg <= data_in[2:0];
                            vec_len_reg <= data_in[7:3];
                            load_bank_reg <= data_in[8];
                        end
                        6'h08: op_a_reg <= data_in;
                        6'h0C: op_b_reg <= data_in;
                        6'h10: begin
                            if (load_bank_reg == 1'b0) begin
                                if (count_a0_reg < 5'd16) begin
                                    a_buf0[count_a0_reg[3:0]] <= data_in;
                                    count_a0_reg <= count_a0_reg + 5'd1;
                                end else begin
                                    illegal_cmd_flag <= 1'b1;
                                end
                            end else begin
                                if (count_a1_reg < 5'd16) begin
                                    a_buf1[count_a1_reg[3:0]] <= data_in;
                                    count_a1_reg <= count_a1_reg + 5'd1;
                                end else begin
                                    illegal_cmd_flag <= 1'b1;
                                end
                            end
                        end
                        6'h14: begin
                            if (load_bank_reg == 1'b0) begin
                                if (count_b0_reg < 5'd16) begin
                                    b_buf0[count_b0_reg[3:0]] <= data_in;
                                    count_b0_reg <= count_b0_reg + 5'd1;
                                end else begin
                                    illegal_cmd_flag <= 1'b1;
                                end
                            end else begin
                                if (count_b1_reg < 5'd16) begin
                                    b_buf1[count_b1_reg[3:0]] <= data_in;
                                    count_b1_reg <= count_b1_reg + 5'd1;
                                end else begin
                                    illegal_cmd_flag <= 1'b1;
                                end
                            end
                        end
                        6'h28: begin
                            if (data_in == AUTH0_MAGIC) begin
                                auth_stage1_reg <= 1'b1;
                                secure_unlocked_reg <= 1'b0;
                            end else begin
                                illegal_cmd_flag <= 1'b1;
                            end
                        end
                        6'h2C: begin
                            if (auth_stage1_reg && (data_in == AUTH1_MAGIC)) begin
                                secure_unlocked_reg <= 1'b1;
                                auth_stage1_reg <= 1'b0;
                            end else begin
                                illegal_cmd_flag <= 1'b1;
                                auth_stage1_reg <= 1'b0;
                            end
                        end
                        default: begin
                        end
                    endcase
                end
            end
        end

        case (state)
            ST_IDLE: begin
            end
            ST_EXEC: begin
                if (mode_reg == MODE_MUL32) begin
                    mul_tmp = $signed(op_a_reg) * $signed(op_b_reg);
                    acc_reg <= mul_tmp;
                    state <= ST_DONE;
                end else if (mode_reg == MODE_DOT4) begin
                    dot_tmp = dot4_int8(op_a_reg, op_b_reg);
                    acc_reg <= {{46{dot_tmp[17]}}, dot_tmp};
                    state <= ST_DONE;
                end else begin
                    acc_reg <= acc_reg + {{32{sum_batch[31]}}, sum_batch};
                    state <= ST_DONE;
                end
            end
            ST_DONE: begin
                busy_reg <= 1'b0;
                done_reg <= 1'b1;
                user_interrupt <= 1'b1;
                state <= ST_IDLE;
            end
            default: begin
                state <= ST_IDLE;
            end
        endcase
    end
end

endmodule
