// =============================================================================
// Module: aes_masking_lfsr
// Description: 32-bit Galois LFSR for generating random mask bytes
//              Used for first-order Boolean masking of AES S-Box operations
// Target: Anti-DPA side-channel countermeasure (CWE-1300)
// Team: Acona | AI-HDL 2026 DP3
// =============================================================================

module aes_masking_lfsr (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        enable,       // Generate new random output
    input  logic        seed_we,      // Seed write enable
    input  logic [31:0] seed_data,    // Seed value (must be non-zero)
    output logic [31:0] rand_out,     // 32-bit random output (4 mask bytes)
    output logic        valid         // Output is valid (LFSR has been seeded)
);

    // 32-bit Galois LFSR with maximal-length polynomial
    // Polynomial: x^32 + x^22 + x^2 + x^1 + 1
    // Period: 2^32 - 1 (over 4 billion unique values)
    logic [31:0] lfsr_reg;
    logic        seeded;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr_reg <= 32'hDEADBEEF;  // Non-zero default seed
            seeded   <= 1'b0;
        end else if (seed_we && (seed_data != 32'h0)) begin
            // Load user-provided seed (reject zero - would lock LFSR)
            lfsr_reg <= seed_data;
            seeded   <= 1'b1;
        end else if (enable) begin
            // Galois LFSR shift with feedback taps at bits 31, 21, 1, 0
            lfsr_reg[31]   <= lfsr_reg[0];
            lfsr_reg[30:23] <= lfsr_reg[31:24];
            lfsr_reg[22]   <= lfsr_reg[23] ^ lfsr_reg[0];
            lfsr_reg[21:3] <= lfsr_reg[22:4];
            lfsr_reg[2]    <= lfsr_reg[3] ^ lfsr_reg[0];
            lfsr_reg[1]    <= lfsr_reg[2] ^ lfsr_reg[0];
            lfsr_reg[0]    <= lfsr_reg[1];
        end
    end

    assign rand_out = lfsr_reg;
    assign valid    = seeded;

endmodule
