`timescale 1ns / 1ps

module clock_timezone (
    input wire clk,                // 2 kHz clock signal
    input wire rst,                // Reset signal (active high)
    input wire set_time_en,         // Enable setting time
    input wire [15:0] set_time,     // Time input (HHMM BCD format)
    input wire [3:0] timezone,      // Timezone offset in 4-bit format (0000 = -8, 1111 = +7)
    output reg [15:0] current_time, // Current time in HHMM BCD format
    output reg [15:0] adjusted_time // Adjusted time with timezone
);

    integer sec_counter; // Counts clock cycles to track 1 second
    reg [3:0] hh_tens, hh_ones, mm_tens, mm_ones;
    reg [3:0] next_hh_tens, next_hh_ones, next_mm_tens, next_mm_ones;
    integer adjusted_hours;
    integer timezone_offset;
    localparam CLOCK_DIVISOR      = 32'd1;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_time <= 16'h0000; 
            adjusted_time <= 16'h0000;
            sec_counter <= 0;
        end else if (set_time_en) begin
            current_time <= set_time; 
            sec_counter <= 0;  // Reset counter when setting time
        end else begin
            sec_counter <= sec_counter + 1;
            
            // Increment time every 2000 cycles (since clk = 2 kHz, this equals 1 second)
            if (sec_counter >= CLOCK_DIVISOR) begin
                sec_counter <= 0;

                // Extract BCD components for easy manipulation
                hh_tens = current_time[15:12]; 
                hh_ones = current_time[11:8];  
                mm_tens = current_time[7:4];   
                mm_ones = current_time[3:0];   

                // Default: Keep the current values
                next_hh_tens = hh_tens;
                next_hh_ones = hh_ones;
                next_mm_tens = mm_tens;
                next_mm_ones = mm_ones;

                // **Handle minute increment**
                if (mm_ones == 4'd9) begin
                    next_mm_ones = 4'd0; // Reset ones place

                    if (mm_tens == 4'd5) begin
                        next_mm_tens = 4'd0; // Reset tens place and increment hour

                        // **Handle hour increment**
                        if ((hh_tens == 4'd2) && (hh_ones == 4'd3)) begin
                            // 23:59 ? 00:00
                            next_hh_tens = 4'd0;
                            next_hh_ones = 4'd0;
                        end else if (hh_ones == 4'd9) begin
                            // 09, 19 ? 10, 20
                            next_hh_ones = 4'd0;
                            next_hh_tens = hh_tens + 4'd1;
                        end else begin
                            // Normal increment
                            next_hh_ones = hh_ones + 4'd1;
                        end
                    end else begin
                        // Increment minute tens place
                        next_mm_tens = mm_tens + 4'd1;
                    end
                end else begin
                    // Normal increment of minute ones place
                    next_mm_ones = mm_ones + 4'd1;
                end

                // **Update current time with new BCD values**
                current_time <= {next_hh_tens, next_hh_ones, next_mm_tens, next_mm_ones};

                // Convert 4-bit timezone input (0000 = -8, 1111 = +7) to signed offset
                timezone_offset = timezone - 8;
                
                // Apply timezone offset (hour adjustment)
                adjusted_hours = (next_hh_tens * 10 + next_hh_ones) + timezone_offset;
                if (adjusted_hours < 0) adjusted_hours = adjusted_hours + 24;
                if (adjusted_hours >= 24) adjusted_hours = adjusted_hours - 24;
                
                next_hh_tens = adjusted_hours / 10;
                next_hh_ones = adjusted_hours % 10;

                // **Update adjusted time with new BCD values**
                adjusted_time <= {next_hh_tens, next_hh_ones, next_mm_tens, next_mm_ones};
            end
        end
    end

endmodule

