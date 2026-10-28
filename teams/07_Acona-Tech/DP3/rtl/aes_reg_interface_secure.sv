//============================================================================
// Module: aes_reg_interface_secure
// Description: Security-Hardened Memory-Mapped Register Interface for AES-128
//
// DP3 SECURITY FEATURES:
//   1. KEY_LOCK - Write-once sticky bit preventing key read-back/overwrite
//   2. ZEROIZE - Hardware key erasure (key regs + expanded round keys)
//   3. LFSR_SEED - Configurable seed for masking LFSR (writable before lock)
//   4. SECURITY_STATUS - Read-only security state monitoring
//   5. FAULT status integration - Reports fault detector state
//
// Extended Register Map (7-bit address, backward compatible):
//   0x00-0x3C: Original DP2 registers (unchanged behavior)
//   0x40: SEC_CTRL     - Security control [0]=KEY_LOCK, [1]=ZEROIZE
//   0x44: SEC_STATUS   - Security status (RO)
//   0x48: LFSR_SEED    - Masking LFSR seed (W, only when KEY_LOCK=0)
//
// CWE Mitigations: CWE-1231, CWE-1259, CWE-1271
// Author: AIHDL 2026 Team Acona | DP3 Security Phase
//============================================================================

module aes_reg_interface_secure (
    input  wire         clk,
    input  wire         rst_n,
    
    // TinyQV Peripheral Bus Interface (extended to 7-bit address)
    input  wire [6:0]   address,
    input  wire [31:0]  data_in,
    input  wire [1:0]   data_write_n,
    input  wire [1:0]   data_read_n,
    output reg  [31:0]  data_out,
    output reg          data_ready,
    
    // AES Core Interface (same as DP2)
    output reg  [127:0] key_reg,
    output reg  [127:0] din_reg,
    input  wire [127:0] dout_reg,
    output reg          start,
    output reg          decrypt,
    input  wire         busy,
    input  wire         done,
    output reg          key_load,
    input  wire         key_valid,
    input  wire         key_busy,
    
    // Interrupt Output
    output wire         user_interrupt,
    
    // DP3 Security Outputs
    output wire         key_locked,       // KEY_LOCK state (to top)
    output reg          zeroize_pulse,    // Single-cycle zeroize trigger
    output reg  [31:0]  lfsr_seed_data,   // LFSR seed value
    output reg          lfsr_seed_we,     // LFSR seed write enable
    
    // DP3 Security Inputs (from fault detector)
    input  wire         fault_detected,   // From fault detector
    input  wire         masking_active    // From LFSR valid
);

    //------------------------------------------------------------------------
    // Register Address Definitions (DP2 original + DP3 security)
    //------------------------------------------------------------------------
    localparam [6:0] ADDR_CTRL     = 7'h00;
    localparam [6:0] ADDR_STATUS   = 7'h04;
    localparam [6:0] ADDR_INT_EN   = 7'h08;
    localparam [6:0] ADDR_INT_STAT = 7'h0C;
    localparam [6:0] ADDR_KEY0     = 7'h10;
    localparam [6:0] ADDR_KEY1     = 7'h14;
    localparam [6:0] ADDR_KEY2     = 7'h18;
    localparam [6:0] ADDR_KEY3     = 7'h1C;
    localparam [6:0] ADDR_DIN0     = 7'h20;
    localparam [6:0] ADDR_DIN1     = 7'h24;
    localparam [6:0] ADDR_DIN2     = 7'h28;
    localparam [6:0] ADDR_DIN3     = 7'h2C;
    localparam [6:0] ADDR_DOUT0    = 7'h30;
    localparam [6:0] ADDR_DOUT1    = 7'h34;
    localparam [6:0] ADDR_DOUT2    = 7'h38;
    localparam [6:0] ADDR_DOUT3    = 7'h3C;
    // DP3 Security Registers
    localparam [6:0] ADDR_SEC_CTRL   = 7'h40;
    localparam [6:0] ADDR_SEC_STATUS = 7'h44;
    localparam [6:0] ADDR_LFSR_SEED  = 7'h48;

    //------------------------------------------------------------------------
    // Internal Registers (DP2 original)
    //------------------------------------------------------------------------
    reg [7:0] ctrl_reg;
    reg [7:0] int_en_reg;
    reg [7:0] int_status_reg;
    reg key_written;
    reg [3:0] key_wr_mask;
    reg din_written;
    reg [3:0] din_wr_mask;
    reg done_latch;
    
    wire write_en;
    wire read_en;
    assign write_en = (data_write_n != 2'b11);
    assign read_en  = (data_read_n != 2'b11);

    //------------------------------------------------------------------------
    // DP3 Security Registers
    //------------------------------------------------------------------------
    reg key_lock_reg;      // Sticky KEY_LOCK bit
    reg zeroized_reg;      // Zeroization completed flag
    
    assign key_locked = key_lock_reg;

    //------------------------------------------------------------------------
    // KEY_LOCK Logic (CWE-1231)
    // Write-once sticky bit: once set, only reset or ZEROIZE clears it
    //------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            key_lock_reg <= 1'b0;
        end else if (zeroize_pulse) begin
            key_lock_reg <= 1'b0;  // Zeroize clears lock (new key needed)
        end else if (write_en && address == ADDR_SEC_CTRL && data_in[0]) begin
            key_lock_reg <= 1'b1;  // Sticky set - cannot be cleared by writing 0
        end
    end

    //------------------------------------------------------------------------
    // ZEROIZE Logic (CWE-1259)
    // Single-cycle pulse to clear all key material
    //------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            zeroize_pulse <= 1'b0;
            zeroized_reg  <= 1'b0;
        end else begin
            zeroize_pulse <= 1'b0;  // Default: clear pulse
            if (write_en && address == ADDR_SEC_CTRL && data_in[1]) begin
                zeroize_pulse <= 1'b1;
                zeroized_reg  <= 1'b1;
            end
            // Clear zeroized flag when new key is loaded
            if (key_load) begin
                zeroized_reg <= 1'b0;
            end
        end
    end

    //------------------------------------------------------------------------
    // LFSR Seed Write (only when KEY_LOCK = 0)
    //------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr_seed_we   <= 1'b0;
            lfsr_seed_data <= 32'h0;
        end else begin
            lfsr_seed_we <= 1'b0;
            if (write_en && address == ADDR_LFSR_SEED && !key_lock_reg) begin
                lfsr_seed_we   <= 1'b1;
                lfsr_seed_data <= data_in;
            end
        end
    end

    //------------------------------------------------------------------------
    // Write Logic (modified from DP2 for KEY_LOCK and ZEROIZE)
    //------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ctrl_reg <= 8'd0;
            int_en_reg <= 8'd0;
            int_status_reg <= 8'd0;
            key_reg <= 128'd0;
            din_reg <= 128'd0;
            start <= 1'b0;
            decrypt <= 1'b0;
            key_load <= 1'b0;
            key_written <= 1'b0;
            key_wr_mask <= 4'd0;
            din_written <= 1'b0;
            din_wr_mask <= 4'd0;
            done_latch <= 1'b0;
        end
        else begin
            // Default: clear single-cycle signals
            start <= 1'b0;
            key_load <= 1'b0;
            
            //==============================================================
            // DP3: Key Zeroization - clear all key material immediately
            //==============================================================
            if (zeroize_pulse) begin
                key_reg     <= 128'd0;
                key_written <= 1'b0;
                key_wr_mask <= 4'd0;
            end
            
            // Latch done signal for interrupt
            if (done) begin
                done_latch <= 1'b1;
                int_status_reg[0] <= 1'b1;
            end
            
            if (start) begin
                done_latch <= 1'b0;
            end
            
            // Write transactions
            if (write_en) begin
                case (address)
                    ADDR_CTRL: begin
                        ctrl_reg <= data_in[7:0];
                        decrypt <= data_in[1];
                        if (data_in[0] && !ctrl_reg[0] && key_valid && din_written) begin
                            start <= 1'b1;
                            done_latch <= 1'b0;
                            int_status_reg[0] <= 1'b0;
                        end
                    end
                    
                    ADDR_INT_EN: begin
                        int_en_reg <= data_in[7:0];
                    end
                    
                    ADDR_INT_STAT: begin
                        int_status_reg <= int_status_reg & ~data_in[7:0];
                    end
                    
                    //======================================================
                    // DP3: Key writes gated by KEY_LOCK (CWE-1231)
                    //======================================================
                    ADDR_KEY0: begin
                        if (!key_lock_reg) begin  // Only write when NOT locked
                            key_reg[127:96] <= data_in;
                            key_wr_mask[0] <= 1'b1;
                            if (key_wr_mask[3:1] == 3'b111) begin
                                key_written <= 1'b1;
                                key_load <= 1'b1;
                                key_wr_mask <= 4'd0;
                            end
                        end
                        // Writes silently ignored when locked (no bus error)
                    end
                    
                    ADDR_KEY1: begin
                        if (!key_lock_reg) begin
                            key_reg[95:64] <= data_in;
                            key_wr_mask[1] <= 1'b1;
                            if ({key_wr_mask[3:2], key_wr_mask[0]} == 3'b111) begin
                                key_written <= 1'b1;
                                key_load <= 1'b1;
                                key_wr_mask <= 4'd0;
                            end
                        end
                    end
                    
                    ADDR_KEY2: begin
                        if (!key_lock_reg) begin
                            key_reg[63:32] <= data_in;
                            key_wr_mask[2] <= 1'b1;
                            if ({key_wr_mask[3], key_wr_mask[1:0]} == 3'b111) begin
                                key_written <= 1'b1;
                                key_load <= 1'b1;
                                key_wr_mask <= 4'd0;
                            end
                        end
                    end
                    
                    ADDR_KEY3: begin
                        if (!key_lock_reg) begin
                            key_reg[31:0] <= data_in;
                            key_wr_mask[3] <= 1'b1;
                            if (key_wr_mask[2:0] == 3'b111) begin
                                key_written <= 1'b1;
                                key_load <= 1'b1;
                                key_wr_mask <= 4'd0;
                            end
                        end
                    end
                    
                    ADDR_DIN0: begin
                        din_reg[127:96] <= data_in;
                        din_wr_mask[0] <= 1'b1;
                        if (din_wr_mask[3:1] == 3'b111) begin
                            din_written <= 1'b1;
                            din_wr_mask <= 4'd0;
                        end
                    end
                    
                    ADDR_DIN1: begin
                        din_reg[95:64] <= data_in;
                        din_wr_mask[1] <= 1'b1;
                        if ({din_wr_mask[3:2], din_wr_mask[0]} == 3'b111) begin
                            din_written <= 1'b1;
                            din_wr_mask <= 4'd0;
                        end
                    end
                    
                    ADDR_DIN2: begin
                        din_reg[63:32] <= data_in;
                        din_wr_mask[2] <= 1'b1;
                        if ({din_wr_mask[3], din_wr_mask[1:0]} == 3'b111) begin
                            din_written <= 1'b1;
                            din_wr_mask <= 4'd0;
                        end
                    end
                    
                    ADDR_DIN3: begin
                        din_reg[31:0] <= data_in;
                        din_wr_mask[3] <= 1'b1;
                        if (din_wr_mask[2:0] == 3'b111) begin
                            din_written <= 1'b1;
                            din_wr_mask <= 4'd0;
                        end
                    end
                    
                    // SEC_CTRL and LFSR_SEED handled in their own always blocks
                    
                    default: begin
                        // Ignore writes to read-only or invalid addresses
                    end
                endcase
            end
            
            // Auto-clear START bit
            if (ctrl_reg[0] && (busy || done)) begin
                ctrl_reg[0] <= 1'b0;
            end
            
            // Clear din_written after operation starts
            if (start) begin
                din_written <= 1'b0;
            end
        end
    end

    //------------------------------------------------------------------------
    // Read Logic (extended with security registers)
    //------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 32'd0;
            data_ready <= 1'b0;
        end
        else begin
            data_ready <= 1'b0;
            
            if (read_en) begin
                data_ready <= 1'b1;
                
                case (address)
                    ADDR_CTRL: begin
                        data_out <= {24'd0, ctrl_reg};
                    end
                    
                    ADDR_STATUS: begin
                        data_out <= {27'd0, din_written, key_valid, 1'b0, done_latch, busy};
                    end
                    
                    ADDR_INT_EN: begin
                        data_out <= {24'd0, int_en_reg};
                    end
                    
                    ADDR_INT_STAT: begin
                        data_out <= {24'd0, int_status_reg};
                    end
                    
                    //======================================================
                    // DP3: Key read returns 0 (always, same as DP2 but 
                    // now also enforced by KEY_LOCK for extra safety)
                    //======================================================
                    ADDR_KEY0, ADDR_KEY1, ADDR_KEY2, ADDR_KEY3: begin
                        data_out <= 32'd0;  // Key always read as zero
                    end
                    
                    ADDR_DIN0, ADDR_DIN1, ADDR_DIN2, ADDR_DIN3: begin
                        data_out <= 32'd0;
                    end
                    
                    ADDR_DOUT0: begin
                        if (busy) begin
                            data_ready <= 1'b0;
                        end else begin
                            data_out <= dout_reg[127:96];
                            data_ready <= 1'b1;
                        end
                    end
                    
                    ADDR_DOUT1: begin
                        if (busy) begin data_ready <= 1'b0; end
                        else begin data_out <= dout_reg[95:64]; data_ready <= 1'b1; end
                    end
                    
                    ADDR_DOUT2: begin
                        if (busy) begin data_ready <= 1'b0; end
                        else begin data_out <= dout_reg[63:32]; data_ready <= 1'b1; end
                    end
                    
                    ADDR_DOUT3: begin
                        if (busy) begin data_ready <= 1'b0; end
                        else begin data_out <= dout_reg[31:0]; data_ready <= 1'b1; end
                    end
                    
                    //======================================================
                    // DP3: Security Registers
                    //======================================================
                    ADDR_SEC_CTRL: begin
                        data_out <= {30'd0, 1'b0, key_lock_reg};  // ZEROIZE is write-only
                    end
                    
                    ADDR_SEC_STATUS: begin
                        // [0]=KEY_LOCKED, [1]=ZEROIZED, [2]=FAULT_DETECTED, [3]=MASKING_ACTIVE
                        data_out <= {28'd0, masking_active, fault_detected, zeroized_reg, key_lock_reg};
                    end
                    
                    ADDR_LFSR_SEED: begin
                        data_out <= 32'd0;  // Seed is write-only
                    end
                    
                    default: begin
                        data_out <= 32'd0;
                    end
                endcase
            end
        end
    end

    //------------------------------------------------------------------------
    // Interrupt Generation (same as DP2)
    //------------------------------------------------------------------------
    assign user_interrupt = (int_status_reg[0] & int_en_reg[0]) |
                            (int_status_reg[1] & int_en_reg[1]);

endmodule

