// ================================================================
//                        Immediate Generator
// ================================================================
// Gera o valor imediato com base na instrução e seu formato
// Suporta formatos: I-type, S-type, B-type, U-type e J-type
// ================================================================

module imm_gen (
    input  wire [31:0] instruction, // Instrução completa (32 bits)
    input  wire [6:0]  opcode,      // Opcode extraído da instrução
    output reg  [31:0] imm          // Imediato estendido para 32 bits
);

always @(*) begin
    case (opcode)

        // ----------------- I-Type -----------------
        // Exemplos: addi, lw, jalr
        7'b0010011, 7'b0000011, 7'b1100111: begin
            imm = {{20{instruction[31]}}, instruction[31:20]};
        end

        // ----------------- S-Type -----------------
        // Exemplo: sw
        7'b0100011: begin
            imm = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
        end

        // ----------------- B-Type -----------------
        // Exemplos: beq, bne, etc.
        7'b1100011: begin
            imm = {{20{instruction[31]}}, instruction[7], instruction[30:25],
                   instruction[11:8], 1'b0}; // Último bit é zero (offset múltiplo de 2)
        end

        // ----------------- J-Type -----------------
        // Exemplo: jal
        7'b1101111: begin
            imm = {{12{instruction[31]}}, instruction[19:12], instruction[20],
                   instruction[30:21], 1'b0}; // Último bit é zero
        end

        // ----------------- U-Type -----------------
        // Exemplos: lui, auipc
        7'b0110111, 7'b0010111: begin
            imm = {instruction[31:12], 12'b0}; // Imediato ocupa os bits superiores
        end

        // ----------------- Default -----------------
        default: begin
            imm = 32'hXXXX_XXXX; // Valor indefinido para formatos desconhecidos
        end
    endcase
end

endmodule
