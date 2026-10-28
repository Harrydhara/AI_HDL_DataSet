`default_nettype none
`timescale 1ns/1ps
// =============================================================================
// HARDENED peripheral wrapper
// Security revision: Milestone Review #3
//
// CWE COUNTERMEASURES IMPLEMENTED
// -----------------------------------------------------------------------------
//  CWE-1274 / CWE-284   P1  BIST auth-token gate           [AUTH]
//  CWE-203              P2  Timing-oracle LFSR jitter       [JITTER]
//  CWE-1244 / CWE-1298  P3  MVU weight-lock FF              [WLOCK]
//  CWE-1252             P4  BIST fail-reg masking           [FMASK]
//  CWE-1239             P5  Zeroize on rst_n                [ZERO]
//  CWE-1271             P6  BIST watchdog timeout           [WDT]
//  CWE-1233             P7  gpio/example_data write-lock    [RLOCK]
//  CWE-682              FIX Address port widened [6:0]      [AFIX]
//
// KEY DESIGN NOTE - WDT implementation
//   bist_ctrl.v has no 'cancel' port.  The watchdog is implemented entirely
//   in this wrapper:  bist_active = bist_active_raw & ~wdt_expire
//   WDT expiry cuts the bus mux without modifying bist_ctrl at all.
//
// ADDRESS MAP (7-bit word addresses)
//
//   0x00        W/R  example_data
//   0x04        R    cycle_count[31:0]  (LFSR-jittered low 5 bits)
//   0x08        R    cycle_count[63:32] (LFSR-jittered low 5 bits)
//   0x0C        W/R  gpio_out [7:0]
//   0x0E        R    gpio_in  (ui_in)
//   0x30-0x49   W/R  mvu     (0x34-0x43 blocked while weight_locked)
//   0x50-0x5D   W/R  systolic_2x2
//   0x5E        W    bist_auth_token   write 32'hDEAD_BEEF  [AUTH]
//   0x5F        R    bist_lock_status  [0]=token_ok [1]=bist_active  [AUTH]
//   0x60        W/R  bist mode_reg     [0]=BIST en  (gated on token) [AUTH]
//   0x61        W    bist start        [0]=syst [1]=mvu [2]=both
//   0x62        R    bist status       [4:0]
//   0x63        R    bist fail_info    (0 when !bist_active)  [FMASK]
//   0x64        R    bist fail_got     (0 when !bist_active)  [FMASK]
//   0x65        R    bist fail_exp     (0 when !bist_active)  [FMASK]
//   0x70        W    reg_lock   [0]=lock gpio  [1]=lock example  [RLOCK]
//   0x71        R    reg_lock_status (sticky)  [RLOCK]
//   0x73        W    weight_unlock  write 32'hC0DE_CAFE  [WLOCK]
// =============================================================================

