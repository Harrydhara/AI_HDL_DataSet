//============================================================================
// Module: aes_control_fsm
// Description: AES Control Finite State Machine
//              Orchestrates the AES encryption/decryption operations
//
// Features:
//   - Controls key expansion sequencing
//   - Manages encryption/decryption round progression
//   - Coordinates data flow between modules
//   - Generates status signals (busy, done, error)
//
// State Flow:
//   IDLE → KEY_WAIT (if key not valid) → INIT_ROUND (1 cycle) → 
//   MAIN_ROUND (9 cycles) → FINAL_ROUND (1 cycle) → OUTPUT → DONE → IDLE
//
// Round Progression:
//   - INIT_ROUND: Round 0 (Initial AddRoundKey)
//   - MAIN_ROUND: Rounds 1-9 (SubBytes, ShiftRows, MixColumns, AddRoundKey)
//   - FINAL_ROUND: Round 10 (SubBytes, ShiftRows, AddRoundKey - no MixColumns)
//
// Author: AIHDL 2026 Competition Team
// Date: January 2026
// Target: TinyQV RISC-V Peripheral (64MHz)
//============================================================================

module aes_control_fsm (
    input  wire         clk,            // System clock
    input  wire         rst_n,          // Active-low reset
    
    // Control Inputs
    input  wire         start,          // Start operation trigger
    input  wire         decrypt,        // Mode: 0=encrypt, 1=decrypt
    input  wire         key_valid,      // Key expansion complete
    input  wire         key_busy,       // Key expansion in progress
    
    // Control Outputs
    output reg          key_start,      // Trigger key expansion
    output reg  [3:0]   round_count,    // Current round number (0-10)
    output reg          round_init,     // Initial AddRoundKey phase
    output reg          round_main,     // Main round processing phase
    output reg          round_final,    // Final round (no MixColumns)
    output reg          state_load,     // Load new state into datapath
    output reg          state_update,   // Update state with round result
    output reg          output_valid,   // Output data valid
    
    // Status Outputs
    output reg          busy,           // Operation in progress
    output reg          done,           // Operation complete (pulse)
    output reg          error           // Error condition
);

    //------------------------------------------------------------------------
    // FSM State Encoding
    //------------------------------------------------------------------------
    localparam [3:0] FSM_IDLE        = 4'd0;   // Waiting for start
    localparam [3:0] FSM_KEY_WAIT    = 4'd1;   // Waiting for key expansion
    localparam [3:0] FSM_INIT_ROUND  = 4'd2;   // Initial AddRoundKey (Round 0)
    localparam [3:0] FSM_MAIN_ROUND  = 4'd3;   // Main rounds 1-9
    localparam [3:0] FSM_FINAL_ROUND = 4'd4;   // Final round 10
    localparam [3:0] FSM_OUTPUT      = 4'd5;   // Output result
    localparam [3:0] FSM_DONE        = 4'd6;   // Signal completion
    localparam [3:0] FSM_ERROR       = 4'd7;   // Error state

    //------------------------------------------------------------------------
    // Internal Registers
    //------------------------------------------------------------------------
    reg [3:0] state_reg;                // Current FSM state
    reg [3:0] round_counter;            // Internal round counter (1-9 for main)
    reg       decrypt_reg;              // Latched decrypt mode

    //------------------------------------------------------------------------
    // Round Number Calculation (Combinational)
    // Encryption: round_count = round_counter (0, 1, 2, ..., 10)
    // Decryption: round_count = 10 - round_counter (10, 9, 8, ..., 0)
    //------------------------------------------------------------------------
    always @(*) begin
        if (decrypt_reg) begin
            round_count = 4'd10 - round_counter;
        end
        else begin
            round_count = round_counter;
        end
    end

    //------------------------------------------------------------------------
    // FSM Sequential Logic - State and Outputs
    //------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset state
            state_reg     <= FSM_IDLE;
            round_counter <= 4'd0;
            decrypt_reg   <= 1'b0;
            
            // Reset all outputs
            key_start     <= 1'b0;
            round_init    <= 1'b0;
            round_main    <= 1'b0;
            round_final   <= 1'b0;
            state_load    <= 1'b0;
            state_update  <= 1'b0;
            output_valid  <= 1'b0;
            busy          <= 1'b0;
            done          <= 1'b0;
            error         <= 1'b0;
        end
        else begin
            // Default: Clear single-cycle pulse signals
            key_start    <= 1'b0;
            state_load   <= 1'b0;
            state_update <= 1'b0;
            done         <= 1'b0;
            round_init   <= 1'b0;
            round_main   <= 1'b0;
            round_final  <= 1'b0;
            
            case (state_reg)
                //------------------------------------------------------------
                // IDLE: Wait for start, prepare for operation
                //------------------------------------------------------------
                FSM_IDLE: begin
                    busy         <= 1'b0;
                    error        <= 1'b0;
                    output_valid <= 1'b0;
                    round_counter <= 4'd0;
                    
                    if (start) begin
                        // Latch decrypt mode
                        decrypt_reg <= decrypt;
                        busy <= 1'b1;
                        
                        if (key_valid) begin
                            // Key ready - go to INIT_ROUND and set outputs
                            state_reg    <= FSM_INIT_ROUND;
                            round_init   <= 1'b1;
                            state_load   <= 1'b1;
                            round_counter <= 4'd0;
                        end
                        else begin
                            // Need key expansion
                            state_reg <= FSM_KEY_WAIT;
                            key_start <= 1'b1;
                        end
                    end
                end
                
                //------------------------------------------------------------
                // KEY_WAIT: Wait for key expansion to complete
                //------------------------------------------------------------
                FSM_KEY_WAIT: begin
                    busy <= 1'b1;
                    
                    if (key_valid) begin
                        // Key ready - go to INIT_ROUND
                        state_reg    <= FSM_INIT_ROUND;
                        round_init   <= 1'b1;
                        state_load   <= 1'b1;
                        round_counter <= 4'd0;
                    end
                    else if (!key_busy && !key_valid) begin
                        // Error: key not expanding and not valid
                        state_reg <= FSM_ERROR;
                        error     <= 1'b1;
                        busy      <= 1'b0;
                    end
                end
                
                //------------------------------------------------------------
                // INIT_ROUND: Initial AddRoundKey (Round 0)
                // Outputs were set in previous state, now transition to MAIN
                //------------------------------------------------------------
                FSM_INIT_ROUND: begin
                    busy <= 1'b1;
                    
                    // Transition to first main round
                    state_reg     <= FSM_MAIN_ROUND;
                    round_main    <= 1'b1;
                    state_update  <= 1'b1;
                    round_counter <= 4'd1;
                end
                
                //------------------------------------------------------------
                // MAIN_ROUND: Rounds 1-9
                //------------------------------------------------------------
                FSM_MAIN_ROUND: begin
                    busy <= 1'b1;
                    
                    if (round_counter >= 4'd9) begin
                        // Done with round 9, go to final round
                        state_reg     <= FSM_FINAL_ROUND;
                        round_final   <= 1'b1;
                        state_update  <= 1'b1;
                        round_counter <= 4'd10;
                    end
                    else begin
                        // Continue main rounds
                        state_reg     <= FSM_MAIN_ROUND;
                        round_main    <= 1'b1;
                        state_update  <= 1'b1;
                        round_counter <= round_counter + 4'd1;
                    end
                end
                
                //------------------------------------------------------------
                // FINAL_ROUND: Round 10 (no MixColumns)
                //------------------------------------------------------------
                FSM_FINAL_ROUND: begin
                    busy <= 1'b1;
                    
                    // Go to output state
                    state_reg    <= FSM_OUTPUT;
                    output_valid <= 1'b1;
                end
                
                //------------------------------------------------------------
                // OUTPUT: Latch output data
                //------------------------------------------------------------
                FSM_OUTPUT: begin
                    busy         <= 1'b1;
                    output_valid <= 1'b1;
                    
                    // Go to done state
                    state_reg <= FSM_DONE;
                    done      <= 1'b1;
                end
                
                //------------------------------------------------------------
                // DONE: Signal completion
                //------------------------------------------------------------
                FSM_DONE: begin
                    busy         <= 1'b0;
                    output_valid <= 1'b1;
                    
                    // Return to idle
                    state_reg <= FSM_IDLE;
                end
                
                //------------------------------------------------------------
                // ERROR: Error state
                //------------------------------------------------------------
                FSM_ERROR: begin
                    busy  <= 1'b0;
                    error <= 1'b1;
                    
                    if (start) begin
                        state_reg <= FSM_IDLE;
                        error     <= 1'b0;
                    end
                end
                
                //------------------------------------------------------------
                // Default: Return to IDLE
                //------------------------------------------------------------
                default: begin
                    state_reg <= FSM_IDLE;
                    busy      <= 1'b0;
                end
            endcase
        end
    end

endmodule
