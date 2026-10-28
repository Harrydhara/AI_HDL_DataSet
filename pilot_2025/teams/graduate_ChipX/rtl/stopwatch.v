// stopwatch.v - Stopwatch with start/stop toggle and reset (counts up to 9:59.9)
module stopwatch(
    input  wire clk_10hz,    // 0.1s tick (10 Hz clock enable)
    input  wire reset,
    input  wire start_stop,  // input pulse to toggle running state
    output reg [3:0] min,    // minutes (0-9)
    output reg [3:0] sec_tens, // tens of seconds (0-5)
    output reg [3:0] sec_ones, // ones of seconds (0-9)
    output reg [3:0] tenths    // tenths of seconds (0-9)
);

    reg running = 0;

    always @(posedge clk_10hz or posedge reset) begin
        if (reset) begin
            // Reset stopwatch time and running state
            min      <= 4'd0;
            sec_tens <= 4'd0;
            sec_ones <= 4'd0;
            tenths   <= 4'd0;
            running  <= 1'b0;
        end else if (start_stop) begin
            // Toggle running state on a one-clock pulse
            running <= ~running;
        end

        // If running, increment time
        if (running) begin
            if (tenths == 4'd9) begin
                tenths <= 4'd0;
                if (sec_ones == 4'd9) begin
                    sec_ones <= 4'd0;
                    if (sec_tens == 4'd5) begin
                        sec_tens <= 4'd0;
                        if (min == 4'd9) begin
                            // If max time 9:59.9 reached, roll back to 0:00.0
                            min <= 4'd0;
                        end else begin
                            min <= min + 1;
                        end
                    end else begin
                        sec_tens <= sec_tens + 1;
                    end
                end else begin
                    sec_ones <= sec_ones + 1;
                end
            end else begin
                tenths <= tenths + 1;
            end
        end
    end
endmodule
