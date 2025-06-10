module data_memory (
    input  wire        clk,
    input  wire        MemRead,
    input  wire        MemWrite,
    input  wire [31:0] addr,
    input  wire [31:0] write_data,
    output reg  [31:0] read_data
);

reg [31:0] memory [0:255]; // 1KB

always @(posedge clk) begin
    if (MemWrite)
        memory[addr[9:2]] <= write_data;
end

always @(*) begin
    if (MemRead)
        read_data = memory[addr[9:2]];
    else
        read_data = 0;
end

endmodule
