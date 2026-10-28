// alarm_clock.v - Alarm time set and trigger
module alarm_clock(
    input  wire        clk,        // use system clock for internal timing if needed
    input  wire        reset,
    input  wire [4:0]  curr_h,     // current hour (0-23)
    input  wire [5:0]  curr_m,     // current minute (0-59)
    input  wire [5:0]  curr_s,     // current second (0-59)
    input  wire [4:0]  set_h,      // desired alarm hour (0-23)
    input  wire [5:0]  set_m,      // desired alarm minute (0-59)
    input  wire        load_alarm, // pulse: load set_h,set_m into alarm time
    input  wire        enable,     // alarm enable switch (1=on, 0=off)
    input  wire        stop_alarm, // user acknowledging the alarm (turn off)
    output reg         alarm_on,   // alarm armed indicator (internal state)
    output reg         alarm_trigger // goes high when alarm time reached and alarm is on
);
    // Registers to store the alarm time (HH:MM)
    reg [4:0] alarm_h = 5'd0;
    reg [5:0] alarm_m = 6'd0;
    
    always @(posedge clk) begin
        if (reset) begin
            alarm_h <= 5'd0;
            alarm_m <= 6'd0;
            alarm_on <= 1'b0;
            alarm_trigger <= 1'b0;
        end else begin
            // Load new alarm time when requested
            if (load_alarm) begin
                alarm_h <= (set_h < 24) ? set_h : 5'd0;
                alarm_m <= (set_m < 60) ? set_m : 6'd0;
            end
            // Update alarm armed status based on enable switch
            if (enable)
                alarm_on <= 1'b1;
            else begin
                alarm_on <= 1'b0;
                alarm_trigger <= 1'b0;  // disable alarm if turning off
            end

            // Check if current time matches alarm time and alarm is armed
            if (alarm_on && (curr_h == alarm_h) && (curr_m == alarm_m) && (curr_s == 6'd0)) begin
                alarm_trigger <= 1'b1;  // Trigger alarm at the exact minute (when seconds = 00)
            end

            // Stop alarm when user presses stop and alarm is currently triggered
            if (stop_alarm) begin
                alarm_trigger <= 1'b0;
            end
        end
    end
endmodule
