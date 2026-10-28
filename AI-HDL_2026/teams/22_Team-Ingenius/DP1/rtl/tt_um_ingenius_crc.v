module tt_um_ingenius_crc (
    input         clk,
    input         rst_n,
    input  [7:0]  ui_in,
    output [7:0]  uo_out,
    input  [5:0]  address,
    input  [31:0] data_in,
    input  [1:0]  data_write_n,
    input  [1:0]  data_read_n,
    output [31:0] data_out,
    output        data_ready,
    output        user_interrupt
);

    // Registers
    reg [31:0] ctrl_reg, status_reg, seed_reg, len_reg, data_reg, result_reg;

    // Datapath interface signals
    reg        crc_start;
    reg        crc_reset;
    wire       crc_busy;
    wire       crc_done;
    wire [31:0] crc_result;
    wire [31:0] crc_data_in;
    wire [31:0] crc_seed;
    wire [15:0] crc_len;

    // CTRL register write with pulse generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ctrl_reg   <= 32'b0;
            crc_start  <= 1'b0;
            crc_reset  <= 1'b0;
        end else begin
            // Latch CTRL register
            if (address == 6'h0 && data_write_n != 2'b11)
                ctrl_reg <= data_in;

            // Generate one-cycle pulses
            crc_start <= (address == 6'h0 && data_write_n != 2'b11 && data_in[0]);
            crc_reset <= (address == 6'h0 && data_write_n != 2'b11 && data_in[1]);
        end
    end

    // SEED register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            seed_reg <= 32'b0;
        else if (address == 6'h8 && data_write_n != 2'b11)
            seed_reg <= data_in;
    end
    assign crc_seed = seed_reg;

    // LEN register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            len_reg <= 32'b0;
        else if (address == 6'hC && data_write_n != 2'b11)
            len_reg <= data_in;
    end
    assign crc_len = len_reg[15:0];

    // DATA register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_reg <= 32'b0;
        else if (address == 6'h10 && data_write_n != 2'b11)
            data_reg <= data_in;
    end
    assign crc_data_in = data_reg;

    // RESULT register updated by datapath
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            result_reg <= 32'b0;
        else if (crc_done)
            result_reg <= crc_result;
    end

    // STATUS register updated by datapath
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            status_reg <= 32'b0;
        else begin
            status_reg[0] <= crc_busy;
            status_reg[1] <= crc_done;
        end
    end

    // Read mux
    assign data_out = (address == 6'h0)  ? ctrl_reg   :
                      (address == 6'h4)  ? status_reg :
                      (address == 6'h8)  ? seed_reg   :
                      (address == 6'hC)  ? len_reg    :
                      (address == 6'h10) ? data_reg   :
                      (address == 6'h14) ? result_reg :
                      32'h0;

    assign data_ready = 1;

    // Interrupt when CRC done
    assign user_interrupt = status_reg[1];

    // Unused signals
    wire _unused = &{data_read_n, 1'b0};

    assign uo_out = 8'h0; // not used for CRC

    // === CRC datapath instantiation ===
    crc_datapath u_crc (
        .clk     (clk),
        .rst_n   (rst_n),
        .start   (crc_start),
        .reset   (crc_reset),
        .seed    (crc_seed),
        .len     (crc_len),
        .data_in (crc_data_in),
        .busy    (crc_busy),
        .done    (crc_done),
        .result  (crc_result)
    );

    // === Dummy signals to satisfy cocotb test harness ===
    wire [3:0] qspi_data_in     = 4'b0;
    wire [3:0] qspi_data_out    = 4'b0;
    wire       qspi_clk         = 1'b0;
    wire       qspi_clk_out     = 1'b0;
    wire       qspi_cs          = 1'b1;
    wire       qspi_flash_select = 1'b0;
    wire       ena              = 1'b1;

endmodule