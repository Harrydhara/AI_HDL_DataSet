module macc (
    input  wire        clk,
    input  wire        rst_n,

    input  wire        cs,        
    input  wire        we,        
    input  wire [3:0]  addr,      
    input  wire [31:0] wdata,
    output reg  [31:0] rdata
);

    // Registers
    reg [31:0] reg_a;
    reg [31:0] reg_b;
    reg [31:0] acc;
    reg        start;
    reg        clear;
    reg        done;

    // Simple FSM: combinational multiply, registered accumulate
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_a <= 32'd0;
            reg_b <= 32'd0;
            acc   <= 32'd0;
            start <= 1'b0;
            clear <= 1'b0;
            done  <= 1'b0;
        end else begin
            // default
            start <= 1'b0;
            clear <= 1'b0;
            done  <= 1'b0;

            // writes
            if (cs && we) begin
                case (addr)
                    4'h0: reg_a <= wdata;
                    4'h1: reg_b <= wdata;
                    4'h3: begin
                        start <= wdata[0];
                        clear <= wdata[1];
                    end
                endcase
            end

            // clear accumulator
            if (clear) begin
                acc <= 32'd0;
            end

            // perform MACC on start
            if (start) begin
                acc  <= acc + (reg_a * reg_b);
                done <= 1'b1;
            end
        end
    end

    // reads
    always @(*) begin
        rdata = 32'd0;
        if (cs) begin
            case (addr)
                4'h0: rdata = reg_a;
                4'h1: rdata = reg_b;
                4'h2: rdata = acc;
                4'h3: rdata = {23'd0, done, 7'd0}; // done in bit 8
                default: rdata = 32'd0;
            endcase
        end
    end

endmodule
