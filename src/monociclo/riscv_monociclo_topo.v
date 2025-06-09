// riscv_monociclo_topo.v
`timescale 1ns/1ps

module riscv_monociclo_topo (
    input         clk,
    input         reset,
    output [31:0] reg_a0_out // Saída para monitorar o registrador a0 (x10)
);

    // Fios para conectar a unidade de controle e a parte operativa
    wire [6:0] opcode;
    wire [2:0] funct3;
    wire [6:0] funct7;
    wire       PCWrite;
    wire       MemWrite;
    wire       ALUSrc;
    wire       RegWrite;
    wire [1:0] ResultSrc;
    wire [3:0] ALUControl;

    // Instanciação da Parte Operativa
    parte_operativa u_parte_operativa (
        .clk(clk),
        .reset(reset),
        .PCWrite(PCWrite),
        .MemWrite(MemWrite),
        .ALUSrc(ALUSrc),
        .RegWrite(RegWrite),
        .ResultSrc(ResultSrc),
        .ALUControl(ALUControl),
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .reg_a0_out(reg_a0_out)
    );

    // Instanciação da Unidade de Controle
    unidade_controle u_unidade_controle (
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .PCWrite(PCWrite),
        .MemWrite(MemWrite),
        .ALUSrc(ALUSrc),
        .RegWrite(RegWrite),
        .ResultSrc(ResultSrc),
        .ALUControl(ALUControl)
    );

endmodule