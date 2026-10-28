module stopwatch (
    input wire clk_1khz,       
    input wire reset,
    input wire stop_start,
    input wire reset_counter,
    output reg [15:0] bcd_out
);

    //change AI code: because the slow clock's freq is 1Khz, we need to devide it one more time down to 1Hz
    reg [9:0] clk_div_counter = 0;    
    reg enable_1hz = 0;
    //--------------------------------------------------------
    
    
    reg running = 0;
    

    //change AI code: devide slow clock down to 1Hz
    always @(posedge clk_1khz, posedge reset) begin
        if (reset) begin
            clk_div_counter <= 0;
            enable_1hz <= 0;
        end else if (clk_div_counter == 999) begin
            clk_div_counter <= 0;
            enable_1hz <= 1;
        end else begin
            clk_div_counter <= clk_div_counter + 1;
            enable_1hz <= 0;
        end
    end
    //----------------------------------------------------------

    always @(posedge clk_1khz or posedge reset) begin
        if (reset) begin
            running <= 0;
        end else if (stop_start) begin
            running <= ~running;
        end
    end


    always @(posedge clk_1khz or posedge reset) begin
        if (reset) begin
            bcd_out <= 16'b0000_0000_0000_0000; 
        end else if (reset_counter) begin
            bcd_out <= 16'b0000_0000_0000_0000; 
        end else if (enable_1hz && running) begin
            if (bcd_out[7:0] == 8'h59) begin
                bcd_out[7:0] <= 8'h00;
                if (bcd_out[15:8] == 8'h59) begin
                    bcd_out[15:8] <= 8'h00;
                end else begin
                    bcd_out[15:8] <= bcd_out[15:8] + 8'h01;
                end
            end else begin
                bcd_out[7:0] <= bcd_out[7:0] + 8'h01;
            end
        end
    end

endmodule