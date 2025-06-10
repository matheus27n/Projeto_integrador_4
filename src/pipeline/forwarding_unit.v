`timescale 1ns / 1ps

module forwarding_unit (
    // Endereços dos registradores fonte no estágio EX
    input [4:0] ex_rs1_addr,
    input [4:0] ex_rs2_addr,
    // Endereço do registrador de destino no estágio MEM
    input [4:0] mem_rd_addr,
    input       mem_RegWrite,
    // Endereço do registrador de destino no estágio WB
    input [4:0] wb_rd_addr,
    input       wb_RegWrite,
    
    // Saídas de controle para os MUXes de forwarding
    output reg [1:0] ForwardA,
    output reg [1:0] ForwardB
);

    always @(*) begin
        // --- Lógica para ForwardA (controla a entrada SrcA da ULA) ---
        // Hazard EX/MEM: Se a instrução no MEM vai escrever e seu destino é a fonte da instrução no EX
        if (mem_RegWrite && (mem_rd_addr != 0) && (mem_rd_addr == ex_rs1_addr)) begin
            ForwardA = 2'b10; // Adiantar do estágio MEM
        // Hazard MEM/WB: Se a instrução no WB vai escrever e seu destino é a fonte da instrução no EX
        end else if (wb_RegWrite && (wb_rd_addr != 0) && (wb_rd_addr == ex_rs1_addr)) begin
            ForwardA = 2'b01; // Adiantar do estágio WB
        end else begin
            ForwardA = 2'b00; // Sem hazard, usar o valor do banco de registradores
        end

        // --- Lógica para ForwardB (controla a entrada SrcB da ULA) ---
        // Mesma lógica, mas para o segundo operando (rs2)
        if (mem_RegWrite && (mem_rd_addr != 0) && (mem_rd_addr == ex_rs2_addr)) begin
            ForwardB = 2'b10; // Adiantar do estágio MEM
        end else if (wb_RegWrite && (wb_rd_addr != 0) && (wb_rd_addr == ex_rs2_addr)) begin
            ForwardB = 2'b01; // Adiantar do estágio WB
        end else begin
            ForwardB = 2'b00; // Sem hazard
        end
    end

endmodule