//============================================================================
// Module: tinyqv_soc
// Description: RISC-V SoC with AES-128 Crypto Accelerator
//============================================================================

module tinyqv_soc (
    // System Interface
    input  wire         clk,
    input  wire         rst_n,
    
    // External Memory Interface (if needed)
    // ...
    
    // UART Interface (if needed)
    // ...
    
    // GPIO (if needed)
    // ...
);

    //------------------------------------------------------------------------
    // Internal Signals
    //------------------------------------------------------------------------
    
    // Peripheral Bus (from RISC-V core)
    wire [31:0] periph_addr;      // Address from CPU
    wire [31:0] periph_wdata;     // Write data from CPU
    wire [31:0] periph_rdata;     // Read data to CPU
    wire        periph_write;     // Write enable from CPU
    wire        periph_read;      // Read enable from CPU
    wire        periph_ready;     // Transaction complete
    
    // AES Module Signals
    wire        aes_select;       // Address decode: AES selected
    wire [31:0] aes_rdata;        // Read data from AES
    wire        aes_ready;        // AES transaction complete
    wire        aes_interrupt;    // AES done interrupt
    
    // Interrupt signals
    wire        external_irq;     // Combined external interrupts
    
    //------------------------------------------------------------------------
    // Address Decoder
    // AES base address: 0x80001000 - 0x8000103F (64 bytes)
    //------------------------------------------------------------------------
    assign aes_select = (periph_addr[31:6] == 26'h200004);  
    // 0x80001000 >> 6 = 0x200004
    
    //------------------------------------------------------------------------
    // Data Multiplexer (from peripherals to CPU)
    //------------------------------------------------------------------------
    assign periph_rdata = aes_select ? aes_rdata : 32'h0;
    assign periph_ready = aes_select ? aes_ready : 1'b1;
    
    //------------------------------------------------------------------------
    // Interrupt Combiner
    //------------------------------------------------------------------------
    assign external_irq = aes_interrupt;  // Can OR with other peripherals
    
    //------------------------------------------------------------------------
    // RISC-V Core Instance (Replace with your actual core)
    //------------------------------------------------------------------------
    tinyqv_core u_riscv_core (
        .clk                (clk),
        .rst_n              (rst_n),
        
        // Peripheral Bus Interface
        .periph_addr        (periph_addr),
        .periph_wdata       (periph_wdata),
        .periph_rdata       (periph_rdata),
        .periph_write       (periph_write),
        .periph_read        (periph_read),
        .periph_ready       (periph_ready),
        
        // Interrupt Input
        .external_interrupt (external_irq)
        
        // ... other ports (memory, UART, etc.)
    );
    
    //------------------------------------------------------------------------
    // AES Crypto Accelerator Instance
    // YOUR SYNTHESIZED DESIGN - NO CHANGES!
    //------------------------------------------------------------------------
    tqvp_aes128_top u_aes (
        // System Interface
        .clk                (clk),
        .rst_n              (rst_n),
        
        // GPIO (unused in this integration)
        .ui_in              (8'h00),
        .uo_out             (),  // Leave unconnected
        
        // Peripheral Bus Interface
        .address            (periph_addr[5:0]),  // Lower 6 bits (64-byte space)
        .data_in            (periph_wdata),
        .data_write_n       ({~(aes_select & periph_write), 
                              ~(aes_select & periph_write)}),  // Active low
        .data_read_n        ({~(aes_select & periph_read), 
                              ~(aes_select & periph_read)}),   // Active low
        .data_out           (aes_rdata),
        .data_ready         (aes_ready),
        
        // Interrupt Output
        .user_interrupt     (aes_interrupt)
    );

endmodule
