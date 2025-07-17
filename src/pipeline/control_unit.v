// Módulo: control_unit.v (VERSÃO ATUALIZADA)
// Descrição: Gera sinais de controle com base no opcode, funct3 e funct7.
// Adicionamos controle para Branch e Jump.

module control_unit (
    input  logic [6:0] opcode,
    input  logic [2:0] funct3, // Nova entrada
    input  logic [6:0] funct7, // Nova entrada
    
    // Saídas de controle para todo o processador
    output logic       reg_write_en,
    output logic       ALUSrc,
    output logic       MemtoReg,
    output logic       MemRead,
    output logic       MemWrite,
    output logic       Branch,       // Novo: Para BEQ/BNE
    output logic       Jump,         // Novo: Para JAL
    output logic [3:0] alu_op
);
    import alu_pkg::*;

    // Sinais internos para a ULA
    logic [3:0] alu_op_r_type;

    // Sub-decodificador para instruções Tipo-R
    always_comb begin
        case (funct3)
            3'b000: begin // ADD ou SUB
                if (funct7 == 7'b0100000) begin
                    alu_op_r_type = ALU_SUB;
                end else begin
                    alu_op_r_type = ALU_ADD;
                end
            end
            3'b010: alu_op_r_type = ALU_SLT;
            // Adicione outros Tipo-R aqui (sltu, xor, etc.) se precisar
            default: alu_op_r_type = ALU_ADD; // Padrão seguro
        endcase
    end

    // Decodificador Principal
    always_comb begin
        // --- Valores padrão (seguros) ---
        reg_write_en = 1'b0;
        ALUSrc       = 1'b0;
        MemtoReg     = 1'b0;
        MemRead      = 1'b0;
        MemWrite     = 1'b0;
        Branch       = 1'b0;
        Jump         = 1'b0;
        alu_op       = ALU_ADD; // Operação padrão

        case (opcode)
            // Tipo-R (add, sub, slt)
            7'b0110011: begin
                reg_write_en = 1'b1;
                ALUSrc       = 1'b0;
                alu_op       = alu_op_r_type; // Usa o resultado do sub-decodificador
            end
            
            // Tipo-I (addi, slli, slti)
            7'b0010011: begin
                reg_write_en = 1'b1;
                ALUSrc       = 1'b1;
                case (funct3)
                    3'b000: alu_op = ALU_ADD;  // addi
                    3'b001: alu_op = ALU_SLLI; // slli
                    3'b010: alu_op = ALU_SLT;  // slti (usa mesma op da ULA que slt)
                    default: alu_op = ALU_ADD; // Padrão seguro
                endcase
            end

            // Tipo-I (lw - Load Word)
            7'b0000011: begin
                reg_write_en = 1'b1;
                ALUSrc       = 1'b1;
                MemtoReg     = 1'b1;
                MemRead      = 1'b1;
                alu_op       = ALU_ADD; // ULA calcula endereço (rs1 + imm)
            end

            // Tipo-S (sw - Store Word)
            7'b0100011: begin
                ALUSrc       = 1'b1;
                MemWrite     = 1'b1;
                alu_op       = ALU_ADD; // ULA calcula endereço (rs1 + imm)
            end

            // Tipo-B (beq, bne) - seu código usa beq e bne
            7'b1100011: begin
                Branch       = 1'b1;
                ALUSrc       = 1'b0; // Compara rs1 e rs2
                alu_op       = ALU_SUB; // ULA subtrai para verificar se o resultado é zero
            end

            // Tipo-J (jal)
            7'b1101111: begin
                reg_write_en = 1'b1; // Salva PC+4 em rd
                Jump         = 1'b1;
            end
            
            default: begin
                // Mantém os valores padrão seguros
            end
        endcase
    end
endmodule