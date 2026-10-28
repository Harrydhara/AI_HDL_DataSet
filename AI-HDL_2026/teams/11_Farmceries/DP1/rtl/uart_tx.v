`default_nettype none

/**
 * UART Transmitter
 * 
 * Converts parallel data to serial output (LSB first).
 * Uses FSM with 4 states: IDLE, START, DATA, STOP
 * 
 * Frame format: 1 start bit (0), 8 data bits (LSB first), 1 stop bit (1)
 * 
 * Timing: All state transitions occur on baud_tick pulses
 * 
 * Example transmission of 0x41 ('A' = 0b01000001):
 *   Wire: 1(idle) → 0(start) → 1→0→0→0→0→0→1→0(data) → 1(stop) → 1(idle)
 *         D0=1, D1=0, D2=0, D3=0, D4=0, D5=0, D6=1, D7=0
 */
module uart_tx (
    input  wire       clk,         // System clock
    input  wire       rst_n,       // Active-low reset
    input  wire       baud_tick,   // Baud rate tick from generator
    input  wire [7:0] tx_data,     // Data to transmit
    input  wire       tx_start,    // Start transmission (1-cycle pulse)
    output reg        tx_out,      // Serial output
    output reg        tx_busy      // 1 = transmitting, 0 = idle
);

    // FSM states
    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;
    
    reg [1:0] state;
    reg [1:0] next_state;
    
    // Shift register for data bits
    reg [7:0] shift_reg;
    
    // Bit counter (0-7 for 8 data bits)
    reg [2:0] bit_cnt;
    
    // Sample counter for 16x oversampling (0-15)
    reg [3:0] sample_cnt;
    
    // State register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
        end else if (tx_start || baud_tick) begin
            state <= next_state;
        end
    end
    
    // Next state logic
    always @(*) begin
        next_state = state;  // Default: stay in current state
        
        case (state)
            IDLE: begin
                if (tx_start)
                    next_state = START;
            end
            
            START: begin
                if (baud_tick && sample_cnt == 4'd15)
                    next_state = DATA;
            end
            
            DATA: begin
                if (baud_tick && sample_cnt == 4'd15 && bit_cnt == 3'd7)
                    next_state = STOP;
            end
            
            STOP: begin
                if (baud_tick && sample_cnt == 4'd15)
                    next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // Shift register and bit counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg  <= 8'h00;
            bit_cnt    <= 3'd0;
            sample_cnt <= 4'd0;
        end else begin
            case (state)
                IDLE: begin
                    if (tx_start) begin
                        shift_reg  <= tx_data;  // Load data
                        bit_cnt    <= 3'd0;
                        sample_cnt <= 4'd0;
                    end
                end
                
                START: begin
                    if (baud_tick) begin
                        if (sample_cnt == 4'd15) begin
                            sample_cnt <= 4'd0;
                        end else begin
                            sample_cnt <= sample_cnt + 4'd1;
                        end
                    end
                end
                
                DATA: begin
                    if (baud_tick) begin
                        if (sample_cnt == 4'd15) begin
                            shift_reg  <= {1'b0, shift_reg[7:1]};  // Shift right
                            bit_cnt    <= bit_cnt + 1;
                            sample_cnt <= 4'd0;
                        end else begin
                            sample_cnt <= sample_cnt + 4'd1;
                        end
                    end
                end
                
                STOP: begin
                    if (baud_tick) begin
                        if (sample_cnt == 4'd15) begin
                            sample_cnt <= 4'd0;
                        end else begin
                            sample_cnt <= sample_cnt + 4'd1;
                        end
                    end
                end
                
                default: begin
                    shift_reg  <= 8'h00;
                    bit_cnt    <= 3'd0;
                    sample_cnt <= 4'd0;
                end
            endcase
        end
    end
    
    // Output logic
    always @(*) begin
        case (state)
            IDLE:    tx_out = 1'b1;           // Idle high
            START:   tx_out = 1'b0;           // Start bit = 0
            DATA:    tx_out = shift_reg[0];   // LSB first
            STOP:    tx_out = 1'b1;           // Stop bit = 1
            default: tx_out = 1'b1;
        endcase
    end
    
    // Busy flag
    always @(*) begin
        tx_busy = (state != IDLE);
    end

endmodule

`default_nettype wire
