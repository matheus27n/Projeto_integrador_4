// unidade_controle.v
`timescale 1ns/1ps

module unidade_controle (
    // Entradas
    input  [6:0] opcode,
    input  [2:0] funct3, // Usado para diferenciar instruções com o mesmo opcode
    input  [6:0] funct7, // Usado para diferenciar ADD de SUB
    // Saídas (sinais de controle)
    output reg PCWrite,
    output reg MemWrite,
    output reg ALUSrc,
    output reg RegWrite,
    output reg [1:0] ResultSrc,
    output reg [3:0] ALUControl
);

    // Lógica principal de decodificação baseada no opcode
    always @(*) begin
        // Valores padrão (seguros) - não escreve em nada
        PCWrite    = 1'b1; // Por padrão, sempre avança o PC
        MemWrite   = 1'b0;
        ALUSrc     = 1'b0;
        RegWrite   = 1'b0;
        ResultSrc  = 2'b00;
        ALUControl = 4'b0000; // Operação padrão: ADD

        case (opcode)
            // Instruções Tipo-R (ex: ADD, SUB)
            7'b0110011: begin
                RegWrite   = 1'b1;
                ALUSrc     = 1'b0; // Usa segundo registrador
                ResultSrc  = 2'b00; // Resultado vem da ULA
                // Decodifica a operação da ULA com base no funct3 e funct7
                if (funct7 == 7'b0000000 && funct3 == 3'b000)
                    ALUControl = 4'b0000; // ADD
                else if (funct7 == 7'b0100000 && funct3 == 3'b000)
                    ALUControl = 4'b0001; // SUB
                else
                    ALUControl = 4'bxxxx; // Operação não suportada
            end

            // Instruções Tipo-I (ex: ADDI)
            7'b0010011: begin
                RegWrite   = 1'b1;
                ALUSrc     = 1'b1; // Usa o imediato
                ResultSrc  = 2'b00; // Resultado vem da ULA
                ALUControl = 4'b0000; // ADD
            end

            // Instruções LW (Load Word)
            7'b0000011: begin
                RegWrite   = 1'b1;
                ALUSrc     = 1'b1; // Imediato para calcular endereço
                ResultSrc  = 2'b01; // Resultado vem da memória
                MemWrite   = 1'b0;
                ALUControl = 4'b0000; // ULA calcula endereço (soma)
            end

            // Instruções SW (Store Word)
            7'b0100011: begin
                RegWrite   = 1'b0; // Não escreve no banco de registradores
                ALUSrc     = 1'b1; // Imediato para calcular endereço
                MemWrite   = 1'b1; // Habilita escrita na memória
                ALUControl = 4'b0000; // ULA calcula endereço (soma)
            end

            // TODO: Adicionar decodificação para BEQ, BNE, JAL, etc.

            default: begin
                // Instrução desconhecida - manter valores padrão
            end
        endcase
    end

endmodule