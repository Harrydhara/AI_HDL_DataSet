`timescale 1ns / 1ps

module clock_timezone(
    input wire clk_1kHz,                  // 1 kHz clock signal
    input wire clk_1Hz,                   // 1 Hz clock signal
    input wire rst,                       // Reset signal
    input wire set_time,                  // Driven by debounced_BTN_C
    input wire set_timezone,              // Signal to toggle timezone adjustment mode
    input wire signed [4:0] timezone_select, // Timezone offset selection (-12 to +12)
    input wire debounced_BTN_L,           // Increment hours / decrement timezone
    input wire debounced_BTN_R,           // Increment minutes / increment timezone
    output reg [5:0] hours,               // Adjusted hours (0-23)
    output reg [5:0] minutes,             // Adjusted minutes (0-59)
    output reg signed [4:0] timezone_offset, // Timezone offset (-12 to +12)
    output reg set_time_mode,             // Tracks set_time mode
    output reg timezone_set_mode,         // Now an output to share state
    output reg long_press_active_clock,   // Changed from long_press_active
    input wire [1:0] current_digit,       // New input for synchronization
    output reg [5:0] hours_reg_out,       // Exposes raw internal hours_reg
    output reg [5:0] minutes_reg_out      // Exposes raw internal minutes_reg
);

    // Internal registers
    reg [5:0] hours_reg;                  // Internal register for raw hours (0-23)
    reg [5:0] minutes_reg;                // Internal register for raw minutes (0-59)
    reg BTN_L_prev, BTN_R_prev;           // Edge detection for BTN_L and BTN_R
    reg set_time_prev;                    // Tracks previous state of set_time
    reg set_timezone_prev;                // Tracks previous state of set_timezone
    reg [15:0] hold_counter_hour;         // Counter for BTN_L hold duration
    reg [15:0] hold_counter_minute;       // Counter for BTN_R hold duration
    reg [9:0] second_counter;             // Counts up to 999 for real-time updates

    // Consolidated logic for updating hours_reg, minutes_reg, and timezone_offset
    always @(posedge clk_1kHz or posedge rst) begin
        if (rst) begin
            hours_reg <= 0;
            minutes_reg <= 0;
            second_counter <= 0;
            timezone_offset <= 0;
            hold_counter_hour <= 16'd0;
            hold_counter_minute <= 16'd0;
            long_press_active_clock <= 1'b0;
        end else begin
            if (!set_time_mode) begin
                if (second_counter == 999) begin
                    second_counter <= 0;
                    if (minutes_reg == 59) begin
                        minutes_reg <= 0;
                        hours_reg <= (hours_reg == 23) ? 0 : hours_reg + 1;
                    end else begin
                        minutes_reg <= minutes_reg + 1;
                    end
                end else begin
                    second_counter <= second_counter + 1;
                end
            end else begin
                if (debounced_BTN_L) begin
                    hold_counter_hour <= hold_counter_hour + 16'd1;
                    if (hold_counter_hour == 16'd1) begin
                        hours_reg <= (hours_reg == 23) ? 0 : hours_reg + 1;
                    end else if (hold_counter_hour >= 16'd1000) begin
                        long_press_active_clock <= 1'b1;
                        if ((hold_counter_hour % 16'd50 == 0) && (current_digit == 2'b00)) begin
                            hours_reg <= (hours_reg == 23) ? 0 : hours_reg + 1;
                        end
                    end
                end else begin
                    hold_counter_hour <= 16'd0;
                end

                if (debounced_BTN_R) begin
                    hold_counter_minute <= hold_counter_minute + 16'd1;
                    if (hold_counter_minute >= 16'd1000) begin
                        if ((hold_counter_minute % 16'd50 == 0) && (current_digit == 2'b00)) begin
                            minutes_reg <= (minutes_reg == 59) ? 0 : minutes_reg + 1;
                        end
                    end else if (hold_counter_minute == 16'd1) begin
                        minutes_reg <= (minutes_reg == 59) ? 0 : minutes_reg + 1;
                    end
                end else begin
                    hold_counter_minute <= 16'd0;
                end

                if (!debounced_BTN_L && !debounced_BTN_R) begin
                    long_press_active_clock <= 1'b0;
                end
            end

            if (timezone_set_mode) begin
                if (debounced_BTN_R && !BTN_R_prev) begin
                    if (timezone_offset < 12) begin
                        timezone_offset <= timezone_offset + 1;
                    end
                end
                if (debounced_BTN_L && !BTN_L_prev) begin
                    if (timezone_offset > -12) begin
                        timezone_offset <= timezone_offset - 1;
                    end
                end
            end
        end
    end

    // Edge detection for set_time_mode
    always @(posedge clk_1kHz or posedge rst) begin
        if (rst) begin
            set_time_mode <= 0;
            set_time_prev <= 0;
        end else begin
            if (set_time && !set_time_prev) begin
                set_time_mode <= ~set_time_mode;
            end
            set_time_prev <= set_time;
        end
    end

    // Edge detection for timezone_set_mode
    always @(posedge clk_1kHz or posedge rst) begin
        if (rst) begin
            timezone_set_mode <= 0;
            set_timezone_prev <= 0;
        end else begin
            if (set_timezone && !set_timezone_prev) begin
                timezone_set_mode <= ~timezone_set_mode;
            end
            set_timezone_prev <= set_timezone;
        end
    end

    // Edge detection for BTN_L and BTN_R
    always @(posedge clk_1kHz or posedge rst) begin
        if (rst) begin
            BTN_L_prev <= 0;
            BTN_R_prev <= 0;
        end else begin
            BTN_L_prev <= debounced_BTN_L;
            BTN_R_prev <= debounced_BTN_R;
        end
    end

    // Combined logic for adjusting hours and minutes
    always @(*) begin
        if (set_time_mode) begin
            hours = hours_reg;
            minutes = minutes_reg;
        end else begin
            hours = ($signed(hours_reg) + timezone_offset + 24) % 24;
            minutes = minutes_reg;
        end
        hours_reg_out = hours_reg;
        minutes_reg_out = minutes_reg;
    end

endmodule