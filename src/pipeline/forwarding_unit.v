// ========================================================
// Módulo: forwarding_unit
// Descrição: Unidade de forwarding para resolver hazards de dados
//            entre os estágios EX, MEM e WB do pipeline.
// ========================================================
module forwarding_unit (
    input  wire [4:0] id_ex_rs1,      // Registrador fonte 1 no estágio EX
    input  wire [4:0] id_ex_rs2,      // Registrador fonte 2 no estágio EX
    input  wire [4:0] ex_mem_rd,      // Registrador destino no estágio MEM
    input  wire [4:0] mem_wb_rd,      // Registrador destino no estágio WB
    input  wire       ex_mem_RegWrite,// Sinal de escrita no registrador no estágio MEM
    input  wire       mem_wb_RegWrite,// Sinal de escrita no registrador no estágio WB
    output reg  [1:0] forwardA,       // Controle de forwarding para operandA
    output reg  [1:0] forwardB        // Controle de forwarding para operandB
);

    // ----------------------------------------------------
    // Lógica de Forwarding para o operando A (rs1)
    // ----------------------------------------------------
    always @(*) begin
        if (ex_mem_RegWrite && (ex_mem_rd != 5'b0) && (ex_mem_rd == id_ex_rs1))
            forwardA = 2'b10; // Forward do estágio MEM
        else if (mem_wb_RegWrite && (mem_wb_rd != 5'b0) && (mem_wb_rd == id_ex_rs1))
            forwardA = 2'b01; // Forward do estágio WB
        else
            forwardA = 2'b00; // Sem forwarding
    end

    // ----------------------------------------------------
    // Lógica de Forwarding para o operando B (rs2)
    // ----------------------------------------------------
    always @(*) begin
        //Se o estágio MEM (ex_mem) vai escrever em um registrador (RegWrite está ativo),
        //e esse registrador de destino (rd) é diferente de x0 (registrador zero, que nunca muda),
        //e o registrador de destino é igual ao registrador fonte rs2 que está sendo usado agora no estágio EX,
        //⇒ então existe dependência de dados e precisamos fazer forwarding do valor da MEM para a ULA.
        if (ex_mem_RegWrite && (ex_mem_rd != 5'b0) && (ex_mem_rd == id_ex_rs2))
            forwardB = 2'b10; // Forward do estágio MEM
        else if (mem_wb_RegWrite && (mem_wb_rd != 5'b0) && (mem_wb_rd == id_ex_rs2))
            forwardB = 2'b01; // Forward do estágio WB
        else
            forwardB = 2'b00; // Sem forwarding
    end

endmodule
