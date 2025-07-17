// ========================================================
// Módulo: control_unit
// Descrição: Unidade de controle principal do processador RISC-V.
//           Gera sinais de controle com base no opcode da instrução.
// ========================================================
module control_unit (
    input  wire [6:0]  opcode,      // Opcode da instrução (bits [6:0])
    output reg         RegWrite,    // Habilita escrita no banco de registradores
    output reg [1:0]   ResultSrc,   // Seleção da fonte de dados para o write-back
    output reg         MemRead,     // Habilita leitura da memória de dados
    output reg         MemWrite,    // Habilita escrita na memória de dados
    output reg [1:0]   ALUOp,       // Define operação da ALU (decodificada por alu_control)
    output reg         ALUSrc,      // Se 1, segundo operando da ALU vem do imediato
    output reg         ALUASrc,     // Se 1, primeiro operando da ALU vem do PC (usado por AUIPC)
    output reg         Branch,      // Sinaliza instrução de desvio condicional
    output reg [1:0]   Jump         // 01 = JAL, 10 = JALR
);

always @(*) begin
    // ======================= Valores padrão =======================
    RegWrite  = 1'b0;
    ResultSrc = 2'b00; // 00 = resultado da ALU
    MemRead   = 1'b0;
    MemWrite  = 1'b0;
    ALUOp     = 2'b00;
    ALUSrc    = 1'b0;
    ALUASrc   = 1'b0;
    Branch    = 1'b0;
    Jump      = 2'b00;

    // ======================= Decodificação ========================
    case (opcode)
        7'b0110011: begin // R-Type (ex: add, sub, and, or)
            RegWrite  = 1;
            ResultSrc = 2'b00; // <<--- CORREÇÃO AQUI
            ALUOp     = 2'b10;
        end

        7'b0010011: begin // I-Type aritmético/lógico (ex: addi, xori)
            RegWrite  = 1;
            ResultSrc = 2'b00; // <<--- CORREÇÃO AQUI
            ALUSrc    = 1;
            ALUOp     = 2'b10;
        end

        7'b0000011: begin // Load (ex: lw)
            RegWrite  = 1;
            ResultSrc = 2'b01; // write-back vem da memória
            MemRead   = 1;
            ALUSrc    = 1;
        end

        7'b0100011: begin // Store (ex: sw)
            MemWrite = 1;
            ALUSrc   = 1;
        end

        7'b1100011: begin // Branch (ex: beq, bne)
            Branch = 1;
            ALUOp  = 2'b01;
        end

        7'b1101111: begin // JAL
            RegWrite  = 1;
            ResultSrc = 2'b11; // write-back vem do PC+4
            Jump      = 2'b01;
        end

        7'b1100111: begin // JALR
            RegWrite  = 1;
            ResultSrc = 2'b11;
            ALUSrc    = 1;
            Jump      = 2'b10;
        end

        7'b0110111: begin // LUI
            RegWrite  = 1;
            ResultSrc = 2'b10; // write-back recebe o imediato
            ALUSrc    = 1;
        end

        7'b0010111: begin // AUIPC
            RegWrite  = 1;
            ALUSrc    = 1;
            ALUASrc   = 1;
            ALUOp     = 2'b00; // Apenas soma
        end
    endcase
end

endmodule