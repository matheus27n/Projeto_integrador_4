// ========================================================
// Módulo: alu_control
// Descrição: Gera sinais de controle da ALU com base no
// ALUOp e campos funct3/funct7 da instrução.
// ========================================================
module alu_control (
    input  wire [1:0] ALUOp,       // Código do tipo de operação (vindo da unidade de controle)
    input  wire [2:0] funct3,      // Campo funct3 da instrução
    input  wire [6:0] funct7,      // Campo funct7 da instrução (bit 5 relevante para SUB/SRA)
    output reg  [3:0] alu_control  // Código de operação para a ALU
);

// A lógica abaixo determina qual operação a ALU deve realizar
always @(*) begin
    case (ALUOp)

        // Caso padrão para LW/SW/AUIPC: soma de endereços
        2'b00: alu_control = 4'b0010; // ADD_OP

        // Branches (BEQ, BNE, BLT, BGE, etc.)
        2'b01: begin
            case(funct3)
                3'b000, 3'b001: alu_control = 4'b0110; // BEQ, BNE → SUB
                3'b100, 3'b101: alu_control = 4'b0111; // BLT, BGE → SLT
                3'b110, 3'b111: alu_control = 4'b1010; // BLTU, BGEU → SLTU
                default:        alu_control = 4'bxxxx; // Instrução inválida
            endcase
        end

        // Operações do tipo R-Type e I-Type aritméticas
        2'b10: begin
            case (funct3)
                3'b000: alu_control = (funct7[5]) ? 4'b0110 : 4'b0010; // SUB ou ADD/ADDI
                3'b001: alu_control = 4'b1001; // SLL
                3'b010: alu_control = 4'b0111; // SLT
                3'b011: alu_control = 4'b1010; // SLTU
                3'b100: alu_control = 4'b1000; // XOR
                3'b101: alu_control = (funct7[5]) ? 4'b1100 : 4'b1011; // SRA ou SRL
                3'b110: alu_control = 4'b0001; // OR
                3'b111: alu_control = 4'b0000; // AND
                default: alu_control = 4'bxxxx; // Instrução inválida
            endcase
        end

        // Valor padrão para caso ALUOp seja indefinido
        default: alu_control = 4'bxxxx;

    endcase
end

endmodule
