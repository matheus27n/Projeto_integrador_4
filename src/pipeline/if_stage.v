// Módulo: if_stage.v
// Descrição: Estágio de Busca de Instrução (IF).

module if_stage (
    input  logic        clk,
    input  logic        rst,
    // Futuramente: entradas para stall, flush e pc_branch
    output logic [31:0] pc_out,
    output logic [31:0] pc_plus_4_out
);

    logic [31:0] pc_reg;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            pc_reg <= 32'b0; // PC começa em 0 no reset
        end else begin
            // Por enquanto, o PC sempre avança para a próxima instrução
            // No futuro, um MUX aqui selecionará entre PC+4 e um endereço de desvio
            pc_reg <= pc_plus_4_out;
        end
    end

    // Saída do PC atual
    assign pc_out = pc_reg;
    // Soma 4 para obter o endereço da próxima instrução
    assign pc_plus_4_out = pc_reg + 32'd4;

endmodule