// Copyright (c) 2021 Ben Marshall
// Changes Copyright (c) 2023-2025 Michael Bell
// MIT License

// 
// Module: uart_rx 
// 
// Notes:
// - UART reciever module.
//

`default_nettype none

module tqvp_uart_rx #(parameter 
    COUNT_REG_LEN = 13,        // Enough to allow baud rates down to 9600 at 64MHz clock
    PAYLOAD_BITS = 8,          // Number of data bits recieved per UART packet.
    STOP_BITS    = 1           // Number of stop bits indicating the end of a packet.
) (
    input  wire        clk,          // Top level system clock input.
    input  wire        resetn,       // Asynchronous active low reset.
    input  wire        uart_rxd,     // UART Recieve pin.
    output reg         uart_rts,     // UART Request to send pin.
    input  wire        uart_rx_read, // Available byte has been read and can be cleared.
    output wire        uart_rx_valid,// Valid data recieved and available.
    output wire [PAYLOAD_BITS-1:0]  uart_rx_data, // The recieved data.
    input  wire [COUNT_REG_LEN-1:0] baud_divider  // The divider for the required baud rate
);
    // -------------------------------------------------------------------------- 
    // Internal registers.
    // 

    //
    // Storage for the recieved serial data.
    reg [PAYLOAD_BITS-1:0] recieved_data;
    //
    // Counter for the number of cycles over a packet bit.
    reg [COUNT_REG_LEN-1:0] cycle_counter;
    //
    // Sample of the UART input line whenever we are in the middle of a bit frame.
    reg bit_sample;
    //
    // Current and next states of the internal FSM.
    reg [3:0] fsm_state;
    reg [3:0] fsm_next; // FIX: Added wire/reg for next state logic

    localparam FSM_IDLE = 4'd0;
    localparam FSM_START = 4'd1;
    localparam FSM_RECV = 4'd2;
    localparam FSM_STOP = 4'd2 + PAYLOAD_BITS;
    localparam FSM_READY = FSM_STOP + STOP_BITS;
    // --------------------------------------------------------------------------- 
    // Output assignment
    // 

    assign uart_rx_valid = fsm_state == FSM_READY;
    assign uart_rx_data = recieved_data;
    // --------------------------------------------------------------------------- 
    // FSM next state selection.
    // 

    wire next_bit     = cycle_counter >= baud_divider;
    wire mid_bit      = cycle_counter == baud_divider >> 1;

    //
    // Handle picking the next state.
    // FIX: Replaced illegal 0-argument function with a combinational always block.
    always @* begin
        case(fsm_state)
            FSM_IDLE : fsm_next = uart_rxd  ? FSM_IDLE  : FSM_START;
            
            // Only go STOP -> READY on a valid STOP bit.
            FSM_STOP : fsm_next = mid_bit     ? (uart_rxd ? FSM_READY : FSM_IDLE) : FSM_STOP;
            FSM_READY: fsm_next = uart_rx_read? FSM_IDLE  : FSM_READY;

            default  : fsm_next = next_bit    ? fsm_state + 1 : fsm_state;
        endcase
    end

    // --------------------------------------------------------------------------- 
    // Internal register setting and re-setting.
    // 

    //
    // Handle updates to the recieved data register.
    always @(posedge clk) begin : p_recieved_data
        if(fsm_state >= FSM_RECV && fsm_state < FSM_STOP && next_bit ) begin
            recieved_data <= {bit_sample, recieved_data[PAYLOAD_BITS-1:1]};
        end
    end

    //
    // Sample the recieved bit when in the middle of a bit frame.
    // FIX: Added 'or negedge resetn' for correct asynchronous reset behavior.
    always @(posedge clk or negedge resetn) begin : p_bit_sample
        if(!resetn) begin
            bit_sample <= 1'b0;
        end else if (mid_bit) begin
            bit_sample <= uart_rxd;
        end
    end


    //
    // Increments the cycle counter when recieving.
    // FIX: Added 'or negedge resetn' for correct asynchronous reset behavior.
    always @(posedge clk or negedge resetn) begin : p_cycle_counter
        if(!resetn) begin
            cycle_counter <= {COUNT_REG_LEN{1'b0}};
        end else if(next_bit || fsm_state == FSM_IDLE || fsm_state == FSM_READY) begin
            cycle_counter <= {COUNT_REG_LEN{1'b0}};
        end else begin
            cycle_counter <= cycle_counter + 1'b1;
        end
    end


    //
    // Progresses the next FSM state.
    // FIX: Added 'or negedge resetn' for correct asynchronous reset behavior.
    always @(posedge clk or negedge resetn) begin : p_fsm_state
        if(!resetn) begin
            fsm_state <= FSM_IDLE;
        end else begin
            // FIX: Assigning from the combinational signal instead of function call
            fsm_state <= fsm_next;
        end
    end

    // Sets RTS
    // FIX: Added 'or negedge resetn' for correct asynchronous reset behavior.
    always @(posedge clk or negedge resetn) begin : p_rts
        if (!resetn) begin
            uart_rts <= 1'b1;
        end else begin
            // RTS is active low, 0 when IDLE or START, or when read is asserted.
            uart_rts <= fsm_state > FSM_START && !uart_rx_read;  
        end
    end

endmodule