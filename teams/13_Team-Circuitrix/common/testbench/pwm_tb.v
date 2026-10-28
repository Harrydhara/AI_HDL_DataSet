// this is test benchmark
// ====================================================
// PWM Generator Testbench
// AI-HDL 2026 League - Beginner Level
// ====================================================

`timescale 1ns/1ps

module tb_pwm_generator();

    // Testbench Parameters
    localparam CLK_PERIOD = 10;  // 100 MHz clock
    
    // DUT Parameters
    localparam PWM_WIDTH = 8;
    localparam ADDR_WIDTH = 4;
    localparam DATA_WIDTH = 32;
    
    // Testbench Signals
    reg clk;
    reg rst_n;
    
    // Register Interface
    reg [ADDR_WIDTH-1:0] reg_addr;
    reg [DATA_WIDTH-1:0] reg_wdata;
    reg reg_write;
    reg reg_read;
    wire [DATA_WIDTH-1:0] reg_rdata;
    wire reg_ready;
    
    // PWM Outputs
    wire pwm_out0;
    wire pwm_out1;
    wire pwm_enabled;
    
    // Test Variables
    integer period_value = 100;  // 100 clock cycles period
    integer duty0_value = 25;    // 25% duty cycle
    integer duty1_value = 75;    // 75% duty cycle
    integer error_count = 0;
    integer test_pass_count = 0;
    integer test_fail_count = 0;
    
    // Instantiate DUT
    pwm_generator #(
        .PWM_WIDTH(PWM_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
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
        .pwm_enabled(pwm_enabled)
    );
    
    // Clock Generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Register Write Task
    task write_register;
        input [ADDR_WIDTH-1:0] addr;
        input [DATA_WIDTH-1:0] data;
        begin
            @(posedge clk);
            reg_addr <= addr;
            reg_wdata <= data;
            reg_write <= 1'b1;
            reg_read <= 1'b0;
            @(posedge clk);
            wait(reg_ready);
            reg_write <= 1'b0;
            #10;
        end
    endtask
    
    // Register Read Task
    task read_register;
        input [ADDR_WIDTH-1:0] addr;
        output [DATA_WIDTH-1:0] data;
        begin
            @(posedge clk);
            reg_addr <= addr;
            reg_write <= 1'b0;
            reg_read <= 1'b1;
            @(posedge clk);
            wait(reg_ready);
            data = reg_rdata;
            reg_read <= 1'b0;
            #10;
        end
    endtask
    
    // Reset Task
    task reset_system;
        begin
            rst_n = 1'b0;
            reg_addr = {ADDR_WIDTH{1'b0}};
            reg_wdata = {DATA_WIDTH{1'b0}};
            reg_write = 1'b0;
            reg_read = 1'b0;
            #100;
            rst_n = 1'b1;
            #100;
        end
    endtask
    
    // Check PWM Duty Cycle Task
    task check_pwm_duty;
        input pwm_signal;
        input integer expected_high_cycles;
        input integer period;
        input string pwm_name;
        begin
            integer high_count = 0;
            integer i;
            
            // Wait for PWM to be stable
            @(posedge pwm_enabled);
            #10;
            
            // Count high cycles over one period
            for (i = 0; i < period; i = i + 1) begin
                @(posedge clk);
                if (pwm_signal) high_count = high_count + 1;
            end
            
            // Verify duty cycle
            if (high_count == expected_high_cycles) begin
                $display("[PASS] %s: Duty cycle = %0d/%0d (%0d%%)", 
                         pwm_name, high_count, period, (high_count*100)/period);
                test_pass_count = test_pass_count + 1;
            end else begin
                $display("[FAIL] %s: Expected %0d high cycles, got %0d", 
                         pwm_name, expected_high_cycles, high_count);
                test_fail_count = test_fail_count + 1;
                error_count = error_count + 1;
            end
        end
    endtask
    
    // Main Test Sequence
    initial begin
        $display("========================================");
        $display("PWM Generator Testbench - AI-HDL 2026");
        $display("========================================");
        
        // Initialize
        reset_system();
        
        // Test 1: Register Write/Read Back
        $display("\n[Test 1] Register Read/Write Test");
        write_register(4'h0, 32'h00000007);  // Enable both PWMs
        write_register(4'h4, period_value);  // Set period
        write_register(4'h8, duty0_value);   // Set duty0
        write_register(4'hC, duty1_value);   // Set duty1
        
        begin
            reg [DATA_WIDTH-1:0] read_data;
            read_register(4'h0, read_data);
            if (read_data === 32'h00000007) begin
                $display("[PASS] Control register readback correct");
                test_pass_count = test_pass_count + 1;
            end else begin
                $display("[FAIL] Control register: expected 7, got %h", read_data);
                test_fail_count = test_fail_count + 1;
                error_count = error_count + 1;
            end
        end
        
        // Test 2: PWM Generation
        $display("\n[Test 2] PWM Generation Test");
        #1000; // Let PWM run for a while
        
        // Check PWM0 duty cycle (25%)
        check_pwm_duty(pwm_out0, duty0_value, period_value, "PWM0");
        
        // Check PWM1 duty cycle (75%)
        check_pwm_duty(pwm_out1, duty1_value, period_value, "PWM1");
        
        // Test 3: Disable PWM
        $display("\n[Test 3] PWM Disable Test");
        write_register(4'h0, 32'h00000000);  // Disable PWM
        
        #200;
        if (pwm_out0 === 1'b0 && pwm_out1 === 1'b0) begin
            $display("[PASS] Both PWM outputs are 0 when disabled");
            test_pass_count = test_pass_count + 1;
        end else begin
            $display("[FAIL] PWM outputs not 0 when disabled");
            test_fail_count = test_fail_count + 1;
            error_count = error_count + 1;
        end
        
        // Test 4: Polarity Inversion
        $display("\n[Test 4] Polarity Inversion Test");
        write_register(4'h0, 32'h00000006);  // Enable with inverted polarity
        #500;
        
        // Check that outputs are inverted (should be low for duty, high otherwise)
        if (pwm_out0 === 1'b0 && pwm_out1 === 1'b1) begin
            $display("[PASS] Polarity inversion working");
            test_pass_count = test_pass_count + 1;
        end else begin
            $display("[FAIL] Polarity inversion not working");
            test_fail_count = test_fail_count + 1;
            error_count = error_count + 1;
        end
        
        // Test 5: Boundary Conditions
        $display("\n[Test 5] Boundary Conditions Test");
        write_register(4'h0, 32'h00000001);  // Enable, normal polarity
        write_register(4'h8, 0);             // 0% duty cycle
        write_register(4'hC, period_value);  // 100% duty cycle
        #500;
        
        if (pwm_out0 === 1'b0 && pwm_out1 === 1'b1) begin
            $display("[PASS] Boundary conditions correct");
            test_pass_count = test_pass_count + 1;
        end else begin
            $display("[FAIL] Boundary conditions incorrect");
            test_fail_count = test_fail_count + 1;
            error_count = error_count + 1;
        end
        
        // Summary
        $display("\n========================================");
        $display("Test Summary:");
        $display("  Passed: %0d", test_pass_count);
        $display("  Failed: %0d", test_fail_count);
        $display("  Total:  %0d", test_pass_count + test_fail_count);
        
        if (error_count == 0) begin
            $display("\n✅ All tests PASSED!");
        end else begin
            $display("\n❌ %0d test(s) FAILED!", error_count);
        end
        
        $display("========================================");
        
        // Create waveform file (for simulation viewers)
        $dumpfile("pwm_generator.vcd");
        $dumpvars(0, tb_pwm_generator);
        
        // End simulation
        #1000;
        $finish;
    end
    
    // Monitor for important events
    initial begin
        $monitor("Time=%0t: PWM0=%b, PWM1=%b, Enabled=%b", 
                 $time, pwm_out0, pwm_out1, pwm_enabled);
    end
    
    // Timeout protection
    initial begin
        #100000;
        $display("\n⚠️  Simulation timeout!");
        $finish;
    end

endmodule
