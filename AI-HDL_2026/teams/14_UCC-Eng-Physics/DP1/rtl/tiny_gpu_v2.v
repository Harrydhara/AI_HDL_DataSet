module tiny_gpu #(
    parameter MEM_SIZE = 16
)(
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    input  wire [2:0]  opcode,
    output reg         done,
    output wire [31:0] result_out
);

    // -------------------------------
    // Width-safe parameters
    // -------------------------------
    localparam INDEX_WIDTH = $clog2(MEM_SIZE);
    localparam [INDEX_WIDTH-1:0] LAST_INDEX = {INDEX_WIDTH{1'b1}};

    // -------------------------------
    // Memory
    // -------------------------------
    reg [31:0] mem_a [0:MEM_SIZE-1];
    reg [31:0] mem_b [0:MEM_SIZE-1];
    reg [31:0] mem_r [0:MEM_SIZE-1];

    // -------------------------------
    // Index
    // -------------------------------
    reg [INDEX_WIDTH-1:0] index;

    // -------------------------------
    // Compute lane wiring
    // -------------------------------
    wire [31:0] a0 = mem_a[index];
    wire [31:0] b0 = mem_b[index];
    wire [31:0] r0;

    assign result_out = mem_r[index];

    compute_lane lane0 (
        .a(a0),
        .b(b0),
        .opcode(opcode),
        .result(r0)
    );

    // -------------------------------
    // Initialization (simulation)
    // -------------------------------
    integer i;
    initial begin
        for (i = 0; i < MEM_SIZE; i = i + 1) begin
            mem_a[i] = i;
            mem_b[i] = i + 1;
            mem_r[i] = 0;
        end
    end

    // -------------------------------
    // Sequential logic
    // -------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            index <= 0;
            done  <= 0;
        end else begin
            if (start) begin
                mem_r[index] <= r0;

                if (index == LAST_INDEX) begin
                    done  <= 1;
                    index <= 0;
                end else begin
                    index <= index + 1;
                end
            end
        end
    end

endmodule
