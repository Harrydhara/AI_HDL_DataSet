/*
 * TinyQV DMA Controller
 *
 * A simple DMA controller that can transfer data between memory locations
 * without modifying the original TinyQV CPU design.
 *
 * Register Map (cfg_addr):
 *   0x0: SRC_ADDR  - Source address (28-bit)
 *   0x1: DST_ADDR  - Destination address (28-bit)
 *   0x2: COUNT     - Transfer count (number of transfers)
 *   0x3: CTRL      - Control register
 *         bit[0]   : START - Write 1 to start transfer
 *         bit[1]   : BUSY  - Read-only, 1 when transfer in progress
 *         bit[2]   : DONE  - Read-only, 1 when transfer complete (write 1 to clear)
 *         bit[3]   : IE    - Interrupt enable
 *         bit[5:4] : SIZE  - Transfer size (00=8-bit, 01=16-bit, 10=32-bit)
 *   0x4: STATUS    - Status register (read-only)
 *         bit[15:0]: Remaining transfer count
 *
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tinyqv_dma (
    input  wire        clk,
    input  wire        rstn,

    // Configuration interface (directly from CPU peripheral bus)
    input  wire        cfg_write,
    input  wire        cfg_read,
    input  wire [3:0]  cfg_addr,
    input  wire [31:0] cfg_data_in,
    output reg  [31:0] cfg_data_out,

    // DMA bus master interface
    output reg  [27:0] dma_addr,
    output reg  [1:0]  dma_write_n,
    output reg  [1:0]  dma_read_n,
    output reg  [31:0] dma_data_out,
    input  wire [31:0] dma_data_in,
    input  wire        dma_ready,

    // Bus arbitration
    output wire        dma_request,
    input  wire        dma_grant,

    // Interrupt output
    output wire        dma_interrupt
);

    // Register addresses
    localparam REG_SRC_ADDR  = 4'h0;
    localparam REG_DST_ADDR  = 4'h1;
    localparam REG_COUNT     = 4'h2;
    localparam REG_CTRL      = 4'h3;
    localparam REG_STATUS    = 4'h4;

    // Control register bits
    localparam CTRL_START = 0;
    localparam CTRL_BUSY  = 1;
    localparam CTRL_DONE  = 2;
    localparam CTRL_IE    = 3;
    // SIZE is bits [5:4]

    // DMA state machine
    localparam STATE_IDLE       = 3'd0;
    localparam STATE_REQ_READ   = 3'd1;
    localparam STATE_WAIT_READ  = 3'd2;
    localparam STATE_REQ_WRITE  = 3'd3;
    localparam STATE_WAIT_WRITE = 3'd4;
    localparam STATE_NEXT       = 3'd5;
    localparam STATE_DONE       = 3'd6;

    // Internal registers
    reg [27:0] src_addr;
    reg [27:0] dst_addr;
    reg [15:0] count;
    reg [15:0] remaining;
    reg [5:0]  ctrl_reg;   // START, BUSY, DONE, IE, SIZE[1:0]
    reg [31:0] data_buffer;

    // State machine
    reg [2:0] state;
    reg [2:0] next_state;

    // Transfer size encoding (same as TinyQV bus)
    wire [1:0] xfer_size = ctrl_reg[5:4];

    // Address increment based on transfer size
    wire [3:0] addr_inc = (xfer_size == 2'b00) ? 4'd1 :  // 8-bit
                          (xfer_size == 2'b01) ? 4'd2 :  // 16-bit
                          4'd4;                          // 32-bit

    // Bus request when we need the bus
    assign dma_request = (state == STATE_REQ_READ)  || (state == STATE_WAIT_READ) ||
                         (state == STATE_REQ_WRITE) || (state == STATE_WAIT_WRITE);

    // Interrupt when done and interrupt enabled
    assign dma_interrupt = ctrl_reg[CTRL_DONE] && ctrl_reg[CTRL_IE];

    // Configuration read
    always @(*) begin
        case (cfg_addr)
            REG_SRC_ADDR: cfg_data_out = {4'b0, src_addr};
            REG_DST_ADDR: cfg_data_out = {4'b0, dst_addr};
            REG_COUNT:    cfg_data_out = {16'b0, count};
            REG_CTRL:     cfg_data_out = {26'b0, ctrl_reg};
            REG_STATUS:   cfg_data_out = {16'b0, remaining};
            default:      cfg_data_out = 32'h0;
        endcase
    end

    // Configuration write
    always @(posedge clk) begin
        if (!rstn) begin
            src_addr <= 28'b0;
            dst_addr <= 28'b0;
            count    <= 16'b0;
            ctrl_reg <= 6'b0;
        end else if (cfg_write) begin
            case (cfg_addr)
                REG_SRC_ADDR: src_addr <= cfg_data_in[27:0];
                REG_DST_ADDR: dst_addr <= cfg_data_in[27:0];
                REG_COUNT:    count    <= cfg_data_in[15:0];
                REG_CTRL: begin
                    // START bit: only set if not busy
                    if (cfg_data_in[CTRL_START] && !ctrl_reg[CTRL_BUSY]) begin
                        ctrl_reg[CTRL_START] <= 1'b1;
                    end
                    // DONE bit: write 1 to clear
                    if (cfg_data_in[CTRL_DONE]) begin
                        ctrl_reg[CTRL_DONE] <= 1'b0;
                    end
                    // IE and SIZE can always be written
                    ctrl_reg[CTRL_IE]  <= cfg_data_in[CTRL_IE];
                    ctrl_reg[5:4]      <= cfg_data_in[5:4];
                end
            endcase
        end else begin
            // Clear START bit after state machine picks it up
            if (state == STATE_REQ_READ && ctrl_reg[CTRL_START]) begin
                ctrl_reg[CTRL_START] <= 1'b0;
            end
            // Set BUSY when transfer starts
            if (state == STATE_IDLE && ctrl_reg[CTRL_START]) begin
                ctrl_reg[CTRL_BUSY] <= 1'b1;
            end
            // Clear BUSY and set DONE when transfer completes
            if (state == STATE_DONE) begin
                ctrl_reg[CTRL_BUSY] <= 1'b0;
                ctrl_reg[CTRL_DONE] <= 1'b1;
            end
        end
    end

    // State machine - sequential
    always @(posedge clk) begin
        if (!rstn) begin
            state <= STATE_IDLE;
        end else begin
            state <= next_state;
        end
    end

    // State machine - combinational
    always @(*) begin
        next_state = state;

        case (state)
            STATE_IDLE: begin
                if (ctrl_reg[CTRL_START]) begin
                    next_state = STATE_REQ_READ;
                end
            end

            STATE_REQ_READ: begin
                if (dma_grant) begin
                    next_state = STATE_WAIT_READ;
                end
            end

            STATE_WAIT_READ: begin
                if (dma_ready) begin
                    next_state = STATE_REQ_WRITE;
                end
            end

            STATE_REQ_WRITE: begin
                if (dma_grant) begin
                    next_state = STATE_WAIT_WRITE;
                end
            end

            STATE_WAIT_WRITE: begin
                if (dma_ready) begin
                    next_state = STATE_NEXT;
                end
            end

            STATE_NEXT: begin
                if (remaining == 16'd0) begin
                    next_state = STATE_DONE;
                end else begin
                    next_state = STATE_REQ_READ;
                end
            end

            STATE_DONE: begin
                next_state = STATE_IDLE;
            end

            default: next_state = STATE_IDLE;
        endcase
    end

    // Data path control
    reg [27:0] current_src;
    reg [27:0] current_dst;

    always @(posedge clk) begin
        if (!rstn) begin
            current_src <= 28'b0;
            current_dst <= 28'b0;
            remaining   <= 16'b0;
            data_buffer <= 32'b0;
            dma_addr    <= 28'b0;
            dma_write_n <= 2'b11;
            dma_read_n  <= 2'b11;
            dma_data_out <= 32'b0;
        end else begin
            case (state)
                STATE_IDLE: begin
                    dma_write_n <= 2'b11;
                    dma_read_n  <= 2'b11;
                    if (ctrl_reg[CTRL_START]) begin
                        current_src <= src_addr;
                        current_dst <= dst_addr;
                        remaining   <= count;
                    end
                end

                STATE_REQ_READ: begin
                    dma_addr   <= current_src;
                    dma_read_n <= xfer_size;  // 00=8-bit, 01=16-bit, 10=32-bit
                    dma_write_n <= 2'b11;
                end

                STATE_WAIT_READ: begin
                    if (dma_ready) begin
                        data_buffer <= dma_data_in;
                        dma_read_n  <= 2'b11;
                    end
                end

                STATE_REQ_WRITE: begin
                    dma_addr     <= current_dst;
                    dma_write_n  <= xfer_size;
                    dma_read_n   <= 2'b11;
                    dma_data_out <= data_buffer;
                end

                STATE_WAIT_WRITE: begin
                    if (dma_ready) begin
                        dma_write_n <= 2'b11;
                        current_src <= current_src + {24'b0, addr_inc};
                        current_dst <= current_dst + {24'b0, addr_inc};
                        remaining   <= remaining - 16'd1;
                    end
                end

                STATE_NEXT: begin
                    dma_write_n <= 2'b11;
                    dma_read_n  <= 2'b11;
                end

                STATE_DONE: begin
                    dma_write_n <= 2'b11;
                    dma_read_n  <= 2'b11;
                end
            endcase
        end
    end

endmodule
