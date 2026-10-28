`default_nettype none

module encoder #(
    parameter WIDTH = 8,
    // Fix 1: Use 'integer' or explicit width so values > 1 don't get truncated
    parameter [WIDTH-1:0] INCREMENT = 1 
)(
    // Fix 2: Add 'wire' to inputs because of default_nettype none
    input wire clk,
    input wire reset,
    input wire a,
    input wire b,
    output reg [WIDTH-1:0] value
);

    // Fix 3: Synchronization registers to prevent metastability
    reg a_sync_0, a_sync_1;
    reg b_sync_0, b_sync_1;
    
    // Store previous state of the synchronized signals
    reg old_a;
    reg old_b;

    always @(posedge clk) begin
        if (reset) begin
            a_sync_0 <= 0; a_sync_1 <= 0;
            b_sync_0 <= 0; b_sync_1 <= 0;
            old_a    <= 0;
            old_b    <= 0;
            value    <= 0;
        end else begin
            // 1. Double-flop synchronizer
            a_sync_0 <= a;
            a_sync_1 <= a_sync_0; // Use a_sync_1 in logic
            
            b_sync_0 <= b;
            b_sync_1 <= b_sync_0; // Use b_sync_1 in logic

            // 2. Store old values (of the synchronized signals)
            old_a <= a_sync_1;
            old_b <= b_sync_1;

            // 3. Full Quadrature Logic (Handling all 8 transitions)
            // {a_sync_1, old_a, b_sync_1, old_b}
            case ({a_sync_1, old_a, b_sync_1, old_b})
                // Clockwise Transitions (A leads B)
                4'b1000: value <= value + INCREMENT; // A rise, B low
                4'b1110: value <= value + INCREMENT; // B rise, A high (Missing in original)
                4'b0111: value <= value + INCREMENT; // A fall, B high
                4'b0001: value <= value + INCREMENT; // B fall, A low  (Missing in original)

                // Counter-Clockwise Transitions (B leads A)
                4'b0010: value <= value - INCREMENT; // B rise, A low
                4'b1011: value <= value - INCREMENT; // A rise, B high (Missing in original)
                4'b1101: value <= value - INCREMENT; // B fall, A high
                4'b0100: value <= value - INCREMENT; // A fall, B low  (Missing in original)

                default: value <= value;
            endcase
        end
    end

endmodule
