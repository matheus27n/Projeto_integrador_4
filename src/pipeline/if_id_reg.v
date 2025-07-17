// Módulo: if_id_reg.v (MODIFICADO)
// Descrição: Adicionada lógica de stall.
module if_id_reg (
    input  logic       clk,
    input  logic       rst,
    input  logic       flush,
    input  logic       stall_pipeline, // MUDANÇA: Sinal da unidade de detecção de hazard
    
    input  logic [31:0] instruction_in,
    input  logic [31:0] pc_plus_4_in,

    output logic [31:0] instruction_out,
    output logic [31:0] pc_plus_4_out
);
    
    localparam NOP_INSTRUCTION = 32'h00000013;

    always_ff @(posedge clk, posedge rst) begin
        if (rst || flush) begin
            instruction_out <= NOP_INSTRUCTION;
            pc_plus_4_out   <= 32'b0;
        end
        // MUDANÇA: Se o pipeline não estiver parado, carrega a nova instrução.
        // Se estiver parado (stall=1), o registrador mantém seu valor antigo,
        // efetivamente "congelando" a instrução no estágio ID.
        else if (!stall_pipeline) begin
            instruction_out <= instruction_in;
            pc_plus_4_out   <= pc_plus_4_in;
        end
    end

endmodule