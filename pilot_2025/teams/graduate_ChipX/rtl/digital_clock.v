// digital_clock.v - 24-hour format digital clock (HH:MM:SS)
module digital_clock(
    input  wire clk_sec,    // 1 Hz clock or pulse
    input  wire reset,      // synchronous reset (resets time to 00:00:00)
    input  wire load,       // load new time when high (one-cycle pulse or held)
    input  wire [4:0] load_h, // new hours (0-23)
    input  wire [5:0] load_m, // new minutes (0-59)
    input  wire [5:0] load_s, // new seconds (0-59)
    output reg  [4:0] hours,  // current hour (5 bits to cover 0-23)
    output reg  [5:0] minutes, // current minute (6 bits for 0-59)
    output reg  [5:0] seconds  // current second (6 bits for 0-59)
);
    always @(posedge clk_sec) begin
        if (reset) begin
            hours   <= 5'd0;
            minutes <= 6'd0;
            seconds <= 6'd0;
        end else if (load) begin
            // Load new time values
            hours   <= (load_h < 24) ? load_h : 5'd0;
            minutes <= (load_m < 60) ? load_m : 6'd0;
            seconds <= (load_s < 60) ? load_s : 6'd0;
        end else begin
            // Normal time increment
            seconds <= seconds + 1;
            if (seconds == 6'd59) begin
                seconds <= 6'd0;
                minutes <= minutes + 1;
                if (minutes == 6'd59) begin
                    minutes <= 6'd0;
                    hours <= hours + 1;
                    if (hours == 5'd23) begin
                        hours <= 5'd0;
                    end
                end
            end
        end
    end
endmodule
