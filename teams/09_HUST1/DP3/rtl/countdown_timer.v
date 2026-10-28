module countdown_timer #(
    parameter PRESCALER_WIDTH = 16,
    parameter TIMER_WIDTH = 8
) (
    input wire clk,
    input wire sys_rst_n,
    input wire en,
    // FIX 1: Input width increased to handle value 'PRESCALER_WIDTH' (e.g., 16 needs 5 bits)
    input wire [($clog2(PRESCALER_WIDTH + 1) - 1):0] prescaler,
    input wire [(TIMER_WIDTH - 1):0] duration,
    output wire request_data,
    output wire pulse_out
);
    reg out;
    
    // FIX 2: Removed undefined edge detector. 'out' is already a correct single-cycle pulse.
    assign pulse_out = out;

    // Registers
    reg [(PRESCALER_WIDTH):0] prescaler_counter;
    reg [TIMER_WIDTH:0] counter; 

    // Helper signals
    wire prescaler_overflow = prescaler_counter[PRESCALER_WIDTH];
    wire counter_overflow = counter[TIMER_WIDTH];

    // FIX 3: Shift Logic. Increased padding to PRESCALER_WIDTH.
    // This creates a (PRESCALER_WIDTH + 1) bit vector so the bit is not lost when shifting by max width.
    wire [PRESCALER_WIDTH:0] prescaler_start_count = ({{(PRESCALER_WIDTH){1'b0}}, 1'b1} << prescaler) - {{(PRESCALER_WIDTH-1){1'b0}}, 2'd2};

    wire [TIMER_WIDTH:0] start_count = {1'b0, duration};

    // Request data 1 cycle before reload (when count is 0 and prescaler hits limit)
    assign request_data = en && (counter == {(TIMER_WIDTH+1){1'b0}}) && prescaler_overflow;

    // FIX 4: Proper Async Reset vs Sync Enable separation
    always @(posedge clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            // Asynchronous Reset
            counter <= {(TIMER_WIDTH + 1){1'b0}};
            prescaler_counter <= {(PRESCALER_WIDTH + 1){1'b0}};
            out <= 1'b0;
        end else if (!en) begin
            // Synchronous Reset/Load (Timer Disabled)
            // Loads start values so it is ready to start immediately when en goes high
            counter <= start_count;
            prescaler_counter <= prescaler_start_count;
            out <= 1'b0;
        end else begin
            // Timer Enabled
            if (prescaler_overflow) begin
                prescaler_counter <= prescaler_start_count;
                if (counter_overflow) begin
                    counter <= start_count;
                    out <= 1'b1; // Pulse output high for 1 cycle
                end else begin
                    out <= 1'b0;
                    counter <= counter - 1;
                end
            end else begin
                out <= 1'b0;
                prescaler_counter <= prescaler_counter - 1;
            end
        end
    end

endmodule