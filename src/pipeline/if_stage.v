// Módulo: if_stage.v (MODIFICADO)
// Descrição: Adicionada lógica de stall e MUX para seleção do PC.
module if_stage (
    input  logic       clk,
    input  logic       rst,
    input  logic       stall_pipeline, // MUDANÇA: Sinal da unidade de detecção de hazard
    input  logic       PCSrc,          // MUDANÇA: Sinal para selecionar desvio (branch)
    input  logic [31:0] pc_branch,      // MUDANÇA: Endereço do desvio
    
    output logic [31:0] pc_out,
    output logic [31:0] pc_plus_4_out
);

    logic [31:0] pc_reg;
    logic [31:0] pc_next;

    // Lógica de atualização do PC
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            pc_reg <= 32'b0;
        end
        // MUDANÇA: O PC só é atualizado se o pipeline não estiver parado.
        else if (!stall_pipeline) begin
            pc_reg <= pc_next;
        end
    end
    
    // MUX para selecionar o próximo valor do PC
    assign pc_plus_4_out = pc_reg + 32'd4;
    assign pc_next = (PCSrc) ? pc_branch : pc_plus_4_out;
    
    // Saída do PC atual para a memória de instruções
    assign pc_out = pc_reg;

endmodule