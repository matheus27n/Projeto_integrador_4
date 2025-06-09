`timescale 1ns / 1ps

module riscv_monociclo_topo(
    input wire clk,
    input wire reset
    // Para depuração, você poderia adicionar uma saída aqui, ex: output wire [31:0] reg_a0_out
);
    // === Conexões entre os módulos ===
    wire [6:0] opcode;
    wire [2:0] funct3;
    wire [6:0] funct7;
    // --- Sinais de Controle ---
    wire ALUSrc, MemtoReg, RegWrite, MemRead, MemWrite, Branch, Jump;
    wire [3:0] ALUControl;
    
    // Instanciação da unidade de controle
    unidade_controle u_unidade_controle(
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        // CORREÇÃO: ALUOp foi removido pois agora é um sinal interno do controle
        .ALUSrc(ALUSrc),
        .MemtoReg(MemtoReg),
        .RegWrite(RegWrite),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .Branch(Branch),
        .Jump(Jump),
        .ALUControl(ALUControl)
    );
    
    // Instanciação da parte operativa
    parte_operativa u_parte_operativa(
        .clk(clk),
        .reset(reset),
        .ALUControl(ALUControl),
        .ALUSrc(ALUSrc),
        .MemtoReg(MemtoReg),
        .RegWrite(RegWrite),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .Branch(Branch),
        .Jump(Jump),
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7)
    );
endmodule