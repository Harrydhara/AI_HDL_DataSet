module convert_12_to_24 (
    input wire clk,              // Clock signal
    input wire rst,              // Reset
    input wire convert_mode,     // Conversion mode (0: 24h, 1:12h)
    input wire [15:0] time_in,   // Input time (24h HHMM format)
    output reg [15:0] time_out   // Output time(depending on the mode)
);

    //------------------------------------------
    // Variable Declarations
    //------------------------------------------
    reg [3:0] hours_24_high;  // Tens digit of 24h hours (BCD)
    reg [3:0] hours_24_low;   // Ones digit of 24h hours (BCD)
    reg [3:0] hours_12_high;  // Tens digit of 12h hours (BCD)
    reg [3:0] hours_12_low;   // Ones digit of 12h hours (BCD)
    reg [7:0] hours_24;       // 24h hours (integer format)
    reg [7:0] hours_12;       // 12h hours (integer format)

    //------------------------------------------
    //24h to 12h Conversion Logic (Synchronous with clock)
    //------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            time_out <= 16'h0000;
        end else begin
            if (convert_mode == 1) begin 
                
                // Extract 24h hours from time_in (BCD format)
                hours_24_high = time_in[15:12]; // Tens digit
                hours_24_low  = time_in[11:8];  // Ones digit
                hours_24 = hours_24_high * 10 + hours_24_low; // Convert to integer

                // Hour Conversion Logic
                if (hours_24 == 0) begin         // 00:00 -> 12 AM
                    hours_12 = 12;
                end 
                else if (hours_24 == 12) begin  // 12:00 -> 12 PM
                    hours_12 = 12;
                end 
                else if (hours_24 > 12) begin   // PM (13-23)
                    hours_12 = hours_24 - 12;   // Subtract 12 to convert to 12h format
                end 
                else begin                      // AM (01-11)
                    hours_12 = hours_24;
                end

                // Convert 12h hours to BCD format
                hours_12_high = hours_12 / 10;  // Tens digit
                hours_12_low  = hours_12 % 10;  // Ones digit

                // Combine hours and minutes (HHMM format)
                time_out <= {hours_12_high, hours_12_low, time_in[7:0]};
            end 
            else begin 
                // 24h Mode (keep input time as is)
                time_out <= time_in;
            end
        end
    end

endmodule