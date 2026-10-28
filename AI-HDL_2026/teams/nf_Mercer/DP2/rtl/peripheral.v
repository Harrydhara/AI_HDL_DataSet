`default_nettype none
// ---------------------------------------------------------------------------
// tqvp_example  –  TinyQV peripheral wrapper
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
    output reg      data_ready,
    output          user_interrupt
);

    // ------------------------------------------------------------------
    // Basic registers
    // ------------------------------------------------------------------
    reg [31:0] example_data;
    reg [63:0] cycle_count;
    reg [7:0]  gpio_out_reg;

    assign uo_out         = gpio_out_reg;
    assign user_interrupt = 1'b0;

    wire write_active = (data_write_n != 2'b11);
    wire read_active  = (data_read_n  != 2'b11);

    // Free-running cycle counter
    always @(posedge clk) begin
        if (!rst_n) cycle_count <= 64'd0;
        else        cycle_count <= cycle_count + 1'b1;
    end

    // ------------------------------------------------------------------
    // Systolic instance
    // Address range 0x50–0x5D; decode on bits [5:4] == 2'b01 covers
    // 0x40–0x5F, which is the full reserved systolic window.
    // Tighten further with: syst_cs = (address[5:4]==2'b01) && (address[3:0]<=4'hD)
    // ------------------------------------------------------------------
    wire        syst_cs = (address[5:4] == 2'b01) && (address[3:0] <= 4'hD);
    wire [31:0] syst_rdata;

    systolic_2x2 u_syst (
        .clk   (clk),
        .rst_n (rst_n),
        .cs    (syst_cs),
        .we    (write_active),
        .addr  (address),
        .wdata (data_in),
        .rdata (syst_rdata)
    );

    // ------------------------------------------------------------------
    // Write logic
    // ------------------------------------------------------------------
    always @(posedge clk) begin
        if (!rst_n) begin
            example_data <= 32'd0;
            gpio_out_reg <= 8'd0;
        end else if (write_active) begin
            case (address)
                6'h00: example_data <= data_in;
                6'h0C: gpio_out_reg <= data_in[7:0];
                default: ;
            endcase
        end
    end

    // ------------------------------------------------------------------
    // Read logic – combinational mux, registered data_ready only
    // ------------------------------------------------------------------
    always @(posedge clk) begin
        if (!rst_n)
            data_ready <= 1'b0;
        else
            data_ready <= read_active;
    end

    always @(*) begin
        if (syst_cs)
            data_out = syst_rdata;
        else begin
            case (address)
                6'h00:  data_out = example_data;
                6'h04:  data_out = cycle_count[31:0];
                6'h08:  data_out = cycle_count[63:32];
                6'h0C:  data_out = {24'h0, gpio_out_reg};
                6'h0E:  data_out = {24'h0, ui_in};
                default: data_out = 32'd0;
            endcase
        end
    end

endmodule