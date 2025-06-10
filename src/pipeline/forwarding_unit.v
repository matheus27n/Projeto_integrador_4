module forwarding_unit (
    input  wire [4:0] id_ex_rs1,
    input  wire [4:0] id_ex_rs2,
    input  wire [4:0] ex_mem_rd,
    input  wire [4:0] mem_wb_rd,
    input  wire       ex_mem_RegWrite,
    input  wire       mem_wb_RegWrite,
    output reg  [1:0] forwardA,
    output reg  [1:0] forwardB
);

always @(*) begin
    forwardA = 2'b00;
    forwardB = 2'b00;

    // EX hazard (EX -> EX)
    if (ex_mem_RegWrite && (ex_mem_rd != 0) && (ex_mem_rd == id_ex_rs1))
        forwardA = 2'b10;

    if (ex_mem_RegWrite && (ex_mem_rd != 0) && (ex_mem_rd == id_ex_rs2))
        forwardB = 2'b10;

    // MEM hazard (MEM -> EX)
    if (mem_wb_RegWrite && (mem_wb_rd != 0) && (mem_wb_rd == id_ex_rs1) &&
       !(ex_mem_RegWrite && (ex_mem_rd != 0) && (ex_mem_rd == id_ex_rs1)))
        forwardA = 2'b01;

    if (mem_wb_RegWrite && (mem_wb_rd != 0) && (mem_wb_rd == id_ex_rs2) &&
       !(ex_mem_RegWrite && (ex_mem_rd != 0) && (ex_mem_rd == id_ex_rs2)))
        forwardB = 2'b01;
end

endmodule