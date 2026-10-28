`default_nettype none

module tqvp_htfab_anatool (
    input  wire       clk,        // Clock
    input  wire       rst_n,      // Reset_n
    input  wire [7:0] ui_in,      // Input PMOD
    output wire [7:0] uo_out,     // Output PMOD
    input  wire [3:0] address,    // Address
    input  wire       data_write, // Write Enable
    input  wire [7:0] data_in,    // Data In
    output wire [7:0] data_out    // Data Out
);

    reg [7:0] step;
    reg [2:0] channel;
    reg       duty_rst_n;

    wire [7:0] fp_time;
    wire [7:0] fp_duty;

    // FIX 1 & 2: Added explicit port mapping (fixed .name syntax error)
    // FIX 3: Defined the missing submodule (see bottom of code)
    fp_counter fp_time_i (
        .clk     (clk),
        .rst_n   (rst_n),
        .step    (step),
        .step_en (1'b1),
        .value   (fp_time)
    );

    fp_counter fp_duty_i (
        .clk     (clk),
        .rst_n   (rst_n & duty_rst_n), // Logic inside port map is valid
        .step    (step),
        .step_en (ui_in[channel]),     // Dynamic bit selection is valid
        .value   (fp_duty)
    );

    reg [7:0] in_duty;
    reg [7:0] out_duty [0:2]; // FIX 4: Clarified array range [0:2]

    always @(posedge clk) begin
        if (!rst_n) begin
            step        <= 0;
            out_duty[0] <= 8'h80;
            out_duty[1] <= 8'h80;
            out_duty[2] <= 8'h80;
            channel     <= 0;
        end else if (data_write) begin
            if (address == 4) begin
                step <= data_in;
            end else if (address == 5) begin
                channel <= data_in[2:0];
            // FIX 5: Added bounds check to prevent memory corruption
            end else if (address < 3) begin 
                // FIX 6: Removed SystemVerilog cast "2'(address)"
                out_duty[address] <= data_in; 
            end
        end
    end

    wire roll = fp_time[7];
    reg last_roll;

    always @(posedge clk) begin
        if (!rst_n) begin
            last_roll  <= 0;
            duty_rst_n <= 0;
            in_duty    <= 0; // FIX 7: Initialize in_duty to prevent latch/unknowns
        end else begin
            last_roll <= roll;
            if (last_roll && !roll) begin
                in_duty    <= fp_duty;
                duty_rst_n <= 0;
            end else begin
                duty_rst_n <= 1;
            end
        end
    end

    wire [2:0] out_bank;
    assign out_bank[0] = fp_time < out_duty[0];
    assign out_bank[1] = fp_time < out_duty[1];
    assign out_bank[2] = fp_time < out_duty[2];

    assign uo_out   = {out_bank, !ui_in[4], out_bank, ui_in[0]};
    assign data_out = in_duty;

endmodule

// FIX 8: Added the missing submodule definition
module fp_counter (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] step,
    input  wire       step_en,
    output reg  [7:0] value
);
    always @(posedge clk) begin
        if (!rst_n) 
            value <= 0;
        else if (step_en) 
            value <= value + step;
    end
endmodule
