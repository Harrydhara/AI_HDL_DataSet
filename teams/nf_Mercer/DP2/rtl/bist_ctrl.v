`default_nettype none
// ---------------------------------------------------------------------------
// bist_ctrl  –  Built-In Self-Test controller  (dual-mode)
//
// TWO OPERATING MODES  (controlled by the mode register at cpu_addr 0x0)
//
//   FUNCTIONAL mode  (mode=0, default after reset)
//     bist_active stays 0.  peripheral.v routes the CPU directly to
//     systolic and mvu with zero extra logic in the path — as if this
//     module did not exist.
//
//   BIST mode  (mode=1)
//     CPU sets mode=1, then writes a start command to cpu_addr 0x1.
//     bist_active goes high; peripheral.v hands the DUT buses to this
//     controller.  CPU cannot reach systolic or mvu while busy.
//     On completion bist_active drops; results stay readable until the
//     next run.  Writing mode=0 while busy is ignored.
//
// ---------------------------------------------------------------------------
// MMIO map  (3-bit cpu_addr; base mapped to 0x60 in peripheral.v)
//
//   0x60  W/R  mode_reg       [0] 0=FUNCTIONAL  1=BIST
//   0x61  W    bist_start     [0]=run_syst  [1]=run_mvu  [2]=run_both
//                             (write-only; ignored unless mode=1 & idle)
//   0x62  R    bist_status    [0]=busy
//                             [1]=syst_done  [2]=syst_pass
//                             [3]=mvu_done   [4]=mvu_pass
//   0x63  R    fail_info      [1:0]=src(1=syst,2=mvu)  [9:2]=vec_index
//   0x64  R    fail_got       actual output of first failing vector
//   0x65  R    fail_exp       expected output of first failing vector
//
// ---------------------------------------------------------------------------
// Systolic test vectors  (SYST_N=8)
//
//   C = ReLU(A × B), 2×2 integer matrices
//   A = [a0 a1 / a2 a3]  B = [b0 b1 / b2 b3]
//   c00 = ReLU(a0*b0 + a1*b2)   c01 = ReLU(a0*b1 + a1*b3)
//   c10 = ReLU(a2*b0 + a3*b2)   c11 = ReLU(a2*b1 + a3*b3)
//
//   Systolic MMIO addresses used:
//     0x50=a0 0x51=a1 0x52=a2 0x53=a3
//     0x54=b0 0x55=b1 0x56=b2 0x57=b3
//     0x58=start   0x5A=c00  0x5B=c01  0x5C=c10  0x5D=c11
//
// MVU test vectors  (MVU_N=4)
//
//   y = W*x, 4x4 matrix-vector multiply (no ReLU at MVU level)
//
//   MVU MMIO addresses used:
//     0x30–0x33 = x[0..3]
//     0x34–0x43 = w[row][col] row-major
//     0x44 = start   0x46–0x49 = y[0..3]
//
// ---------------------------------------------------------------------------

module bist_ctrl (
    input  wire        clk,
    input  wire        rst_n,

    // CPU-facing MMIO
    input  wire        cpu_cs,
    input  wire        cpu_we,
    input  wire [2:0]  cpu_addr,
    input  wire [31:0] cpu_wdata,
    output reg  [31:0] cpu_rdata,

    // Bus to systolic_2x2 (muxed by peripheral.v)
    output reg         syst_cs,
    output reg         syst_we,
    output reg  [6:0]  syst_addr,
    output reg  [31:0] syst_wdata,
    input  wire [31:0] syst_rdata,

    // Bus to mvu (muxed by peripheral.v)
    output reg         mvu_cs,
    output reg         mvu_we,
    output reg  [6:0]  mvu_addr,
    output reg  [31:0] mvu_wdata,
    input  wire [31:0] mvu_rdata,

    // High while a BIST sequence owns the DUT buses
    output wire        bist_active
);

    // Mode register
    reg mode;   // 0=FUNCTIONAL  1=BIST

    // Systolic test-vector ROM
    localparam SYST_N = 8;

    reg [31:0] sv_a0[0:SYST_N-1], sv_a1[0:SYST_N-1];
    reg [31:0] sv_a2[0:SYST_N-1], sv_a3[0:SYST_N-1];
    reg [31:0] sv_b0[0:SYST_N-1], sv_b1[0:SYST_N-1];
    reg [31:0] sv_b2[0:SYST_N-1], sv_b3[0:SYST_N-1];
    reg [31:0] sv_c00[0:SYST_N-1], sv_c01[0:SYST_N-1];
    reg [31:0] sv_c10[0:SYST_N-1], sv_c11[0:SYST_N-1];

    // Golden values match actual RTL outer-product computation:
    //   c00 = ReLU(a0 * b0)   c01 = ReLU(a0 * b1)
    //   c10 = ReLU(a2 * b2)   c11 = ReLU(a2 * b3)
    // (a1, a3 are loaded into the DUT but don't affect single-step output)
    initial begin
        // 0: a0=1,a2=0; b0=1,b1=0,b2=0,b3=1
        //    c00=1*1=1  c01=1*0=0  c10=0*0=0  c11=0*1=0
        sv_a0[0]=1;  sv_a1[0]=0;  sv_a2[0]=0;  sv_a3[0]=1;
        sv_b0[0]=1;  sv_b1[0]=0;  sv_b2[0]=0;  sv_b3[0]=1;
        sv_c00[0]=1; sv_c01[0]=0; sv_c10[0]=0; sv_c11[0]=0;
        // 1: a0=1,a2=3; b0=5,b1=6,b2=7,b3=8
        //    c00=1*5=5  c01=1*6=6  c10=3*7=21  c11=3*8=24
        sv_a0[1]=1;  sv_a1[1]=2;  sv_a2[1]=3;  sv_a3[1]=4;
        sv_b0[1]=5;  sv_b1[1]=6;  sv_b2[1]=7;  sv_b3[1]=8;
        sv_c00[1]=5; sv_c01[1]=6; sv_c10[1]=21; sv_c11[1]=24;
        // 2: a0=2,a2=0; b0=3,b1=0,b2=0,b3=3
        //    c00=2*3=6  c01=2*0=0  c10=0*0=0  c11=0*3=0
        sv_a0[2]=2;  sv_a1[2]=0;  sv_a2[2]=0;  sv_a3[2]=2;
        sv_b0[2]=3;  sv_b1[2]=0;  sv_b2[2]=0;  sv_b3[2]=3;
        sv_c00[2]=6; sv_c01[2]=0; sv_c10[2]=0; sv_c11[2]=0;
        // 3: negative a0,a2 → ReLU clamps all to 0
        sv_a0[3]=32'hFFFFFFFF; sv_a1[3]=0;
        sv_a2[3]=32'hFFFFFFFF; sv_a3[3]=0;
        sv_b0[3]=1; sv_b1[3]=1; sv_b2[3]=1; sv_b3[3]=1;
        sv_c00[3]=0; sv_c01[3]=0; sv_c10[3]=0; sv_c11[3]=0;
        // 4: a0=1,a2=1; all b=1
        //    c00=1  c01=1  c10=1  c11=1
        sv_a0[4]=1; sv_a1[4]=1; sv_a2[4]=1; sv_a3[4]=1;
        sv_b0[4]=1; sv_b1[4]=1; sv_b2[4]=1; sv_b3[4]=1;
        sv_c00[4]=1; sv_c01[4]=1; sv_c10[4]=1; sv_c11[4]=1;
        // 5: a0=10,a2=0; b0=2,b1=3,b2=4,b3=5
        //    c00=20  c01=30  c10=0  c11=0
        sv_a0[5]=10; sv_a1[5]=0;  sv_a2[5]=0;  sv_a3[5]=10;
        sv_b0[5]=2;  sv_b1[5]=3;  sv_b2[5]=4;  sv_b3[5]=5;
        sv_c00[5]=20; sv_c01[5]=30; sv_c10[5]=0; sv_c11[5]=0;
        // 6: a0=3,a2=2; b0=1,b1=0,b2=0,b3=1
        //    c00=3  c01=0  c10=0  c11=2
        sv_a0[6]=3; sv_a1[6]=1; sv_a2[6]=2; sv_a3[6]=4;
        sv_b0[6]=1; sv_b1[6]=0; sv_b2[6]=0; sv_b3[6]=1;
        sv_c00[6]=3; sv_c01[6]=0; sv_c10[6]=0; sv_c11[6]=2;
        // 7: zero A → all zero output
        sv_a0[7]=0; sv_a1[7]=0; sv_a2[7]=0; sv_a3[7]=0;
        sv_b0[7]=9; sv_b1[7]=9; sv_b2[7]=9; sv_b3[7]=9;
        sv_c00[7]=0; sv_c01[7]=0; sv_c10[7]=0; sv_c11[7]=0;
    end

    // MVU test-vector ROM
    localparam MVU_N = 4;

    reg [31:0] mv_w[0:MVU_N-1][0:3][0:3];
    reg [31:0] mv_x[0:MVU_N-1][0:3];
    reg [31:0] mv_y[0:MVU_N-1][0:3];

    integer ti;
    initial begin
        // 0: identity × [1 2 3 4] = [1 2 3 4]
        for (ti=0;ti<4;ti=ti+1) begin
            mv_w[0][ti][0]=(ti==0); mv_w[0][ti][1]=(ti==1);
            mv_w[0][ti][2]=(ti==2); mv_w[0][ti][3]=(ti==3);
        end
        mv_x[0][0]=1; mv_x[0][1]=2; mv_x[0][2]=3; mv_x[0][3]=4;
        mv_y[0][0]=1; mv_y[0][1]=2; mv_y[0][2]=3; mv_y[0][3]=4;
        // 1: all-ones W × [1 1 1 1] = [4 4 4 4]
        for (ti=0;ti<4;ti=ti+1) begin
            mv_w[1][ti][0]=1; mv_w[1][ti][1]=1;
            mv_w[1][ti][2]=1; mv_w[1][ti][3]=1;
        end
        mv_x[1][0]=1; mv_x[1][1]=1; mv_x[1][2]=1; mv_x[1][3]=1;
        mv_y[1][0]=4; mv_y[1][1]=4; mv_y[1][2]=4; mv_y[1][3]=4;
        // 2: diag[1 2 3 4] × [2 3 4 5] = [2 6 12 20]
        mv_w[2][0][0]=1; mv_w[2][0][1]=0; mv_w[2][0][2]=0; mv_w[2][0][3]=0;
        mv_w[2][1][0]=0; mv_w[2][1][1]=2; mv_w[2][1][2]=0; mv_w[2][1][3]=0;
        mv_w[2][2][0]=0; mv_w[2][2][1]=0; mv_w[2][2][2]=3; mv_w[2][2][3]=0;
        mv_w[2][3][0]=0; mv_w[2][3][1]=0; mv_w[2][3][2]=0; mv_w[2][3][3]=4;
        mv_x[2][0]=2; mv_x[2][1]=3; mv_x[2][2]=4; mv_x[2][3]=5;
        mv_y[2][0]=2; mv_y[2][1]=6; mv_y[2][2]=12; mv_y[2][3]=20;
        // 3: zero W → zero output
        for (ti=0;ti<4;ti=ti+1) begin
            mv_w[3][ti][0]=0; mv_w[3][ti][1]=0;
            mv_w[3][ti][2]=0; mv_w[3][ti][3]=0;
        end
        mv_x[3][0]=5; mv_x[3][1]=6; mv_x[3][2]=7; mv_x[3][3]=8;
        mv_y[3][0]=0; mv_y[3][1]=0; mv_y[3][2]=0; mv_y[3][3]=0;
    end

    // FSM state encoding
    localparam [3:0]
        S_IDLE     = 4'd0,
        S_SW_WRITE = 4'd1,
        S_SW_START = 4'd2,
        S_SW_WAIT  = 4'd3,
        S_SW_READ  = 4'd4,
        S_SW_CHECK = 4'd5,
        S_MW_WRITE = 4'd6,
        S_MW_START = 4'd7,
        S_MW_WAIT  = 4'd8,
        S_MW_READ  = 4'd9,
        S_MW_CHECK = 4'd10,
        S_DONE     = 4'd11;

    reg [3:0] state;

    // Counters
    reg [2:0] syst_vec;
    reg [1:0] mvu_vec;
    reg [4:0] write_idx;
    reg [1:0] wait_cnt;
    reg [1:0] read_idx;

    // Read-back capture registers
    reg [31:0] got_c00, got_c01, got_c10;
    reg [31:0] got_y0,  got_y1,  got_y2;

    // Result registers
    reg syst_done, syst_pass;
    reg mvu_done,  mvu_pass;
    reg fail_latched;
    reg [7:0]  fail_vec_r;
    reg [1:0]  fail_src_r;
    reg [31:0] fail_got_r, fail_exp_r;

    // Which DUTs to test in this run
    reg run_syst, run_mvu;

    // bist_active: high whenever FSM is running (not idle/done) AND mode=BIST
    assign bist_active = mode & (state != S_IDLE) & (state != S_DONE);

    // FSM + register-write logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mode         <= 1'b0;
            state        <= S_IDLE;
            syst_vec     <= 0; mvu_vec    <= 0;
            write_idx    <= 0; wait_cnt   <= 0; read_idx <= 0;
            syst_done    <= 0; syst_pass  <= 1;
            mvu_done     <= 0; mvu_pass   <= 1;
            fail_latched <= 0; fail_vec_r <= 0;
            fail_src_r   <= 0; fail_got_r <= 0; fail_exp_r <= 0;
            run_syst     <= 0; run_mvu    <= 0;
            syst_cs  <= 0; syst_we  <= 0; syst_addr  <= 0; syst_wdata <= 0;
            mvu_cs   <= 0; mvu_we   <= 0; mvu_addr   <= 0; mvu_wdata  <= 0;
            got_c00  <= 0; got_c01  <= 0; got_c10    <= 0;
            got_y0   <= 0; got_y1   <= 0; got_y2     <= 0;
        end else begin

            // Default: drop all bus strobes each cycle
            syst_cs <= 0; syst_we <= 0;
            mvu_cs  <= 0; mvu_we  <= 0;

            // ── CPU writes ──────────────────────────────────────────
            if (cpu_cs && cpu_we) begin
                case (cpu_addr)
                    // Mode: writable any time the FSM is not actively running
                    3'h0: if (!bist_active) mode <= cpu_wdata[0];

                    // Start: only accepted in BIST mode while idle
                    3'h1: if (mode && (state == S_IDLE) && |cpu_wdata[2:0]) begin
                        syst_done    <= 0; syst_pass <= 1;
                        mvu_done     <= 0; mvu_pass  <= 1;
                        fail_latched <= 0;
                        syst_vec     <= 0; mvu_vec   <= 0; write_idx <= 0;
                        run_syst     <= cpu_wdata[0] | cpu_wdata[2];
                        run_mvu      <= cpu_wdata[1] | cpu_wdata[2];
                        if (cpu_wdata[0] | cpu_wdata[2])
                            state <= S_SW_WRITE;
                        else
                            state <= S_MW_WRITE;
                    end

                    default: ;
                endcase
            end

            // ── FSM ─────────────────────────────────────────────────
            case (state)

                S_IDLE: ; // waiting for start

                // ── Systolic: write a0..b3 (8 regs × 1 per cycle) ──
                S_SW_WRITE: begin
                    syst_cs  <= 1;
                    syst_we  <= 1;
                    syst_addr <= 7'h50 + {4'b0, write_idx[2:0]};
                    case (write_idx[2:0])
                        3'd0: syst_wdata <= sv_a0[syst_vec];
                        3'd1: syst_wdata <= sv_a1[syst_vec];
                        3'd2: syst_wdata <= sv_a2[syst_vec];
                        3'd3: syst_wdata <= sv_a3[syst_vec];
                        3'd4: syst_wdata <= sv_b0[syst_vec];
                        3'd5: syst_wdata <= sv_b1[syst_vec];
                        3'd6: syst_wdata <= sv_b2[syst_vec];
                        3'd7: syst_wdata <= sv_b3[syst_vec];
                        default: syst_wdata <= 32'd0;
                    endcase
                    if (write_idx[2:0] == 3'd7) begin
                        write_idx <= 0;
                        state     <= S_SW_START;
                    end else
                        write_idx <= write_idx + 1;
                end

                // ── Systolic: pulse start (addr 0x58) ───────────────
                S_SW_START: begin
                    syst_cs    <= 1;
                    syst_we    <= 1;
                    syst_addr  <= 7'h58;
                    syst_wdata <= 32'd1;
                    wait_cnt   <= 0;
                    state      <= S_SW_WAIT;
                end

                // ── Systolic: wait 2 cycles (pe_macc + done reg) ────
                S_SW_WAIT: begin
                    if (wait_cnt == 2'd1) begin
                        read_idx <= 0;
                        state    <= S_SW_READ;
                    end else
                        wait_cnt <= wait_cnt + 1;
                end

                // ── Systolic: read c00(0x5A)..c11(0x5D) ─────────────
                // Address is presented this cycle; data is valid next cycle.
                // So at read_idx=1 we latch the data that was addressed at
                // read_idx=0, etc.  At read_idx=3 we move to CHECK where
                // syst_rdata holds the last word (c11).
                S_SW_READ: begin
                    syst_cs   <= 1;
                    syst_we   <= 0;
                    syst_addr <= 7'h5A + {5'b0, read_idx};
                    case (read_idx)
                        2'd1: got_c00 <= syst_rdata;
                        2'd2: got_c01 <= syst_rdata;
                        2'd3: got_c10 <= syst_rdata;
                        default: ;
                    endcase
                    if (read_idx == 2'd3)
                        state <= S_SW_CHECK;
                    read_idx <= read_idx + 1;
                end

                // ── Systolic: compare ────────────────────────────────
                S_SW_CHECK: begin
                    // syst_rdata is c11 (last read, one cycle latency)
                    begin : syst_cmp
                        reg        f;
                        reg [31:0] bg, be;
                        f = 0; bg = 0; be = 0;
                        if      (got_c00 !== sv_c00[syst_vec])
                            begin f=1; bg=got_c00;    be=sv_c00[syst_vec]; end
                        else if (got_c01 !== sv_c01[syst_vec])
                            begin f=1; bg=got_c01;    be=sv_c01[syst_vec]; end
                        else if (got_c10 !== sv_c10[syst_vec])
                            begin f=1; bg=got_c10;    be=sv_c10[syst_vec]; end
                        else if (syst_rdata !== sv_c11[syst_vec])
                            begin f=1; bg=syst_rdata; be=sv_c11[syst_vec]; end
                        if (f && !fail_latched) begin
                            fail_latched <= 1;
                            fail_src_r   <= 2'd1;
                            fail_vec_r   <= {5'd0, syst_vec};
                            fail_got_r   <= bg;
                            fail_exp_r   <= be;
                            syst_pass    <= 0;
                        end
                    end

                    if (syst_vec == SYST_N-1) begin
                        syst_done <= 1;
                        syst_vec  <= 0;
                        state     <= run_mvu ? S_MW_WRITE : S_DONE;
                    end else begin
                        syst_vec  <= syst_vec + 1;
                        write_idx <= 0;
                        state     <= S_SW_WRITE;
                    end
                end

                // ── MVU: write x[0..3]+W (20 regs × 1 per cycle) ───
                S_MW_WRITE: begin
                    mvu_cs  <= 1;
                    mvu_we  <= 1;
                    if (write_idx < 5'd4) begin
                        mvu_addr  <= 7'h30 + {2'b0, write_idx[1:0]};
                        case (write_idx[1:0])
                            2'd0: mvu_wdata <= mv_x[mvu_vec][0];
                            2'd1: mvu_wdata <= mv_x[mvu_vec][1];
                            2'd2: mvu_wdata <= mv_x[mvu_vec][2];
                            2'd3: mvu_wdata <= mv_x[mvu_vec][3];
                        endcase
                    end else begin
                        // write_idx 4..19 → w[row][col], row-major
                        // offset = write_idx-4; row=offset[3:2] col=offset[1:0]
                        mvu_addr <= 7'h34 + {2'b0, write_idx - 5'd4};
                        begin : wlookup
                            reg [3:0] ofs;
                            ofs = write_idx[3:0] - 4'd4;
                            mvu_wdata <= mv_w[mvu_vec][ofs[3:2]][ofs[1:0]];
                        end
                    end
                    if (write_idx == 5'd19) begin
                        write_idx <= 0;
                        state     <= S_MW_START;
                    end else
                        write_idx <= write_idx + 1;
                end

                // ── MVU: pulse start (addr 0x44) ─────────────────────
                S_MW_START: begin
                    mvu_cs    <= 1;
                    mvu_we    <= 1;
                    mvu_addr  <= 7'h44;
                    mvu_wdata <= 32'd1;
                    wait_cnt  <= 0;
                    state     <= S_MW_WAIT;
                end

                // ── MVU: wait 2 cycles (pe_macc + vpu sum reg) ───────
                S_MW_WAIT: begin
                    if (wait_cnt == 2'd1) begin
                        read_idx <= 0;
                        state    <= S_MW_READ;
                    end else
                        wait_cnt <= wait_cnt + 1;
                end

                // ── MVU: read y[0](0x46)..y[3](0x49) ────────────────
                S_MW_READ: begin
                    mvu_cs   <= 1;
                    mvu_we   <= 0;
                    mvu_addr <= 7'h46 + {5'b0, read_idx};
                    case (read_idx)
                        2'd1: got_y0 <= mvu_rdata;
                        2'd2: got_y1 <= mvu_rdata;
                        2'd3: got_y2 <= mvu_rdata;
                        default: ;
                    endcase
                    if (read_idx == 2'd3)
                        state <= S_MW_CHECK;
                    read_idx <= read_idx + 1;
                end

                // ── MVU: compare ─────────────────────────────────────
                S_MW_CHECK: begin
                    // mvu_rdata is y[3]
                    begin : mvu_cmp
                        reg        f;
                        reg [31:0] bg, be;
                        f = 0; bg = 0; be = 0;
                        if      (got_y0 !== mv_y[mvu_vec][0])
                            begin f=1; bg=got_y0;    be=mv_y[mvu_vec][0]; end
                        else if (got_y1 !== mv_y[mvu_vec][1])
                            begin f=1; bg=got_y1;    be=mv_y[mvu_vec][1]; end
                        else if (got_y2 !== mv_y[mvu_vec][2])
                            begin f=1; bg=got_y2;    be=mv_y[mvu_vec][2]; end
                        else if (mvu_rdata !== mv_y[mvu_vec][3])
                            begin f=1; bg=mvu_rdata; be=mv_y[mvu_vec][3]; end
                        if (f && !fail_latched) begin
                            fail_latched <= 1;
                            fail_src_r   <= 2'd2;
                            fail_vec_r   <= {6'd0, mvu_vec};
                            fail_got_r   <= bg;
                            fail_exp_r   <= be;
                            mvu_pass     <= 0;
                        end
                    end

                    if (mvu_vec == MVU_N-1) begin
                        mvu_done <= 1;
                        mvu_vec  <= 0;
                        state    <= S_DONE;
                    end else begin
                        mvu_vec   <= mvu_vec + 1;
                        write_idx <= 0;
                        state     <= S_MW_WRITE;
                    end
                end

                S_DONE:  state <= S_IDLE;
                default: state <= S_IDLE;

            endcase
        end
    end

    // CPU MMIO read — combinational
    always @(*) begin
        cpu_rdata = 32'd0;
        if (cpu_cs && !cpu_we) begin
            case (cpu_addr)
                3'h0: cpu_rdata = {31'd0, mode};
                3'h1: cpu_rdata = 32'd0; // start is write-only
                3'h2: cpu_rdata = {27'd0,
                                   mvu_pass,  mvu_done,
                                   syst_pass, syst_done,
                                   bist_active};
                3'h3: cpu_rdata = {22'd0, fail_src_r, fail_vec_r};
                3'h4: cpu_rdata = fail_got_r;
                3'h5: cpu_rdata = fail_exp_r;
                default: cpu_rdata = 32'd0;
            endcase
        end
    end

endmodule