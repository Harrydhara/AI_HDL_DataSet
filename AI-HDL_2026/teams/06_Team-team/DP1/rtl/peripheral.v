/*
 * Copyright (c) 2026 Team Team
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

// Change the name of this module to something that reflects its functionality and includes your name for uniqueness
// For example tqvp_yourname_spi for an SPI peripheral.
// Then edit tt_wrapper.v line 38 and change tqvp_example to your chosen module name.
module zyl_vga_generator (
    input  wire       clk,        
    input  wire       rst_n,      
    input  wire [7:0] ui_in,      
    output wire [7:0] uo_out,     
    input  wire [3:0] address,    
    input  wire       data_write, 
    input  wire [7:0] data_in,    
    output reg  [7:0] data_out    
);
    localparam H_VISIBLE = 1627; // 640 * 2.54
    localparam H_FRONT   = 41;   // 16  * 2.54
    localparam H_SYNC    = 244;  // 96  * 2.54
    localparam H_BACK    = 122;  // 48  * 2.54
    localparam H_TOTAL   = 2034;

    localparam V_VISIBLE = 480;  // Vertical stays same (lines)
    localparam V_FRONT   = 10;
    localparam V_SYNC    = 2;
    localparam V_BACK    = 33;
    localparam V_TOTAL   = 525;
    // 1. Registers for CPU Control
    reg [7:0] reg_color;
    reg       display_en;

    // Handle SPI/CPU Writes
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_color <= 8'h0;
            display_en <= 1'b0;
        end else if (data_write) begin
            case (address)
                4'h0: reg_color  <= data_in; // CPU sets color
                4'h1: display_en <= data_in[0]; // CPU turns on/off
                default : ; //%Warning-CASEINCOMPLETE: peripheral.v:42:13: Case values incompletely covered (example pattern 0x2)
                            //    42 |             case (address)
                            //        |             ^~~~
                            //                            ... For warning description see https://verilator.org/warn/CASEINCOMPLETE?v=5.020
                            //                            ... Use "/* verilator lint_off CASEINCOMPLETE */" and lint_on around source to disable this message.
                            //    %Error: Exiting due to 1 warning(s)
            endcase
        end
    end

    // 2. VGA Timing Logic
    // Using 64MHz timing parameters (calculated for 640x480 resolution)
    reg [10:0] h_cnt; // Needs to go up to ~2033
    reg [9:0]  v_cnt;
    wire h_sync, v_sync, video_active;

    // Horizontal Counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) h_cnt <= 0;
        else if (h_cnt == H_TOTAL - 1) h_cnt <= 0;
        else h_cnt <= h_cnt + 1;
    end

    // Vertical Counter (increments when H-counter finishes a line)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) v_cnt <= 0;
        else if (h_cnt == H_TOTAL - 1) begin
        if (v_cnt == V_TOTAL - 1) v_cnt <= 0;
        else v_cnt <= v_cnt + 1;
        end
    end
    // Sync pulses are usually active low for 640x480
    
    assign h_sync = !((h_cnt >= H_VISIBLE + H_FRONT) && (h_cnt < H_VISIBLE + H_FRONT + H_SYNC));
    assign v_sync = !((v_cnt >= V_VISIBLE + V_FRONT) && (v_cnt < V_VISIBLE + V_FRONT + V_SYNC));
    
    // Handle CPU Reads
    always @(*) begin
        case (address)
            4'h0: data_out = reg_color;   // Allow CPU to read back the current color
            4'h1: data_out = {7'b0, display_en}; // Read back enable status
            default: data_out = 8'h00;    // Drive unused addresses to 0
        endcase
    end
    // Only output colors when within the 640x480 visible box
    assign video_active = (h_cnt < H_VISIBLE) && (v_cnt < V_VISIBLE);
    // 3. Mapping to uo_out
    // uo_out[7:6] = 0, uo_out[5]=VSYNC, uo_out[4]=HSYNC, uo_out[3]=B, uo_out[2]=G, uo_out[1]=R, uo_out[0]=0
    assign uo_out[0]   = 1'b0; // Spare
    assign uo_out[3:1] = video_active ? reg_color[2:0] : 3'b000; 
    assign uo_out[4]   = h_sync;
    assign uo_out[5]   = v_sync;
    assign uo_out[7:6] = 2'b00;

endmodule