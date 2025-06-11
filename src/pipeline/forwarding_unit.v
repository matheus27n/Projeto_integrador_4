module forwarding_unit (
    input  wire [4:0] id_ex_rs1, id_ex_rs2, ex_mem_rd, mem_wb_rd,
    input  wire       ex_mem_RegWrite, mem_wb_RegWrite,
    output reg  [1:0] forwardA,
    output reg  [1:0] forwardB
);
always @(*) begin
    // Forward do Estágio MEM para EX
    if (ex_mem_RegWrite && (ex_mem_rd != 5'b0) && (ex_mem_rd == id_ex_rs1))
        forwardA = 2'b10;
    else if (mem_wb_RegWrite && (mem_wb_rd != 5'b0) && (mem_wb_rd == id_ex_rs1))
        forwardA = 2'b01;
    else
        forwardA = 2'b00;

    // Forward do Estágio WB para EX
    if (ex_mem_RegWrite && (ex_mem_rd != 5'b0) && (ex_mem_rd == id_ex_rs2))
        forwardB = 2'b10;
    else if (mem_wb_RegWrite && (mem_wb_rd != 5'b0) && (mem_wb_rd == id_ex_rs2))
        forwardB = 2'b01;
    else
        forwardB = 2'b00;
end
endmodule