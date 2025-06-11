// hazard_unit.v - Unidade de detecção de hazard (load-use)

module hazard_unit (
    input  wire        id_ex_MemRead,   // Sinal indicando se a instrução em EX é um LW
    input  wire [4:0]  id_ex_rd,        // Registrador de destino da instrução em EX
    input  wire [4:0]  if_id_rs1,       // Registrador fonte 1 da instrução em ID
    input  wire [4:0]  if_id_rs2,       // Registrador fonte 2 da instrução em ID
    output reg         stall            // Sinal de controle de stall (pausa)
);

always @(*) begin
    // Detecta hazard de "load-use":
    // Se a instrução em EX é um LW, e seu rd será usado logo em seguida por uma instrução em ID
    if (id_ex_MemRead && (
            (id_ex_rd != 0) && 
            ((id_ex_rd == if_id_rs1) || (id_ex_rd == if_id_rs2))
        )) begin
        stall = 1'b1; // Gerar bolha (inserir NOP)
    end else begin
        stall = 1'b0;
    end
end

endmodule
