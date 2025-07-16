// Módulo: control_unit.v (ATUALIZADO PARA ESTÁGIO MEM)
// Descrição: Gera sinais de controle com base no opcode da instrução.

module control_unit (
    input  logic [6:0] opcode,
    
    // Saídas de controle para todo o processador
    output logic       reg_write_en, // Habilita escrita no banco de registradores
    output logic       ALUSrc,       // MUX da segunda entrada da ULA (0: rs2, 1: imm)
    output logic       MemtoReg,     // MUX do dado de escrita (0: ALU, 1: Mem)
    output logic       MemRead,      // Habilita leitura da memória de dados
    output logic       MemWrite,     // Habilita escrita na memória de dados
    output logic [3:0] alu_op        // Código de operação para a ULA
);
    import alu_pkg::*; // Importa os parâmetros da ULA (ALU_ADD, etc)

    always_comb begin
        // --- Valores padrão (seguros) ---
        // Por padrão, nenhuma operação de escrita ou acesso à memória ocorre.
        reg_write_en = 1'b0;
        ALUSrc       = 1'b0;
        MemtoReg     = 1'b0;
        MemRead      = 1'b0;
        MemWrite     = 1'b0;
        alu_op       = ALU_ADD; // Operação padrão e segura
        
        // --- Decodificação baseada no Opcode ---
        case (opcode)
            // Tipo-R (ex: add, sub)
            7'b0110011: begin
                reg_write_en = 1'b1;
                ALUSrc       = 1'b0; // ALU usa [rs1] e [rs2]
            end
            
            // Tipo-I (ex: addi)
            7'b0010011: begin
                reg_write_en = 1'b1;
                ALUSrc       = 1'b1; // ALU usa [rs1] e [imediato]
            end

            // Tipo-I (lw - Load Word)
            7'b0000011: begin
                reg_write_en = 1'b1;
                ALUSrc       = 1'b1; // ALU usa [rs1] e [imediato] para calcular endereço
                MemtoReg     = 1'b1; // O dado escrito no registrador vem da MEMÓRIA
                MemRead      = 1'b1; // Habilita LEITURA da memória
            end

            // Tipo-S (sw - Store Word)
            7'b0100011: begin
                ALUSrc       = 1'b1; // ALU usa [rs1] e [imediato] para calcular endereço
                MemWrite     = 1'b1; // Habilita ESCRITA na memória
                // reg_write_en e MemRead continuam 0
            end
            
            default: begin
                // Mantém os valores padrão seguros para instruções não implementadas
            end
        endcase
    end
endmodule