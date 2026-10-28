`default_nettype none
// ---------------------------------------------------------------------------
//
// Address map (6-bit word addresses, all fit in [5:0], max 0x37 = 55):
//
// ---------------------------------------------------------------------------

module tqvp_example (
    input           clk,
    input           rst_n,
    input  [7:0]    ui_in,
    output [7:0]    uo_out,
    input  [5:0]    address,
    input  [31:0]   data_in,
    input  [1:0]    data_write_n,
    input  [1:0]    data_read_n,
    output reg [31:0] data_out,
    output reg        data_ready,
    output            user_interrupt
);

    // -----------------------------------------------------------------------
    // Basic registers
    // -----------------------------------------------------------------------
    reg [31:0] example_data;
    reg [63:0] cycle_count;
    reg [7:0]  gpio_out_reg;

    assign uo_out         = gpio_out_reg;
    assign user_interrupt = 1'b0;

    wire we = (data_write_n != 2'b11);

    // 64-bit cycle counter (free-running)
    always @(posedge clk) begin
        if (!rst_n) cycle_count <= 64'd0;
        else        cycle_count <= cycle_count + 1'b1;
    end

    // -----------------------------------------------------------------------
    // MVU instance
    //   Peripheral address range : 0x10 – 0x29
    //   MVU internal address     : 0x30 – 0x49  (offset +0x20)
    // -----------------------------------------------------------------------
    wire        mvu_cs   = (address >= 6'h10) && (address <= 6'h29);
    wire [6:0]  mvu_addr = {1'b0, address} + 7'h20;
    wire [31:0] mvu_rdata;

    mvu u_mvu (
        .clk   (clk),
        .rst_n (rst_n),
        .cs    (mvu_cs),
        .we    (we),
        .addr  (mvu_addr),
        .wdata (data_in),
        .rdata (mvu_rdata)
    );

    // -----------------------------------------------------------------------
    // Systolic 2x2 instance
    //   Peripheral address range : 0x2A – 0x37
    //   Systolic internal address: 0x50 – 0x5D  (offset +0x26)
    // -----------------------------------------------------------------------
    wire        syst_cs   = (address >= 6'h2A) && (address <= 6'h37);
    wire [5:0]  syst_addr = address + 6'h26;   // wraps into 0x50–0x5D as [5:0]
    wire [31:0] syst_rdata;

    systolic_2x2 u_syst (
        .clk   (clk),
        .rst_n (rst_n),
        .cs    (syst_cs),
        .we    (we),
        .addr  (syst_addr),
        .wdata (data_in),
        .rdata (syst_rdata)
    );

    // -----------------------------------------------------------------------
    // Write logic
    // -----------------------------------------------------------------------
    always @(posedge clk) begin
        if (!rst_n) begin
            example_data <= 32'd0;
            gpio_out_reg <= 8'd0;
        end else if (we) begin
            case (address)
                6'h00: example_data <= data_in;
                6'h0C: gpio_out_reg <= data_in[7:0];
                default: ;
            endcase
        end
    end

    // -----------------------------------------------------------------------
    // Read logic — registered output
    // Priority: exact matches before wildcard ranges (casez top-to-bottom)
    // -----------------------------------------------------------------------
    always @(posedge clk) begin
        if (!rst_n) begin
            data_out   <= 32'd0;
            data_ready <= 1'b0;
        end else begin
            data_ready <= (data_read_n != 2'b11);

            casez (address)
                // Basic registers
                6'h00: data_out <= example_data;
                6'h04: data_out <= cycle_count[31:0];
                6'h08: data_out <= cycle_count[63:32];
                6'h0C: data_out <= {24'h0, gpio_out_reg};
                6'h0E: data_out <= {24'h0, ui_in};

                // MVU block: 0x10–0x29
                6'h10, 6'h11, 6'h12, 6'h13,
                6'h14, 6'h15, 6'h16, 6'h17,
                6'h18, 6'h19, 6'h1A, 6'h1B,
                6'h1C, 6'h1D, 6'h1E, 6'h1F,
                6'h20, 6'h21, 6'h22, 6'h23,
                6'h24, 6'h25, 6'h26, 6'h27,
                6'h28, 6'h29:
                    data_out <= mvu_rdata;

                // Systolic block: 0x2A–0x37
                6'h2A, 6'h2B, 6'h2C, 6'h2D,
                6'h2E, 6'h2F, 6'h30, 6'h31,
                6'h32, 6'h33, 6'h34, 6'h35,
                6'h36, 6'h37:
                    data_out <= syst_rdata;

                default:
                    data_out <= 32'h0;
            endcase
        end
    end

endmodule