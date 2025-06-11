// ================================================================
//                imm_gen.v - VERSÃO CORRIGIDA
// ================================================================
module imm_gen (
    input  wire [31:0] instruction, // MUDANÇA: Agora recebe a instrução completa
    input  wire [6:0]  opcode,      // Opcode para decidir o formato
    output reg  [31:0] imm          // Saída do imediato de 32 bits
);

always @(*) begin
    case (opcode)
        // I-type (addi, lw, jalr)
        7'b0010011, 7'b0000011, 7'b1100111:
            imm = {{20{instruction[31]}}, instruction[31:20]};
            
        // S-type (sw)
        7'b0100011:
            imm = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
            
        // B-type (beq)
        7'b1100011:
            imm = {{20{instruction[31]}}, instruction[7], instruction[30:25], instruction[11:8], 1'b0};
            
        // J-type (jal)
        7'b1101111:
            imm = {{12{instruction[31]}}, instruction[19:12], instruction[20], instruction[30:21], 1'b0};
            
        // U-type (lui, auipc)
        7'b0110111, 7'b0010111:
            imm = {instruction[31:12], 12'b0};
            
        default:
            imm = 32'bx; // Formato desconhecido
    endcase
end

endmodule