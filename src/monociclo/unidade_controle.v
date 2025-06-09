`timescale 1ns / 1ps

module unidade_controle(
    input wire [6:0] opcode,
    input wire [2:0] funct3,
    input wire [6:0] funct7,
    // Saídas de Controle
    output reg ALUSrc,
    output reg MemtoReg,
    output reg RegWrite,
    output reg MemRead,
    output reg MemWrite,
    output reg Branch,
    output reg Jump,
    output reg [3:0] ALUControl
);
    // MELHORIA: ALUOp agora é um sinal interno, não uma porta de saída.
    // Isso encapsula melhor a lógica de controle da ULA.
    reg [1:0] ALUOp;

    // === 1. Decodificador Principal (baseado no opcode) ===
    // Gera os principais sinais de controle.
    always @(*) begin
        // Valores padrão (seguros)
        ALUSrc   = 1'b0; MemtoReg = 1'b0; RegWrite = 1'b0; MemRead = 1'b0;
        MemWrite = 1'b0; Branch   = 1'b0; Jump     = 1'b0; ALUOp    = 2'bxx;

        case(opcode)
            // R-type (ADD, SUB, AND, OR, etc.)
            7'b0110011: begin
                RegWrite = 1'b1;
                ALUOp    = 2'b10; // '10' significa que é uma operação do tipo R
            end
            // I-type (ADDI, etc.)
            7'b0010011: begin
                ALUSrc   = 1'b1;
                RegWrite = 1'b1;
                ALUOp    = 2'b10; // Reutiliza a lógica do tipo R para a ULA
            end
            // LW
            7'b0000011: begin
                ALUSrc   = 1'b1;
                MemtoReg = 1'b1;
                RegWrite = 1'b1;
                MemRead  = 1'b1;
                ALUOp    = 2'b00; // '00' significa que a ULA deve somar para o endereço
            end
            // SW
            7'b0100011: begin
                ALUSrc   = 1'b1;
                MemWrite = 1'b1;
                ALUOp    = 2'b00; // '00' significa que a ULA deve somar para o endereço
            end
            // BEQ
            7'b1100011: begin
                Branch = 1'b1;
                ALUOp  = 2'b01; // '01' significa que a ULA deve subtrair para comparar
            end
            // JAL
            7'b1101111: begin
                RegWrite = 1'b1;
                Jump     = 1'b1;
                // ALUOp não importa, pois o resultado da ULA não é usado
            end
            default: begin
                // Mantém os valores padrão para instruções não suportadas
            end
        endcase
    end
    
    // === 2. Decodificador Secundário (Lógica da ULA) ===
    // Gera o sinal ALUControl final com base no ALUOp e nos campos de função.
    always @(*) begin
        case(ALUOp)
            // Para LW e SW, a ULA sempre faz uma SOMA
            2'b00: ALUControl = 4'b0010; // ADD
            // Para BEQ, a ULA sempre faz uma SUBTRAÇÃO para comparar
            2'b01: ALUControl = 4'b0110; // SUB
            // Para tipo R e I, decodifica com base em funct3 e funct7
            2'b10: begin
                case(funct3)
                    3'b000: ALUControl = (opcode == 7'b0110011 && funct7[5]) ? 4'b0110 : 4'b0010; // SUB ou ADD/ADDI
                    3'b111: ALUControl = 4'b0000; // AND
                    3'b110: ALUControl = 4'b0001; // OR
                    3'b001: ALUControl = 4'b0011; // SLL
                    3'b101: ALUControl = 4'b0101; // SRL
                    3'b100: ALUControl = 4'b0100; // XOR
                    3'b010: ALUControl = 4'b0111; // SLT
                    default: ALUControl = 4'bxxxx; // Não suportado
                endcase
            end
            default: ALUControl = 4'bxxxx; // Não suportado
        endcase
    end
endmodule