`timescale 1ns / 1ps

module pipeline_topo(
    input clk,
    input reset,

    // --- ADICIONADO PARA O TESTBENCH ---
    // Expondo os resultados do estágio WB para o testbench poder monitorá-los.
    output wire [31:0] wb_pc,
    output wire [31:0] wb_instruction,
    output wire [31:0] wb_write_data,
    output wire [4:0]  wb_rd_addr,
    output wire        wb_RegWrite
);
    // --- Fios de conexão internos ---
    wire [6:0] id_opcode;
    wire [2:0] id_funct3;
    wire [6:0] id_funct7;
    wire id_ALUSrc, id_MemtoReg, id_RegWrite_ctrl, id_MemRead, id_MemWrite, id_Branch, id_Jump;
    wire [3:0] id_ALUControl;

    // Instancia o "corpo" do processador
    parte_operativa_pipeline u_parte_operativa (
        .clk(clk), .reset(reset),
        // Conecta os comandos do controle para a parte operativa
        .id_ALUSrc(id_ALUSrc), .id_MemtoReg(id_MemtoReg), .id_RegWrite(id_RegWrite_ctrl),
        .id_MemRead(id_MemRead), .id_MemWrite(id_MemWrite), .id_Branch(id_Branch), 
        .id_Jump(id_Jump), .id_ALUControl(id_ALUControl),
        // Conecta os campos da instrução da parte operativa para o controle
        .id_opcode(id_opcode), .id_funct3(id_funct3), .id_funct7(id_funct7),

        // --- ADICIONADO PARA O TESTBENCH ---
        // Conecta as saídas de depuração da parte operativa para as saídas do topo.
        .wb_pc(wb_pc),
        .wb_instruction(wb_instruction),
        .wb_write_data(wb_write_data),
        .wb_rd_addr(wb_rd_addr),
        .wb_RegWrite(wb_RegWrite)
    );
    
    // Instancia o "cérebro" do processador
    // Nota: O sinal de escrita no registrador foi renomeado para id_RegWrite_ctrl para evitar conflito com a saída wb_RegWrite.
    unidade_controle_pipeline u_unidade_controle (
        .opcode(id_opcode), .funct3(id_funct3), .funct7(id_funct7),
        // Conecta as saídas do controle
        .ALUSrc(id_ALUSrc), .MemtoReg(id_MemtoReg), .RegWrite(id_RegWrite_ctrl),
        .MemRead(id_MemRead), .MemWrite(id_MemWrite), .Branch(id_Branch), 
        .Jump(id_Jump), .ALUControl(id_ALUControl)
    );
    
endmodule