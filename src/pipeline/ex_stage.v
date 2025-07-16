// Módulo: ex_stage.v
// Descrição: Estágio de Execução (EX).

module ex_stage (
    // Entradas vindas do registrador ID/EX
    input  logic [31:0] rs1_data,
    input  logic [31:0] rs2_data,
    input  logic [31:0] immediate,
    input  logic        ALUSrc,
    input  logic [3:0]  alu_op,
    
    // Saídas para o próximo estágio (EX/MEM)
    output logic [31:0] alu_result,
    output logic        zero_flag
);

    logic [31:0] alu_in_b;

    // MUX para selecionar a segunda entrada da ULA:
    // Se ALUSrc=1, usa o imediato; se ALUSrc=0, usa o dado do registrador rs2.
    assign alu_in_b = (ALUSrc) ? immediate : rs2_data;

    // Instanciação da ULA
    alu alu_inst (
        .a(rs1_data),
        .b(alu_in_b),
        .alu_op(alu_op),
        .result(alu_result),
        .zero(zero_flag)
    );

endmodule