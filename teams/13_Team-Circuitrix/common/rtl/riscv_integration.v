// integration wrapper
// ====================================================
// RISC-V PWM Integration Module
// Connects PWM Generator to RISC-V core
// ====================================================

module riscv_pwm_integration #(
    parameter PWM_WIDTH = 8,
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 32
)(
    // Clock and Reset
    input wire clk,
    input wire rst_n,
    
    // RISC-V Wishbone Bus Interface (Common for small RISC-V cores)
    input wire wb_cyc_i,      // Bus cycle
    input wire wb_stb_i,      // Strobe
    input wire wb_we_i,       // Write enable
    input wire [31:0] wb_adr_i, // Address
    input wire [31:0] wb_dat_i, // Write data
    output reg [31:0] wb_dat_o, // Read data
    output reg wb_ack_o,      // Acknowledge
    
    // PWM Outputs
    output wire pwm_out0,
    output wire pwm_out1,
    
    // Interrupt (optional)
    output wire pwm_irq
);

    // Local Parameters
    localparam BASE_ADDRESS = 32'h4000_0000; // Memory-mapped address
    
    // Internal signals
    wire [ADDR_WIDTH-1:0] reg_addr;
    wire [DATA_WIDTH-1:0] reg_wdata;
    wire reg_write;
    wire reg_read;
    wire [DATA_WIDTH-1:0] reg_rdata;
    wire reg_ready;
    
    // Address decoder
    wire pwm_select = (wb_adr_i[31:8] == BASE_ADDRESS[31:8]);
    wire [3:0] reg_offset = wb_adr_i[5:2]; // Word-aligned addresses
    
    // Bus interface FSM
    reg ack_reg;
    reg [1:0] state;
    localparam IDLE = 2'b00;
    localparam ACCESS = 2'b01;
    localparam RESPOND = 2'b10;
    
    // Bus control logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            ack_reg <= 1'b0;
            wb_ack_o <= 1'b0;
            wb_dat_o <= 32'h0;
        end else begin
            case (state)
                IDLE: begin
                    wb_ack_o <= 1'b0;
                    if (wb_cyc_i && wb_stb_i && pwm_select) begin
                        state <= ACCESS;
                        ack_reg <= 1'b1;
                    end
                end
                
                ACCESS: begin
                    if (reg_ready) begin
                        wb_dat_o <= reg_rdata;
                        wb_ack_o <= 1'b1;
                        state <= RESPOND;
                    end
                end
                
                RESPOND: begin
                    wb_ack_o <= 1'b0;
                    state <= IDLE;
                end
            endcase
        end
    end
    
    // Connect to PWM generator
    assign reg_addr = reg_offset[ADDR_WIDTH-1:0];
    assign reg_wdata = wb_dat_i;
    assign reg_write = pwm_select && wb_cyc_i && wb_stb_i && wb_we_i && (state == IDLE);
    assign reg_read = pwm_select && wb_cyc_i && wb_stb_i && !wb_we_i && (state == IDLE);
    
    // Instantiate PWM Generator
    pwm_generator #(
        .PWM_WIDTH(PWM_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) pwm_inst (
        .clk(clk),
        .rst_n(rst_n),
        .reg_addr(reg_addr),
        .reg_wdata(reg_wdata),
        .reg_write(reg_write),
        .reg_read(reg_read),
        .reg_rdata(reg_rdata),
        .reg_ready(reg_ready),
        .pwm_out0(pwm_out0),
        .pwm_out1(pwm_out1),
        .pwm_enabled()  // Connect if needed
    );
    
    // Simple interrupt generation (optional)
    // Generate interrupt when PWM counter wraps
    reg irq_reg;
    reg [31:0] counter;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            irq_reg <= 1'b0;
            counter <= 32'h0;
        end else begin
            counter <= counter + 1;
            // Generate interrupt every 1 million cycles (example)
            irq_reg <= (counter == 32'd1000000);
            if (irq_reg) counter <= 32'h0;
        end
    end
    
    assign pwm_irq = irq_reg;

endmodule