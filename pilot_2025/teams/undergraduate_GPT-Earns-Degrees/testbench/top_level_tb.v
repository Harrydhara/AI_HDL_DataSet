module tb_top_level;

    // Declare the signals to connect to the top_level module
    reg clk_100mhz;              // 100 MHz clock input
    reg button0;                 // Start/Stop button input
    reg button1;                 // Reset button input
    wire [3:0] anodes;           // Anode control signals for the 4 SSDs
    wire [6:0] segments;         // Segment control signals (a-g)

    // Instantiate the top_level module
    top_level uut (
        .clk_100mhz(clk_100mhz),
        .button0(button0),
        .button1(button1),
        .anodes(anodes),
        .segments(segments)
    );

    // Clock generation: Generate a 100 MHz clock (simulate 100 MHz clock input)
    always begin
        #5 clk_100mhz = ~clk_100mhz;  // Toggle every 5 time units to simulate 100 MHz
    end

    // Initial block to define the test procedure
    initial begin
        // Initialize signals
        clk_100mhz = 0;
        button0 = 0;  // Start/Stop button initially not pressed
        button1 = 0;  // Reset button initially not pressed

        // Apply reset to the design (simulate reset behavior)
        $display("Applying reset...");
        #10 button1 = 1;  // Assert reset (reset the stopwatch)
        #10 button1 = 0;  // Release reset
        #50;  // Wait a few cycles to observe reset behavior
        $display("After reset, Stopwatch should show 00:00.");

        // Test 1: Press Reset (button1) at 100 ns
        $display("Pressing Reset button (button1) at 100 ns...");
        #100 button1 = 1;  // Press Reset at 100 ns
        #10 button1 = 0;   // Release Reset
        #50;  // Wait to verify stopwatch is reset to 00:00
        $display("After pressing Reset button, Stopwatch should show 00:00.");

        // Test 2: Press Start/Stop (button0) at 200 ns to start the stopwatch
        $display("Pressing Start/Stop button (button0) at 200 ns...");
        #100 button0 = 1;  // Press Start/Stop at 200 ns
        #10 button0 = 0;   // Release Start/Stop button
        #200;  // Wait for a few clock cycles (simulate time passing)
        $display("After pressing Start/Stop button at 200 ns, Stopwatch should show 00:00.");

        // Test 3: Press Start/Stop (button0) again at 400 ns to stop the stopwatch
        $display("Pressing Start/Stop button (button0) at 400 ns...");
        #100 button0 = 1;  // Press Start/Stop at 400 ns to stop the stopwatch
        #10 button0 = 0;   // Release Start/Stop button
        #50;  // Wait to observe the stopwatch stopping
        $display("After pressing Start/Stop button at 400 ns, Stopwatch should show 00:00 and stop counting.");

        // Test 4: Press Reset (button1) at 600 ns
        $display("Pressing Reset button (button1) at 600 ns...");
        #100 button1 = 1;  // Press Reset at 600 ns
        #10 button1 = 0;   // Release Reset
        #50;  // Wait to verify stopwatch is reset to 00:00
        $display("After pressing Reset button at 600 ns, Stopwatch should show 00:00.");

        // Test 5: Press Start/Stop (button0) again at 800 ns to start the stopwatch
        $display("Pressing Start/Stop button (button0) at 800 ns...");
        #100 button0 = 1;  // Press Start/Stop at 800 ns
        #10 button0 = 0;   // Release Start/Stop button
        #50;  // Wait for a few clock cycles (simulate time passing)
        $display("After pressing Start/Stop button at 800 ns, Stopwatch should show 00:00.");

        // Finish the simulation
        $display("Simulation complete.");
        $finish;
    end
endmodule
