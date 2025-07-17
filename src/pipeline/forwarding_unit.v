// Módulo: forwarding_unit.v (NOVO)
// Descrição: Detecta hazards de dados e gera sinais de controle para os MUXes de forwarding.
module forwarding_unit (
    // Endereços dos operandos da instrução no estágio EX
    input  logic [4:0] rs1_addr_ex,
    input  logic [4:0] rs2_addr_ex,

    // Endereço de destino da instrução no estágio MEM
    input  logic [4:0] rd_addr_mem,
    input  logic       reg_write_en_mem,

    // Endereço de destino da instrução no estágio WB
    input  logic [4:0] rd_addr_wb,
    input  logic       reg_write_en_wb,

    // Sinais de controle de saída para os MUXes no estágio EX
    output logic [1:0] forward_a, // 00: No-fwd, 01: Fwd from MEM, 10: Fwd from WB
    output logic [1:0] forward_b
);

    always_comb begin
        // --- Lógica para o operando A (rs1) ---
        // Prioridade 1: Hazard EX/MEM (o mais recente)
        if (reg_write_en_mem && (rd_addr_mem != 5'b0) && (rd_addr_mem == rs1_addr_ex)) begin
            forward_a = 2'b01; // Encaminha resultado da ULA (do estágio MEM)
        end
        // Prioridade 2: Hazard MEM/WB
        else if (reg_write_en_wb && (rd_addr_wb != 5'b0) && (rd_addr_wb == rs1_addr_ex)) begin
            forward_a = 2'b10; // Encaminha dado do estágio WB
        end
        // Sem hazard
        else begin
            forward_a = 2'b00;
        end

        // --- Lógica para o operando B (rs2) ---
        // Prioridade 1: Hazard EX/MEM
        if (reg_write_en_mem && (rd_addr_mem != 5'b0) && (rd_addr_mem == rs2_addr_ex)) begin
            forward_b = 2'b01; // Encaminha resultado da ULA (do estágio MEM)
        end
        // Prioridade 2: Hazard MEM/WB
        else if (reg_write_en_wb && (rd_addr_wb != 5'b0) && (rd_addr_wb == rs2_addr_ex)) begin
            forward_b = 2'b10; // Encaminha dado do estágio WB
        end
        // Sem hazard
        else begin
            forward_b = 2'b00;
        end
    end

endmodule