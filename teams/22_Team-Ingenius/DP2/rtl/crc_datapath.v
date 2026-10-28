module crc_datapath (
    input         clk,
    input         rst_n,
    input         start,
    input         reset,
    input  [31:0] seed,
    input  [15:0] len,        // number of 32-bit words to process
    input  [31:0] data_in,    // new word loaded when requested
    output reg    busy,
    output reg    done,
    output reg [31:0] result
);

    // Polynomial for CRC-32 (IEEE 802.3)
    localparam [31:0] POLY = 32'h04C11DB7;

    // FSM states
    localparam IDLE  = 2'b00;
    localparam LOAD  = 2'b01;   // load new word and start shifting
    localparam SHIFT = 2'b10;   // bit-serial shift processing
    localparam DONE  = 2'b11;

    reg [1:0] state, next_state;

    // Internal registers
    reg [31:0] crc_reg;
    reg [31:0] crc_mid;         // pipeline register stage 2
    reg [31:0] data_reg;        // holds current word being shifted
    reg        msb_stage;       // NEW pipeline register stage 1
    reg [31:0] shift_stage;     // NEW pipeline register stage 1
    reg [5:0]  bit_cnt;         // 0..31
    reg [15:0] word_cnt;        // counts remaining words

    // Start pulse detection (single-cycle)
    reg start_d;
    wire start_pulse = start & ~start_d;

    // Minimal combinational next-bit logic
    wire data_bit = data_reg[31]; // MSB first
    wire msb_xor = crc_reg[31] ^ data_bit;
    wire [31:0] crc_shift = {crc_reg[30:0], 1'b0};
    wire [31:0] crc_next = msb_stage ? (shift_stage ^ POLY) : shift_stage;

    // FSM sequential
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state       <= IDLE;
            start_d     <= 1'b0;
            crc_reg     <= 32'h0;
            crc_mid     <= 32'h0;
            data_reg    <= 32'h0;
            msb_stage   <= 1'b0;
            shift_stage <= 32'h0;
            bit_cnt     <= 6'd0;
            word_cnt    <= 16'd0;
            busy        <= 1'b0;
            done        <= 1'b0;
            result      <= 32'h0;
        end else begin
            start_d <= start;
            state   <= next_state;

            // state actions
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    if (start_pulse) begin
                        busy        <= 1'b1;
                        word_cnt    <= len;
                        crc_reg     <= seed;
                        crc_mid     <= seed;
                        msb_stage   <= 1'b0;
                        shift_stage <= 32'h0;
                        data_reg    <= data_in;
                        bit_cnt     <= 6'd32;
                    end
                end

                LOAD: begin
                    bit_cnt <= 6'd32;
                end

                SHIFT: begin
                    // stage 1 pipeline: capture XOR and shift
                    msb_stage   <= msb_xor;
                    shift_stage <= crc_shift;

                    // stage 2 pipeline: compute next CRC
                    crc_mid <= crc_next;
                    crc_reg <= crc_mid;

                    // shift data register and decrement bit counter
                    data_reg <= {data_reg[30:0], 1'b0};
                    bit_cnt  <= bit_cnt - 1'b1;
                end

                DONE: begin
                    busy   <= 1'b0;
                    done   <= 1'b1;
                    result <= crc_reg;
                end
            endcase
        end
    end

    // FSM combinational next state logic
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (start_pulse && len != 0)
                    next_state = LOAD;
            end

            LOAD: begin
                next_state = SHIFT;
            end

            SHIFT: begin
                if (bit_cnt == 1) begin
                    if (word_cnt > 1)
                        next_state = LOAD;
                    else
                        next_state = DONE;
                end else begin
                    next_state = SHIFT;
                end
            end

            DONE: begin
                if (start_pulse)
                    next_state = LOAD;
                else
                    next_state = DONE;
            end

            default: next_state = IDLE;
        endcase
    end

endmodule
