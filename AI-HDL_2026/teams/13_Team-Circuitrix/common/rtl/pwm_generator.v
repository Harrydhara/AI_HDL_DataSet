// ====================================================
// PWM Generator Module
// AI-HDL 2026 League - Beginner Level
// Features:
// - Configurable PWM resolution (default 8-bit)
// - Dual PWM outputs with independent duty cycles
// - Configurable frequency via period register
// - Enable/disable control
// - Simple AXI-like register interface
// ====================================================
// note from dami
// this is the rtl code

module pwm_generator #(
    parameter PWM_WIDTH = 8,           // PWM resolution in bits
    parameter ADDR_WIDTH = 4,          // Address width for register interface
    parameter DATA_WIDTH = 32          // Data width (matches RISC-V 32-bit)
)(
    // Clock and Reset
    input wire clk,
    input wire rst_n,
    
    // Register Interface (Simple AXI-Lite like)
    input wire [ADDR_WIDTH-1:0] reg_addr,
    input wire [DATA_WIDTH-1:0] reg_wdata,
    input wire reg_write,
    input wire reg_read,
    output reg [DATA_WIDTH-1:0] reg_rdata,
    output reg reg_ready,
    
    // PWM Outputs
    output reg pwm_out0,
    output reg pwm_out1,
    
    // Status Outputs
    output reg pwm_enabled
);

    // ====================================================
    // Internal Registers
    // ====================================================
    localparam REG_CTRL     = 4'h0;    // Control register
    localparam REG_PERIOD   = 4'h4;    // Period register
    localparam REG_DUTY0    = 4'h8;    // Duty cycle for PWM0
    localparam REG_DUTY1    = 4'hC;    // Duty cycle for PWM1
    
    // Control register bits
    localparam CTRL_ENABLE  = 0;       // Bit 0: Global enable
    localparam CTRL_POL0    = 1;       // Bit 1: PWM0 polarity (0=active high, 1=active low)
    localparam CTRL_POL1    = 2;       // Bit 2: PWM1 polarity
    
    // Internal registers
    reg [DATA_WIDTH-1:0] ctrl_reg;     // Control register
    reg [DATA_WIDTH-1:0] period_reg;   // Period register
    reg [DATA_WIDTH-1:0] duty0_reg;    // Duty cycle 0
    reg [DATA_WIDTH-1:0] duty1_reg;    // Duty cycle 1
    
    // Counter and compare registers
    reg [DATA_WIDTH-1:0] counter;
    reg [DATA_WIDTH-1:0] duty0_compare;
    reg [DATA_WIDTH-1:0] duty1_compare;
    
    // Internal PWM signals (before polarity adjustment)
    wire pwm_raw0;
    wire pwm_raw1;
    
    // ====================================================
    // Register Write Logic
    // ====================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ctrl_reg <= {DATA_WIDTH{1'b0}};
            period_reg <= {DATA_WIDTH{1'b0}};
            duty0_reg <= {DATA_WIDTH{1'b0}};
            duty1_reg <= {DATA_WIDTH{1'b0}};
            reg_ready <= 1'b0;
        end else begin
            reg_ready <= 1'b0;
            
            if (reg_write) begin
                reg_ready <= 1'b1;
                case (reg_addr)
                    REG_CTRL:   ctrl_reg <= reg_wdata;
                    REG_PERIOD: period_reg <= reg_wdata;
                    REG_DUTY0:  duty0_reg <= reg_wdata;
                    REG_DUTY1:  duty1_reg <= reg_wdata;
                    default:    ; // Do nothing for invalid addresses
                endcase
            end
        end
    end
    
    // ====================================================
    // Register Read Logic
    // ====================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_rdata <= {DATA_WIDTH{1'b0}};
        end else begin
            reg_rdata <= {DATA_WIDTH{1'b0}};
            
            if (reg_read) begin
                reg_ready <= 1'b1;
                case (reg_addr)
                    REG_CTRL:   reg_rdata <= ctrl_reg;
                    REG_PERIOD: reg_rdata <= period_reg;
                    REG_DUTY0:  reg_rdata <= duty0_reg;
                    REG_DUTY1:  reg_rdata <= duty1_reg;
                    default:    reg_rdata <= 32'hDEADBEEF; // Debug value
                endcase
            end
        end
    end
    
    // ====================================================
    // PWM Counter Logic
    // ====================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= {DATA_WIDTH{1'b0}};
            duty0_compare <= {DATA_WIDTH{1'b0}};
            duty1_compare <= {DATA_WIDTH{1'b0}};
        end else begin
            // Update compare values when PWM is disabled
            if (!ctrl_reg[CTRL_ENABLE]) begin
                duty0_compare <= duty0_reg;
                duty1_compare <= duty1_reg;
            end
            
            // Counter logic
            if (ctrl_reg[CTRL_ENABLE]) begin
                if (counter >= period_reg) begin
                    counter <= {DATA_WIDTH{1'b0}};
                    // Update compare values at the end of period
                    duty0_compare <= duty0_reg;
                    duty1_compare <= duty1_reg;
                end else begin
                    counter <= counter + 1;
                end
            end else begin
                counter <= {DATA_WIDTH{1'b0}};
            end
        end
    end
    
    // ====================================================
    // PWM Generation Logic
    // ====================================================
    assign pwm_raw0 = (counter < duty0_compare) && (period_reg != 0);
    assign pwm_raw1 = (counter < duty1_compare) && (period_reg != 0);
    
    // Apply polarity inversion if configured
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pwm_out0 <= 1'b0;
            pwm_out1 <= 1'b0;
            pwm_enabled <= 1'b0;
        end else begin
            pwm_enabled <= ctrl_reg[CTRL_ENABLE];
            
            // PWM0 with polarity control
            if (ctrl_reg[CTRL_POL0])
                pwm_out0 <= ~pwm_raw0;
            else
                pwm_out0 <= pwm_raw0;
                
            // PWM1 with polarity control
            if (ctrl_reg[CTRL_POL1])
                pwm_out1 <= ~pwm_raw1;
            else
                pwm_out1 <= pwm_raw1;
        end
    end
    
    // ====================================================
    // Assertions (for simulation only)
    // ====================================================
    // synthesis translate_off
    always @(posedge clk) begin
        if (ctrl_reg[CTRL_ENABLE]) begin
            // Ensure duty cycle doesn't exceed period
            if (duty0_reg > period_reg)
                $warning("PWM0 duty cycle (%0d) exceeds period (%0d)", duty0_reg, period_reg);
            if (duty1_reg > period_reg)
                $warning("PWM1 duty cycle (%0d) exceeds period (%0d)", duty1_reg, period_reg);
        end
    end
    // synthesis translate_on

endmodule