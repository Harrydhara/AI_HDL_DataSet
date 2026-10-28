//============================================================================
// Module: aes_reg_interface
// Description: Memory-Mapped Register Interface for AES-128 Accelerator
//              Handles TinyQV peripheral bus transactions
//
// Features:
//   - 32-bit read/write register access
//   - Address decoding for AES register map
//   - Control and status register management
//   - Interrupt generation and control
//   - TinyQV peripheral interface compliance
//
// Register Map (Base offset 0x100 from peripheral base):
//   0x00: AES_CTRL     - Control register (R/W)
//   0x04: AES_STATUS   - Status register (R)
//   0x08: AES_INT_EN   - Interrupt enable (R/W)
//   0x0C: AES_INT_STAT - Interrupt status (R/W1C)
//   0x10: AES_KEY0     - Key word 0 (W)
//   0x14: AES_KEY1     - Key word 1 (W)
//   0x18: AES_KEY2     - Key word 2 (W)
//   0x1C: AES_KEY3     - Key word 3 (W)
//   0x20: AES_DIN0     - Data input word 0 (W)
//   0x24: AES_DIN1     - Data input word 1 (W)
//   0x28: AES_DIN2     - Data input word 2 (W)
//   0x2C: AES_DIN3     - Data input word 3 (W)
//   0x30: AES_DOUT0    - Data output word 0 (R)
//   0x34: AES_DOUT1    - Data output word 1 (R)
//   0x38: AES_DOUT2    - Data output word 2 (R)
//   0x3C: AES_DOUT3    - Data output word 3 (R)
//
// Author: AIHDL 2026 Competition Team
// Date: January 2026
// Target: TinyQV RISC-V Peripheral (64MHz)
//============================================================================

