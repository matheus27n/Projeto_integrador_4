// Módulo: if_id_reg.v
// Descrição: Registrador de pipeline entre os estágios IF e ID.

module if_id_reg (
    input  logic        clk,
    input  logic        rst,
    input  logic        flush, // Sinal para limpar o registrador (inserir NOP)
    // Futuramente: entrada para stall
    
    // Entradas vindas do estágio IF
    input  logic [31:0] instruction_in,
    input  logic [31:0] pc_plus_4_in,

    // Saídas para o estágio ID
    output logic [31:0] instruction_out,
    output logic [31:0] pc_plus_4_out
);
    
    // Instrução NOP (addi x0, x0, 0) para ser usada no flush
    localparam NOP_INSTRUCTION = 32'h00000013;

    always_ff @(posedge clk, posedge rst) begin
        if (rst || flush) begin
            // Se resetar ou limpar, insere uma instrução NOP e zera o PC+4
            instruction_out <= NOP_INSTRUCTION;
            pc_plus_4_out   <= 32'b0;
        end else begin
            // Em operação normal, apenas passa os dados de entrada para a saída
            instruction_out <= instruction_in;
            pc_plus_4_out   <= pc_plus_4_in;
        end
    end

endmodule