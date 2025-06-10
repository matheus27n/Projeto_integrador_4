module register_file (
    input  wire        clk,
    input  wire        RegWrite,
    input  wire [4:0]  rs1,
    input  wire [4:0]  rs2,
    input  wire [4:0]  rd,
    input  wire [31:0] write_data,
    output wire [31:0] read_data1,
    output wire [31:0] read_data2
);

reg [31:0] registers [31:0];

assign read_data1 = (rs1 != 0) ? registers[rs1] : 0;
assign read_data2 = (rs2 != 0) ? registers[rs2] : 0;

always @(posedge clk) begin
    if (RegWrite && (rd != 0))
        registers[rd] <= write_data;
end

endmodule