module tqvp_example #(
    parameter [15:0] WDT_LIMIT = 16'hFFFF
) (
    input           clk,
    input           rst_n,
    input  [7:0]    ui_in,
    output [7:0]    uo_out,
    input  [6:0]    address,
    input  [31:0]   data_in,
    input  [1:0]    data_write_n,
    input  [1:0]    data_read_n,
    output reg [31:0] data_out,
    output reg      data_ready,
    output          user_interrupt
);

    wire write_active = (data_write_n != 2'b11);
    wire read_active  = (data_read_n  != 2'b11);

    assign user_interrupt = 1'b0;

    // Forward declarations - all wires driven by bist_ctrl or WDT
    // (declared here so every subsequent always block can reference them)
    wire        bist_active_raw;
    wire        bist_active;        // = bist_active_raw & ~wdt_expire
    wire        bist_syst_cs,  bist_syst_we;
    wire [6:0]  bist_syst_addr;
    wire [31:0] bist_syst_wdata;
    wire        bist_mvu_cs,   bist_mvu_we;
    wire [6:0]  bist_mvu_addr;
    wire [31:0] bist_mvu_wdata;
    wire [31:0] bist_rdata;
    wire [31:0] syst_rdata;
    wire [31:0] mvu_rdata;

    // [WDT] CWE-1271 -- Watchdog implemented entirely in wrapper
    reg [15:0] wdt_count;
    wire       wdt_expire = (wdt_count >= WDT_LIMIT);

    always @(posedge clk) begin
        if (!rst_n)
            wdt_count <= 16'd0;
        else if (!bist_active_raw)
            wdt_count <= 16'd0;
        else if (!wdt_expire)
            wdt_count <= wdt_count + 1'b1;
    end

    assign bist_active = bist_active_raw & ~wdt_expire;

    // [AUTH] CWE-1274 / CWE-284 -- BIST authentication gate
    localparam [31:0] BIST_AUTH_TOKEN    = 32'hDEAD_BEEF;
    localparam [31:0] WEIGHT_UNLOCK_TOKEN = 32'hC0DE_CAFE;

    reg bist_token_ok;

    always @(posedge clk) begin
        if (!rst_n)
            bist_token_ok <= 1'b0;
        else if (write_active && (address == 7'h5E) && (data_in == BIST_AUTH_TOKEN))
            bist_token_ok <= 1'b1;
    end

    // [WLOCK] CWE-1244 / CWE-1298 -- MVU weight-lock FF
    reg weight_locked;

    always @(posedge clk) begin
        if (!rst_n)
            weight_locked <= 1'b0;
        else if (write_active && (address == 7'h44))
            weight_locked <= 1'b1;
        else if (write_active && (address == 7'h73) && (data_in == WEIGHT_UNLOCK_TOKEN))
            weight_locked <= 1'b0;
    end

    // [RLOCK] CWE-1233 -- Sticky write-lock for gpio and example_data
    reg lock_gpio;
    reg lock_example;

    always @(posedge clk) begin
        if (!rst_n) begin
            lock_gpio    <= 1'b0;
            lock_example <= 1'b0;
        end else if (write_active && (address == 7'h70)) begin
            if (data_in[0]) lock_gpio    <= 1'b1;
            if (data_in[1]) lock_example <= 1'b1;
        end
    end

    // [JITTER] CWE-203 -- 5-bit Galois LFSR (taps x^5+x^3+1, period 31)
    reg [4:0] lfsr_state;

    always @(posedge clk) begin
        if (!rst_n)
            lfsr_state <= 5'b10101;
        else
            lfsr_state <= {lfsr_state[0],
                           lfsr_state[4],
                           lfsr_state[3] ^ lfsr_state[0],
                           lfsr_state[2],
                           lfsr_state[1]};
    end

    // Basic registers
    reg [31:0] example_data;
    reg [63:0] cycle_count;
    reg [7:0]  gpio_out_reg;

    assign uo_out = gpio_out_reg;

    always @(posedge clk) begin
        if (!rst_n) cycle_count <= 64'd0;
        else        cycle_count <= cycle_count + 1'b1;
    end

    wire [31:0] jittered_cycle_lo = cycle_count[31:0]  ^ {27'd0, lfsr_state};
    wire [31:0] jittered_cycle_hi = cycle_count[63:32] ^ {27'd0, lfsr_state};

    // Address decode
    wire bist_cs = (address >= 7'h60) && (address <= 7'h65);
    wire sec_cs  = (address == 7'h5E) || (address == 7'h5F)
                || (address == 7'h70) || (address == 7'h71)
                || (address == 7'h73);

    // bist_ctrl instantiation -- no cancel port, WDT handled above
    bist_ctrl u_bist (
        .clk        (clk),
        .rst_n      (rst_n),
        // [AUTH]: writes to 0x60 (cpu_addr=0) dropped unless token is valid
        .cpu_cs     (bist_cs),
        .cpu_we     (write_active && ((address != 7'h60) || bist_token_ok)),
        .cpu_addr   (address[2:0]),
        .cpu_wdata  (data_in),
        .cpu_rdata  (bist_rdata),
        .syst_cs    (bist_syst_cs),
        .syst_we    (bist_syst_we),
        .syst_addr  (bist_syst_addr),
        .syst_wdata (bist_syst_wdata),
        .syst_rdata (syst_rdata),
        .mvu_cs     (bist_mvu_cs),
        .mvu_we     (bist_mvu_we),
        .mvu_addr   (bist_mvu_addr),
        .mvu_wdata  (bist_mvu_wdata),
        .mvu_rdata  (mvu_rdata),
        .bist_active(bist_active_raw)
    );

    // Systolic -- CPU cs gated off while bist_active=1
    wire syst_cs_cpu = !bist_active
                       && (address >= 7'h50)
                       && (address <= 7'h5D);

    systolic_2x2 u_syst (
        .clk   (clk),
        .rst_n (rst_n),
        .cs    (bist_active ? bist_syst_cs    : syst_cs_cpu),
        .we    (bist_active ? bist_syst_we    : write_active),
        .addr  (bist_active ? bist_syst_addr  : address[6:0]),
        .wdata (bist_active ? bist_syst_wdata : data_in),
        .rdata (syst_rdata)
    );

    // MVU -- CPU cs gated off while bist_active=1
    // [WLOCK]: weight writes blocked while weight_locked
    wire mvu_cs_cpu = !bist_active
                      && (address >= 7'h30)
                      && (address <= 7'h49);

    wire is_weight_addr = (address >= 7'h34) && (address <= 7'h43);
    wire mvu_we_cpu     = write_active && !(is_weight_addr && weight_locked);

    mvu u_mvu (
        .clk   (clk),
        .rst_n (rst_n),
        .cs    (bist_active ? bist_mvu_cs    : mvu_cs_cpu),
        .we    (bist_active ? bist_mvu_we    : mvu_we_cpu),
        .addr  (bist_active ? bist_mvu_addr  : address[6:0]),
        .wdata (bist_active ? bist_mvu_wdata : data_in),
        .rdata (mvu_rdata)
    );

    // CPU write logic
    // [RLOCK] gate on lock bits
    // [ZERO]  rst_n branch zeroes both regs (CWE-1239)
    always @(posedge clk) begin
        if (!rst_n) begin
            example_data <= 32'd0;
            gpio_out_reg <= 8'd0;
        end else if (write_active) begin
            case (address)
                7'h00: if (!lock_example) example_data <= data_in;
                7'h0C: if (!lock_gpio)    gpio_out_reg <= data_in[7:0];
                default: ;
            endcase
        end
    end

    // data_ready
    always @(posedge clk) begin
        if (!rst_n) data_ready <= 1'b0;
        else        data_ready <= read_active;
    end

    // [FMASK] CWE-1252 -- Fail registers return 0 outside BIST mode
    wire is_fail_reg = (address >= 7'h63) && (address <= 7'h65);

    // Read mux -- combinational
    always @(*) begin
        if (bist_cs) begin
            data_out = (is_fail_reg && !bist_active) ? 32'd0 : bist_rdata;
        end else if (syst_cs_cpu) begin
            data_out = syst_rdata;
        end else if (mvu_cs_cpu) begin
            data_out = mvu_rdata;
        end else if (sec_cs) begin
            case (address)
                7'h5F:   data_out = {30'd0, bist_active, bist_token_ok};
                7'h71:   data_out = {30'd0, lock_example, lock_gpio};
                default: data_out = 32'd0;
            endcase
        end else begin
            case (address)
                7'h00:   data_out = example_data;
                7'h04:   data_out = jittered_cycle_lo;
                7'h08:   data_out = jittered_cycle_hi;
                7'h0C:   data_out = {24'h0, gpio_out_reg};
                7'h0E:   data_out = {24'h0, ui_in};
                default: data_out = 32'd0;
            endcase
        end
    end

endmodule