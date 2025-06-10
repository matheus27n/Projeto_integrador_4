`timescale 1ns / 1ps

//******************************************************************
// Unidade de Detecção de Hazard (Load-Use)
// Fica no estágio ID e, se necessário, comanda um Stall.
//******************************************************************
module hazard_detection_unit (
    // Endereços fonte da instrução em ID
    input [4:0] id_rs1_addr,
    input [4:0] id_rs2_addr,
    // Registrador de destino e sinal MemRead da instrução em EX
    input [4:0] ex_rd_addr,
    input       ex_MemRead,
    
    // Saídas para controlar o pipeline
    output reg PCWrite,       // Controla se o PC pode ser atualizado
    output reg IF_ID_Write,   // Controla se o registrador IF/ID pode ser atualizado
    output reg ID_EX_Bubble   // Controla a injeção de NOP no estágio ID/EX
);

    always @(*) begin
        // Condição do Load-Use Hazard:
        // Se a instrução no estágio EX está lendo da memória (LW) E
        // seu registrador de destino é um dos fontes da instrução no estágio ID...
        if (ex_MemRead && (ex_rd_addr != 5'b0) &&
           ((ex_rd_addr == id_rs1_addr) || (ex_rd_addr == id_rs2_addr))) 
        begin
            // STALL!
            PCWrite = 1'b0;      // Congela o PC
            IF_ID_Write = 1'b0;  // Congela o registrador IF/ID
            ID_EX_Bubble = 1'b1; // Injeta uma bolha (NOP) no próximo estágio
        end else begin
            // Sem hazard, tudo funciona normalmente.
            PCWrite = 1'b1;
            IF_ID_Write = 1'b1;
            ID_EX_Bubble = 1'b0;
        end
    end

endmodule


//******************************************************************
// Unidade de Forwarding (Adiantamento)
// Fica no estágio EX e decide se os dados devem ser adiantados.
//******************************************************************
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
        // Prioridade maior para o hazard mais próximo (MEM)
        if (mem_RegWrite && (mem_rd_addr != 0) && (mem_rd_addr == ex_rs1_addr))
            ForwardA = 2'b10; // Adiantar do estágio MEM
        else if (wb_RegWrite && (wb_rd_addr != 0) && (wb_rd_addr == ex_rs1_addr))
            ForwardA = 2'b01; // Adiantar do estágio WB
        else
            ForwardA = 2'b00; // Sem adiantamento

        // --- Lógica para ForwardB (controla a entrada SrcB da ULA) ---
        if (mem_RegWrite && (mem_rd_addr != 0) && (mem_rd_addr == ex_rs2_addr))
            ForwardB = 2'b10; // Adiantar do estágio MEM
        else if (wb_RegWrite && (wb_rd_addr != 0) && (wb_rd_addr == ex_rs2_addr))
            ForwardB = 2'b01; // Adiantar do estágio WB
        else
            ForwardB = 2'b00; // Sem adiantamento
    end

endmodule