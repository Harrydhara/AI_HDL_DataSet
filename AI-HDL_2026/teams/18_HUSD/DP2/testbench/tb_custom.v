`default_nettype none
`timescale 1ns / 1ps

module tb_custom ();

    // =====================================================================
    // 1. COCOTB / PYTHON INTERFACE (PASSIVE)
    // =====================================================================
    reg        clk;
    reg        rst_n;
    reg        ena;
    reg  [7:0] ui_in;
    reg  [7:0] uio_in;
    wire [7:0] uo_out;
    wire [7:0] uio_out;
    wire [7:0] uio_oe;

    tt_um_tqv_peripheral_harness dut (
        .ui_in  (ui_in),
        .uo_out (uo_out),
        .uio_in (uio_in),
        .uio_out(uio_out),
        .uio_oe (uio_oe),
        .ena    (ena),
        .clk    (clk),
        .rst_n  (rst_n)
    );

    // =====================================================================
    // 2. ADVANCED VERILOG TEST INTERFACE (ACTIVE)
    // =====================================================================
    reg  [7:0]  adv_ui_in;
    wire [7:0]  adv_uo_out;
    reg  [5:0]  adv_address;
    reg  [31:0] adv_data_in;
    reg  [1:0]  adv_data_write_n;
    reg  [1:0]  adv_data_read_n;
    wire [31:0] adv_data_out;
    wire        adv_data_ready;
    wire        adv_user_interrupt;
    
    uart_controller adv_dut (
        .clk(clk),
        .rst_n(rst_n),
        .ui_in(adv_ui_in),
        .uo_out(adv_uo_out),
        .address(adv_address),
        .data_in(adv_data_in),
        .data_write_n(adv_data_write_n),
        .data_read_n(adv_data_read_n),
        .data_out(adv_data_out),
        .data_ready(adv_data_ready),
        .user_interrupt(adv_user_interrupt)
    );

    // --- Bus Helpers (Synchronous to Clock) ---
    task write_reg(input [5:0] addr, input [31:0] data);
        begin
            @(posedge clk);
            adv_address      <= addr;
            adv_data_in      <= data;
            adv_data_write_n <= 2'b00;
            wait(adv_data_ready == 1'b1);
            @(posedge clk);
            adv_data_write_n <= 2'b11; 
            wait(adv_data_ready == 1'b0);
        end
    endtask

    task read_reg(input [5:0] addr, output [31:0] data);
        begin
            @(posedge clk);
            adv_address     <= addr;
            adv_data_read_n <= 2'b00; 
            wait(adv_data_ready == 1'b1);
            data <= adv_data_out;
            @(posedge clk);
            adv_data_read_n <= 2'b11; 
            wait(adv_data_ready == 1'b0);
        end
    endtask

    // --- Advanced Test Sequence ---
    reg [31:0] read_val;

    initial begin
        $dumpfile("tb_custom.vcd");
        $dumpvars(0, tb_custom);

        adv_ui_in        = 8'h01; // RX idles high
        adv_address      = 6'b0;
        adv_data_in      = 32'b0;
        adv_data_write_n = 2'b11;
        adv_data_read_n  = 2'b11;

        // Wait for Cocotb to release reset
        wait(rst_n == 1'b0);
        wait(rst_n == 1'b1);

        repeat(5) @(posedge clk);
        
        $display("\n==================================================");
        $display(" VERILOG ADVANCED CONDITIONS STARTING ");
        $display("==================================================");

        // --- TEST 1: Zero Divisor Fallback ---
        $display("[TEST 1] Zero Divisor Safety Check");
        write_reg(6'h08, 32'd0); 
        repeat(2) @(posedge clk);
        
        if (adv_dut.div_load_val == 32'd100) 
            $display(" -> PASS: Internal div_load_val successfully defaulted to 100.");
        else 
            $display(" -> FAIL: Divisor fallback failed.");

        // --- TEST 2: Half-Duplex Operation (Sequential TX then RX) ---
        $display("\n[TEST 2] Half-Duplex Operation (Sequential TX then RX)");
        write_reg(6'h08, 32'd10); 
        
        write_reg(6'h00, 32'h000000AA); 
        $display(" -> TX started (Sending 0xAA).");

        // Dynamically wait for hardware to flag completion
        wait(adv_dut.tx_busy == 1'b1);
        wait(adv_dut.tx_busy == 1'b0);
        $display(" -> TX completed successfully.");
        
        repeat(5) @(posedge clk);
        // Small buffer

        $display(" -> RX started (Receiving perfectly matched 0x00).");
        // Pull line low on the negative edge to prevent simulation race conditions
        @(negedge clk);
        adv_ui_in[0] = 1'b0; 
        
        // Dynamically wait for the UART hardware to finish its entire state machine
        wait(adv_dut.rx_valid == 1'b1);

        if (adv_dut.rx_shifter == 8'h00)
            $display(" -> PASS: RX received 0x00 correctly!");
        else
            $display(" -> FAIL: RX data corrupted. Got 0x%h", adv_dut.rx_shifter);

        // Restore idle line immediately upon completion
        @(negedge clk);
        adv_ui_in[0] = 1'b1;

        // --- TEST 3: State Machine Recovery ---
        $display("\n[TEST 3] RX State Machine Recovery");
        // Read the RX register to ensure the bus interface clears the valid flag
        read_reg(6'h0C, read_val);

        repeat(2) @(posedge clk);
        if (adv_dut.rx_valid == 1'b0)
            $display(" -> PASS: rx_valid correctly cleared after read. State machine is stable.");
        else
            $display(" -> FAIL: rx_valid stuck high.");
            
        // --- TEST 4: User Interrupt Latch and Clear ---
        $display("\n[TEST 4] User Interrupt Logic (ui_in[6] -> user_interrupt)");
        
        // 1. Trigger the interrupt via hardware input
        @(negedge clk);
        adv_ui_in[6] = 1'b1; 
        @(negedge clk);
        adv_ui_in[6] = 1'b0; // Release the pin
        
        // Wait a cycle for the sequential logic to register the input
        @(posedge clk);
        
        // 2. Verify the interrupt latched and propagated to the output wire
        if (adv_dut.test_irq_latched == 1'b1 && adv_user_interrupt == 1'b1)
            $display(" -> PASS: test_irq_latched asserted and propagated to user_interrupt.");
        else
            $display(" -> FAIL: Interrupt failed to latch or propagate. latched: %b, int: %b", 
                     adv_dut.test_irq_latched, adv_user_interrupt);
            
        // 3. Clear the interrupt via software (Bus Write)
        // Writing to ADDR_CTRL (6'h08) with data_in[0] = 1 to trigger the clear logic
        write_reg(6'h08, 32'd1); 
        
        repeat(2) @(posedge clk);
        
        // 4. Verify the interrupt was successfully cleared
        if (adv_dut.test_irq_latched == 1'b0 && adv_user_interrupt == 1'b0)
            $display(" -> PASS: test_irq_latched successfully cleared via ADDR_CTRL.");
        else
            $display(" -> FAIL: Interrupt failed to clear. latched: %b, int: %b", 
                     adv_dut.test_irq_latched, adv_user_interrupt);

        $display("\n==================================================");
        $display(" ALL ADVANCED TESTS COMPLETED ");
        $display("==================================================");
    end

endmodule