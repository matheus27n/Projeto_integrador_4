// Módulo: hazard_detection_unit.v (NOVO)
// Descrição: Detecta hazards do tipo Load-Use.
// Opera no estágio ID, mas usa informações dos estágios ID e EX.

module hazard_detection_unit (
    // Entrada: Sinal de controle da instrução no estágio EX
    input  logic       MemRead_ex,

    // Entrada: Endereços de registradores
    input  logic [4:0] rd_addr_ex,    // Destino da instrução em EX
    input  logic [4:0] rs1_addr_id,   // Origem 1 da instrução em ID
    input  logic [4:0] rs2_addr_id,   // Origem 2 da instrução em ID

    // Saídas de Controle de Hazard
    output logic       stall_pipeline, // 1: Congela PC e IF/ID. 0: Operação normal.
    output logic       flush_id_ex     // 1: Insere bolha em ID/EX. 0: Operação normal.
);

    always_comb begin
        // A condição para o stall é:
        // 1. Uma instrução de leitura da memória (lw) está no estágio EX.
        // 2. O registrador de destino dessa 'lw' é um dos registradores de origem
        //    da instrução que está atualmente no estágio ID.
        if (MemRead_ex && (rd_addr_ex != 5'b0) &&
           ((rd_addr_ex == rs1_addr_id) || (rd_addr_ex == rs2_addr_id)))
        begin
            // Hazard detectado!
            stall_pipeline = 1'b1;
            flush_id_ex    = 1'b1;
        end
        else begin
            // Sem hazard, operação normal.
            stall_pipeline = 1'b0;
            flush_id_ex    = 1'b0;
        end
    end

endmodule