`timescale 1ns / 1ps

// Unidade de Controle para o Processador Pipeline
// Função: Decodifica a instrução no estágio ID e gera todos os sinais de controle.
// A lógica é a mesma do processador monociclo.
module unidade_controle_pipeline(
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
        // Valores padrão (seguros) para cada ciclo.
        // Se uma instrução não for reconhecida, ela não fará nada prejudicial.
        ALUSrc   = 1'b0; MemtoReg = 1'b0; RegWrite = 1'b0; MemRead = 1'b0;
        MemWrite = 1'b0; Branch   = 1'b0; Jump     = 1'b0; ALUControl = 4'bxxxx;

        case(opcode)
            // R-type (ADD, SUB, AND, OR, SLT, etc.)
            7'b0110011: begin
                RegWrite = 1'b1; // Escreve o resultado no registrador
                ALUSrc   = 1'b0; // A segunda fonte da ULA é um registrador (RD2)
                
                // Decodifica a operação exata da ULA baseada nos campos de função
                case(funct3)
                    3'b000: ALUControl = (funct7[5]) ? 4'b0110 : 4'b0010; // SUB ou ADD
                    3'b001: ALUControl = 4'b0011; // SLL
                    3'b010: ALUControl = 4'b0111; // SLT
                    3'b011: ALUControl = 4'b1000; // SLTU
                    3'b100: ALUControl = 4'b0100; // XOR
                    3'b101: ALUControl = 4'b0101; // SRL (SRA não implementado na ULA)
                    3'b110: ALUControl = 4'b0001; // OR
                    3'b111: ALUControl = 4'b0000; // AND
                    default: ALUControl = 4'bxxxx;
                endcase
            end

            // I-type (ADDI, etc.)
            7'b0010011: begin
                RegWrite   = 1'b1; // Escreve o resultado no registrador
                ALUSrc     = 1'b1; // A segunda fonte da ULA é o imediato
                // A ULA deve fazer a operação correta baseada no funct3
                case(funct3)
                    3'b000: ALUControl = 4'b0010; // ADDI (Soma)
                    // Adicionar outros I-types aqui seria fácil (SLTI, XORI, etc.)
                    default: ALUControl = 4'bxxxx;
                endcase
            end

            // LW (Load Word)
            7'b0000011: begin
                RegWrite   = 1'b1;   // Escreve o dado da memória no registrador
                ALUSrc     = 1'b1;   // Usa o imediato para calcular o endereço
                MemRead    = 1'b1;   // Habilita a leitura da memória de dados
                MemtoReg   = 1'b1;   // O dado para o registrador vem da memória
                ALUControl = 4'b0010; // A ULA sempre SOMA para calcular o endereço
            end

            // SW (Store Word)
            7'b0100011: begin
                ALUSrc     = 1'b1;   // Usa o imediato para calcular o endereço
                MemWrite   = 1'b1;   // Habilita a escrita na memória de dados
                ALUControl = 4'b0010; // A ULA sempre SOMA para calcular o endereço
            end

            // Branch (BEQ, BNE, BLT, etc.)
            7'b1100011: begin
                Branch   = 1'b1;   // Habilita a lógica de desvio na parte operativa
                ALUSrc   = 1'b0;   // A ULA compara dois registradores
                // A ULA deve ser configurada para a comparação correta
                case(funct3)
                    3'b000: ALUControl = 4'b0110; // BEQ (usa SUB)
                    3'b001: ALUControl = 4'b0110; // BNE (usa SUB)
                    3'b100: ALUControl = 4'b0111; // BLT (usa SLT)
                    3'b101: ALUControl = 4'b0111; // BGE (reutiliza SLT)
                    3'b110: ALUControl = 4'b1000; // BLTU (usa SLTU)
                    3'b111: ALUControl = 4'b1000; // BGEU (reutiliza SLTU)
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