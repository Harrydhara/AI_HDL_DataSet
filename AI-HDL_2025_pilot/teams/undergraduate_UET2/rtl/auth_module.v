`timescale 1ns / 1ps

module auth_module(
    input clk,
    input rst,
    input button0,
    input button1,
    input button2,
    input button3,
    output reg auth_valid
);
    
    reg [7:0] stored_code = 8'b00_11_10_11; // Authentication code: 3230
    reg [7:0] input_sequence;
    reg [2:0] index;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            auth_valid <= 0;
            input_sequence <= 8'b0000_0000;
            index <= 0;
        end else if (!auth_valid) begin // Process only if auth_valid is not set
            if (index < 4) begin
                if (button0) begin
                    input_sequence[index*2 +: 2] <= 2'b00;
                    index <= index + 1;
                end else if (button1) begin
                    input_sequence[index*2 +: 2] <= 2'b01; 
                    index <= index + 1;
                end else if (button2) begin
                    input_sequence[index*2 +: 2] <= 2'b10; 
                    index <= index + 1;
                end else if (button3) begin
                    input_sequence[index*2 +: 2] <= 2'b11;
                    index <= index + 1;
                end
            end
            
            if (index == 4) begin
                if (input_sequence == stored_code) begin
                    auth_valid <= 1;
                end else begin
                    auth_valid <= 0;
                end
                input_sequence <= 8'b0000_0000; // Reset input sequence
                index <= 0; // Reset after checking
            end
        end
    end
    
endmodule
