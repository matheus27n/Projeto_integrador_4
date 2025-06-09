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

    // Bloco principal que gera todos os sinais de controle
    always @(*) begin
        // Valores padrão (seguros) para cada ciclo
        ALUSrc   = 1'b0; MemtoReg = 1'b0; RegWrite = 1'b0; MemRead = 1'b0;
        MemWrite = 1'b0; Branch   = 1'b0; Jump     = 1'b0; ALUControl = 4'bxxxx;

 case(opcode)
            // R-type (ADD, SUB, AND, OR, etc.)
            7'b0110011: begin
                RegWrite = 1'b1; // Escreve o resultado no registrador
                ALUSrc   = 1'b0; // A segunda fonte da ULA é um registrador (RD2)
                
                // CORREÇÃO: Bloco completo para todas as instruções Tipo-R do RV32I
                case(funct3)
                    3'b000: // ADD ou SUB
                        ALUControl = (funct7[5]) ? 4'b0110 : 4'b0010; // funct7[5]=1 -> SUB, senão ADD
                    3'b001: // SLL (Shift Left Logical)
                        ALUControl = 4'b0011; // Usando o código que definimos na ULA
                    3'b010: // SLT (Set on Less Than, Signed)
                        ALUControl = 4'b0111;
                    3'b011: // SLTU (Set on Less Than, Unsigned)
                        ALUControl = 4'b1000;
                    3'b100: // XOR
                        ALUControl = 4'b0100;
                    3'b101: // SRL ou SRA (Shift Right Logical/Arithmetic)
                        ALUControl = (funct7[5]) ? 4'bxxxx : 4'b0101; // SRA ainda não implementado na ULA
                    3'b110: // OR
                        ALUControl = 4'b0001;
                    3'b111: // AND
                        ALUControl = 4'b0000;
                    default: 
                        ALUControl = 4'bxxxx;
                endcase
            end

            // I-type (ADDI)
            7'b0010011: begin
                RegWrite   = 1'b1; // Escreve o resultado no registrador
                ALUSrc     = 1'b1; // A segunda fonte da ULA é o imediato
                ALUControl = 4'b0010; // A ULA sempre faz ADIÇÃO
            end

            // LW (Load Word)
            7'b0000011: begin
                RegWrite   = 1'b1;   // Escreve o dado da memória no registrador
                ALUSrc     = 1'b1;   // Usa o imediato para calcular o endereço
                MemRead    = 1'b1;   // Habilita a leitura da memória de dados
                MemtoReg   = 1'b1;   // O dado para o registrador vem da memória
                ALUControl = 4'b0010; // A ULA calcula o endereço (soma)
            end

            // SW (Store Word)
            7'b0100011: begin
                ALUSrc     = 1'b1;   // Usa o imediato para calcular o endereço
                MemWrite   = 1'b1;   // Habilita a escrita na memória de dados
                ALUControl = 4'b0010; // A ULA calcula o endereço (soma)
            end

            // Branch (BEQ, BNE, BLT, etc.)
            7'b1100011: begin
                Branch   = 1'b1;   // Habilita a lógica de desvio
                ALUSrc   = 1'b0;   // A ULA compara dois registradores
                case(funct3)
                    3'b000: ALUControl = 4'b0110; // BEQ (usa SUB para comparar)
                    3'b001: ALUControl = 4'b0110; // BNE (usa SUB para comparar)
                    3'b100: ALUControl = 4'b0111; // BLT (usa SLT)
                    3'b101: ALUControl = 4'b0111; // BGE (usa SLT)
                    3'b110: ALUControl = 4'b1000; // BLTU (usa SLTU)
                    3'b111: ALUControl = 4'b1000; // BGEU (usa SLTU)
                    default: ALUControl = 4'bxxxx;
                endcase
            end

            // JAL (Jump and Link)
            7'b1101111: begin
                RegWrite = 1'b1; // Escreve PC+4 no registrador
                Jump     = 1'b1; // Habilita o salto incondicional
            end
            
            default: begin
                // Mantém os valores padrão seguros para instruções não suportadas
            end
        endcase
    end

endmodule