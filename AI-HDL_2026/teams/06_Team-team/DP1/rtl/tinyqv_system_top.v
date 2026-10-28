// `include "tinyqv.v" // Add this at the top of tinyqv_system_top.v
// `include "tt_wrapper.v"
// `include "cpu.v"
// `include "peripheral.v"
// `include "mem_ctrl.v"
// `include "core.v"
// `include "decode.v"
// `include "qspi_ctrl.v"
// `include "counter.v"
// `include "register.v"
// `include "alu.v"

`default_nettype none

module tinyqv_system_top (
    input  wire       clk,
    input  wire       rst_n,

    // SPI Flash/RAM Interface
    input   [3:0] spi_data_in,
    output  [3:0] spi_data_out,
    output  [3:0] spi_data_oe,
    output        spi_clk_out,
    output        spi_flash_select,
    output        spi_ram_a_select,
    output        spi_ram_b_select,

    // VGA Outputs
    output wire [7:0] vga_uo_out,
    input  wire [7:0] vga_ui_in
);

  // Interconnect Wires
  wire [27:0] cpu_data_addr;
  wire [1:0]  cpu_data_write_n;
  wire [1:0]  cpu_data_read_n;
  wire [31:0] cpu_data_out;
  wire [31:0] cpu_data_in;
  wire        cpu_data_ready;
  wire        cpu_data_read_complete; // Driven by CPU 
  wire        cpu_data_continue;

  // Peripheral Interface Wires
  wire [3:0]  peri_address;
  wire [7:0]  peri_data_in;
  wire [7:0]  peri_data_out;
  wire        peri_write_en;

  // 1. Address Decoding Logic
  // Memory is at addr[27:25] == 0[cite: 13]. 
  // We use the "is_mem" logic style from tinyqv.v[cite: 13].
  wire is_peri_addr = (cpu_data_addr[27:25] != 3'b000); 

  assign peri_address  = cpu_data_addr[3:0]; 
  assign peri_data_in  = cpu_data_out[7:0]; 
  assign peri_write_en = is_peri_addr && (cpu_data_write_n != 2'b11); 

  // 2. Bus Feedback to CPU
  // We drive data_in and data_ready back to the CPU [cite: 14]
  assign cpu_data_in    = is_peri_addr ? {24'h0, peri_data_out} : 32'h0;
  assign cpu_data_ready = is_peri_addr ? 1'b1 : 1'b0;

  // 3. Instantiate TinyQV Core
  tinyQV cpu_inst (
      .clk(clk),
      .rstn(rst_n),
      .data_addr(cpu_data_addr),           // Output [cite: 1, 16]
      .data_write_n(cpu_data_write_n),     // Output [cite: 1, 16]
      .data_read_n(cpu_data_read_n),       // Output [cite: 1, 17]
      .data_read_complete(cpu_data_read_complete), // Output 
      .data_out(cpu_data_out),             // Output [cite: 2, 19]
      .data_ready(cpu_data_ready),         // Input [cite: 2, 14]
      .data_in(cpu_data_in),               // Input [cite: 2, 14]
      
      .interrupt_req(4'b0),
      .timer_interrupt(1'b0),

      .spi_data_in(spi_data_in),
      .spi_data_out(spi_data_out),
      .spi_data_oe(spi_data_oe),
      .spi_clk_out(spi_clk_out),
      .spi_flash_select(spi_flash_select),
      .spi_ram_a_select(spi_ram_a_select),
      .spi_ram_b_select(spi_ram_b_select),
      
      // Connect or acknowledge missing debug pins 
      .debug_instr_complete(),             // [cite: 3, 21]
      .debug_instr_ready(),                // [cite: 3, 25]
      .debug_instr_valid(),                // [cite: 3, 21]
      .debug_fetch_restart(),              // [cite: 4, 25]
      .debug_data_ready(),                 // [cite: 4, 25]
      .debug_interrupt_pending(),          // [cite: 4, 21]
      .debug_branch(),                     // [cite: 4, 21]
      .debug_early_branch(),               // [cite: 4, 22]
      .debug_ret(),                        // [cite: 4, 22]
      .debug_reg_wen(),                    // [cite: 4, 22]
      .debug_counter_0(),                  // [cite: 4, 22]
      .debug_data_continue(cpu_data_continue), // [cite: 5, 26]
      .debug_stall_txn(),                  // [cite: 5, 24]
      .debug_stop_txn(),                   // [cite: 5, 24]
      .debug_rd()                          // [cite: 5, 22]
  );

  // 4. Instantiate Your Peripheral
  zyl_vga_generator user_peripheral (
      .clk(clk),
      .rst_n(rst_n),
      .ui_in(vga_ui_in),
      .uo_out(vga_uo_out),
      .address(peri_address),
      .data_write(peri_write_en),
      .data_in(peri_data_in),
      .data_out(peri_data_out)
  );

endmodule
