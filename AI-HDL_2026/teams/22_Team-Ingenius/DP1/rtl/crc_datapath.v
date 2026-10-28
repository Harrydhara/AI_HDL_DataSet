
module crc_datapath (
    input         clk,
    input         rst_n,
    input         start,
    input         reset,
    input  [31:0] seed,
    input  [15:0] len,
    input  [31:0] data_in,
    output reg    busy,
    output reg    done,
    output reg [31:0] result
);

    reg [31:0] crc_reg;
    reg [15:0] counter;

    // Polynomial for CRC-32 (IEEE 802.3)
    localparam POLY = 32'h04C11DB7;

    // Detect rising edge of start
    reg start_d;
    wire start_pulse = start & ~start_d;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            start_d <= 1'b0;
        else
            start_d <= start;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_reg  <= 32'b0;
            result   <= 32'b0;
            busy     <= 1'b0;
            done     <= 1'b0;
            counter  <= 16'b0;
        end else if (start_pulse) begin
            // Start overrides reset, only once per rising edge
            busy     <= 1'b1;
            done     <= 1'b0;
            counter  <= len;
            crc_reg  <= seed ^ data_in; // initial mix
        end else if (reset) begin
            // Reset only if start is not active
            crc_reg  <= seed;
            result   <= 32'b0;
            busy     <= 1'b0;
            done     <= 1'b0;
            counter  <= 16'b0;
        end else if (busy) begin
            if (counter != 0) begin
                if (crc_reg[31])
                    crc_reg <= (crc_reg << 1) ^ POLY;
                else
                    crc_reg <= (crc_reg << 1);
                counter <= counter - 1; // decrement until zero
            end else begin
                busy   <= 1'b0;
                done   <= 1'b1;
                result <= crc_reg;
            end
        end
    end

endmodule
