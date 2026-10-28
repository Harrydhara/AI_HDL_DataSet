module stopwatch (  
    input wire clk,  
    input wire rst,  
    input wire start_stop,     // Debounced start/stop button input  
    input wire reset_button,   // Debounced reset button input  
    input wire number1,        // For Button 1  
    input wire number2,        // For Button 2  
    input wire number3,        // For Button 3  
    output reg [15:0] time_out // BCD output for display (MM:SS)  
);  

    // Internal Signals  
    reg [5:0] seconds = 0;    // Seconds count (0-59)  
    reg [5:0] minutes = 0;    // Minutes count (0-59)  
    reg [9:0] hundredths = 0; // 1/100th of a second (0-999)  
    reg running = 0;          // Indicates if the stopwatch is running  
    reg [1:0] password_index = 0; // Tracks which digit of the password is being entered  

    // State definitions using parameters instead of typedef  
    parameter IDLE = 1'b0, VERIFY = 1'b1; 
    parameter index0 = 3'b000, index1 = 3'b001,  index2 = 3'b010, index3 = 3'b011, index4 = 3'b100;
    reg current_state = IDLE; // Current state register  
    reg [3:0] index = index0;

    // State Control Logic  
    always @(posedge clk or posedge rst) begin  
        if (rst) begin  
            running <= 0;  
            password_index = 0;  
            current_state <= IDLE; // Start in IDLE state  
            seconds <= 0;          // Reset seconds  
            minutes <= 0;          // Reset minutes  
            hundredths <= 0;       // Reset hundredths  
        end else begin  
            case (current_state)  
                IDLE: begin  
                    if (start_stop) begin  
                        current_state = VERIFY; // Move to password verification  
                    end  
                end  

                VERIFY: begin
                    case (index)
                        index0: begin
                            if (number1) begin
                                  index = index1;
                        end
                        end
                        index1: begin
                            if (number2) begin
                                  index = index2;
                        end 
                            else if (number1 || number3) begin
                                  index = index0;
                             end
                        end
                        index2: begin
                            if (number3) begin
                                  index = index3;
                        end 
                            else if (number1 || number2) begin
                                  index = index0;
                             end
                        end
                        index3: begin
                            if (number1) begin
                                  index = index4;
                        end 
                            else if (number3 || number2) begin
                                  index = index0;
                             end
                        end
                        index4: begin
                                  running = 1;          // Start the stopwatch  
                                  current_state = IDLE;
                                end
                  endcase

                  end
            endcase  
        end  
    end  

    // Reset and Timing Logic  
    always @(posedge clk or posedge rst) begin  
        if (rst || reset_button) begin  
            hundredths <= 0; // Reset hundredths on reset  
            seconds <= 0;    // Reset seconds on reset  
            minutes <= 0;    // Reset minutes on reset  
            running <= 0;    // Stop the stopwatch  
        end else if (running) begin  
            hundredths <= hundredths + 1; // Increment hundredths of seconds  
            if (hundredths == 999) begin   // If 1 second has passed  
                seconds <= seconds + 1;     // Increment seconds  
                hundredths <= 0;            // Reset hundredths  
                if (seconds == 59) begin  
                    seconds <= 0;           // Reset seconds after 59  
                    minutes <= minutes + 1; // Increment minutes  
                    if (minutes == 59) begin  
                        minutes <= 0;        // Reset minutes after 59  
                    end  
                end  
            end  
        end  
    end  

    // Output MM:SS in BCD format  
    always @(*) begin  
        time_out[15:12] = minutes / 10; // Tens place of minutes  
        time_out[11:8]  = minutes % 10; // Ones place of minutes  
        time_out[7:4]   = seconds / 10; // Tens place of seconds  
        time_out[3:0]   = seconds % 10; // Ones place of seconds  
    end  

endmodule  