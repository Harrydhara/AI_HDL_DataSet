//============================================================================
// Module: aes_fault_detector
// Description: Redundant round counter with completion check
//              Detects fault injection attacks that skip AES rounds
// Target: CWE-1243 Fault Injection Protection
// Team: Acona | AI-HDL 2026 DP3
//============================================================================

module aes_fault_detector (
    input  wire        clk,
    input  wire        rst_n,

    input  wire        round_start,
    input  wire        encryption_start,
    input  wire        encryption_done,
    input  wire [3:0]  fsm_round_count,

    input  wire        clear_fault,

    output reg         fault_detected,
    output wire        output_valid
);

    // Shadow round counter (independent from FSM)
    reg [3:0] shadow_count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shadow_count <= 4'd0;
        end else if (encryption_start) begin
            shadow_count <= 4'd0;
        end else if (round_start) begin
            shadow_count <= shadow_count + 4'd1;
        end
    end

    // Check ONLY at encryption completion
    // Normal AES-128 produces exactly 9 round_start pulses (rounds 1-9)
    // and fsm_round_count should be 10 at completion
    wire completion_fault;
    assign completion_fault = encryption_done && 
                              ((shadow_count != 4'd9) || (fsm_round_count != 4'd10));

    // Sticky fault flag
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fault_detected <= 1'b0;
        end else if (clear_fault) begin
            fault_detected <= 1'b0;
        end else if (completion_fault) begin
            fault_detected <= 1'b1;
        end
    end

    assign output_valid = ~fault_detected;

endmodule