module aes_reg_interface (
    input  wire         clk,            // System clock
    input  wire         rst_n,          // Active-low reset
    
    // TinyQV Peripheral Bus Interface
    input  wire [5:0]   address,        // Register address (6-bit)
    input  wire [31:0]  data_in,        // Write data from CPU
    input  wire [1:0]   data_write_n,   // Write strobe (0,1,2=8,16,32-bit; 3=none)
    input  wire [1:0]   data_read_n,    // Read strobe (0,1,2=8,16,32-bit; 3=none)
    output reg  [31:0]  data_out,       // Read data to CPU
    output reg          data_ready,     // Read data valid
    
    // AES Core Interface
    output reg  [127:0] key_reg,        // 128-bit key to AES core
    output reg  [127:0] din_reg,        // 128-bit data input to AES core
    input  wire [127:0] dout_reg,       // 128-bit data output from AES core
    output reg          start,          // Start operation signal
    output reg          decrypt,        // Decrypt mode (0=encrypt, 1=decrypt)
    input  wire         busy,           // AES core busy
    input  wire         done,           // AES core done
    output reg          key_load,       // Load key trigger
    input  wire         key_valid,      // Key expansion complete
    input  wire         key_busy,       // Key expansion in progress
    
    // Interrupt Output
    output wire         user_interrupt  // Interrupt to TinyQV
);

    //------------------------------------------------------------------------
    // Register Address Definitions
    //------------------------------------------------------------------------
    localparam [5:0] ADDR_CTRL     = 6'h00;  // Control register
    localparam [5:0] ADDR_STATUS   = 6'h04;  // Status register
    localparam [5:0] ADDR_INT_EN   = 6'h08;  // Interrupt enable
    localparam [5:0] ADDR_INT_STAT = 6'h0C;  // Interrupt status
    localparam [5:0] ADDR_KEY0     = 6'h10;  // Key word 0
    localparam [5:0] ADDR_KEY1     = 6'h14;  // Key word 1
    localparam [5:0] ADDR_KEY2     = 6'h18;  // Key word 2
    localparam [5:0] ADDR_KEY3     = 6'h1C;  // Key word 3
    localparam [5:0] ADDR_DIN0     = 6'h20;  // Data in word 0
    localparam [5:0] ADDR_DIN1     = 6'h24;  // Data in word 1
    localparam [5:0] ADDR_DIN2     = 6'h28;  // Data in word 2
    localparam [5:0] ADDR_DIN3     = 6'h2C;  // Data in word 3
    localparam [5:0] ADDR_DOUT0    = 6'h30;  // Data out word 0
    localparam [5:0] ADDR_DOUT1    = 6'h34;  // Data out word 1
    localparam [5:0] ADDR_DOUT2    = 6'h38;  // Data out word 2
    localparam [5:0] ADDR_DOUT3    = 6'h3C;  // Data out word 3

    //------------------------------------------------------------------------
    // Internal Registers
    //------------------------------------------------------------------------
    
    // Control Register: [0]=START, [1]=MODE(0=enc,1=dec), [2]=KEY_VALID(RO)
    reg [7:0] ctrl_reg;
    
    // Interrupt Enable Register: [0]=DONE_IE, [1]=ERROR_IE
    reg [7:0] int_en_reg;
    
    // Interrupt Status Register: [0]=DONE_IF, [1]=ERROR_IF (W1C)
    reg [7:0] int_status_reg;
    
    // Key and Data Valid tracking
    reg key_written;
    reg [3:0] key_wr_mask;
    reg din_written;
    reg [3:0] din_wr_mask;
    
    // Operation done latch
    reg done_latch;
    
    // Write enable detection
    wire write_en;
    wire read_en;
    
    assign write_en = (data_write_n != 2'b11);
    assign read_en  = (data_read_n != 2'b11);

    //------------------------------------------------------------------------
    // Write Logic
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
            
            // Latch done signal for interrupt
            if (done) begin
                done_latch <= 1'b1;
                int_status_reg[0] <= 1'b1;  // Set DONE_IF
            end
            
            // Clear done latch when reading status or starting new operation
            if (start) begin
                done_latch <= 1'b0;
            end
            
            // Write transactions
            if (write_en) begin
                case (address)
                    ADDR_CTRL: begin
                        ctrl_reg <= data_in[7:0];
                        decrypt <= data_in[1];
                        // Start operation on rising edge of START bit
                        if (data_in[0] && !ctrl_reg[0] && key_valid && din_written) begin
                            start <= 1'b1;
                            done_latch <= 1'b0;
                            int_status_reg[0] <= 1'b0;  // Clear DONE_IF
                        end
                    end
                    
                    ADDR_INT_EN: begin
                        int_en_reg <= data_in[7:0];
                    end
                    
                    ADDR_INT_STAT: begin
                        // Write-1-to-clear behavior
                        int_status_reg <= int_status_reg & ~data_in[7:0];
                    end
                    
                    ADDR_KEY0: begin
                        key_reg[127:96] <= data_in;
                        key_wr_mask[0] <= 1'b1;
                        // Check if all key words written
                        if (key_wr_mask[3:1] == 3'b111) begin
                            key_written <= 1'b1;
                            key_load <= 1'b1;
                            key_wr_mask <= 4'd0;
                        end
                    end
                    
                    ADDR_KEY1: begin
                        key_reg[95:64] <= data_in;
                        key_wr_mask[1] <= 1'b1;
                        if ({key_wr_mask[3:2], key_wr_mask[0]} == 3'b111) begin
                            key_written <= 1'b1;
                            key_load <= 1'b1;
                            key_wr_mask <= 4'd0;
                        end
                    end
                    
                    ADDR_KEY2: begin
                        key_reg[63:32] <= data_in;
                        key_wr_mask[2] <= 1'b1;
                        if ({key_wr_mask[3], key_wr_mask[1:0]} == 3'b111) begin
                            key_written <= 1'b1;
                            key_load <= 1'b1;
                            key_wr_mask <= 4'd0;
                        end
                    end
                    
                    ADDR_KEY3: begin
                        key_reg[31:0] <= data_in;
                        key_wr_mask[3] <= 1'b1;
                        if (key_wr_mask[2:0] == 3'b111) begin
                            key_written <= 1'b1;
                            key_load <= 1'b1;
                            key_wr_mask <= 4'd0;
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
    // Read Logic
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
                        // Status: [0]=BUSY, [1]=DONE, [2]=ERROR, [3]=KEY_VALID, [4]=DIN_VALID
                        data_out <= {27'd0, din_written, key_valid, 1'b0, done_latch, busy};
                    end
                    
                    ADDR_INT_EN: begin
                        data_out <= {24'd0, int_en_reg};
                    end
                    
                    ADDR_INT_STAT: begin
                        data_out <= {24'd0, int_status_reg};
                    end
                    
                    ADDR_KEY0: begin
                        data_out <= 32'd0;  // Key is write-only for security
                    end
                    
                    ADDR_KEY1: begin
                        data_out <= 32'd0;
                    end
                    
                    ADDR_KEY2: begin
                        data_out <= 32'd0;
                    end
                    
                    ADDR_KEY3: begin
                        data_out <= 32'd0;
                    end
                    
                    ADDR_DIN0: begin
                        data_out <= 32'd0;  // Input data is write-only
                    end
                    
                    ADDR_DIN1: begin
                        data_out <= 32'd0;
                    end
                    
                    ADDR_DIN2: begin
                        data_out <= 32'd0;
                    end
                    
                    ADDR_DIN3: begin
                        data_out <= 32'd0;
                    end
                    
                    ADDR_DOUT0: begin
                        // Delay ready until operation complete
                        if (busy) begin
                            data_ready <= 1'b0;
                        end
                        else begin
                            data_out <= dout_reg[127:96];
                            data_ready <= 1'b1;
                        end
                    end
                    
                    ADDR_DOUT1: begin
                        if (busy) begin
                            data_ready <= 1'b0;
                        end
                        else begin
                            data_out <= dout_reg[95:64];
                            data_ready <= 1'b1;
                        end
                    end
                    
                    ADDR_DOUT2: begin
                        if (busy) begin
                            data_ready <= 1'b0;
                        end
                        else begin
                            data_out <= dout_reg[63:32];
                            data_ready <= 1'b1;
                        end
                    end
                    
                    ADDR_DOUT3: begin
                        if (busy) begin
                            data_ready <= 1'b0;
                        end
                        else begin
                            data_out <= dout_reg[31:0];
                            data_ready <= 1'b1;
                        end
                    end
                    
                    default: begin
                        data_out <= 32'd0;
                    end
                endcase
            end
        end
    end

    //------------------------------------------------------------------------
    // Interrupt Generation
    // Interrupt asserted when enabled interrupt flag is set
    //------------------------------------------------------------------------
    assign user_interrupt = (int_status_reg[0] & int_en_reg[0]) |  // DONE interrupt
                            (int_status_reg[1] & int_en_reg[1]);   // ERROR interrupt

endmodule
