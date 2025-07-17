// Módulo: ex_stage.v (MODIFICADO PARA CORRIGIR HAZARD DE STORE)
// Descrição: Adicionada uma saída para o dado de store já encaminhado.
module ex_stage (
    // Entradas do registrador ID/EX
    input  logic [31:0] rs1_data,
    input  logic [31:0] rs2_data,
    input  logic [31:0] immediate,
    input  logic        ALUSrc,
    input  logic [3:0]  alu_op,
    
    // Entradas para Forwarding
    input  logic [1:0]  forward_a,
    input  logic [1:0]  forward_b,
    input  logic [31:0] alu_result_mem,
    input  logic [31:0] wb_data,

    // Saídas
    output logic [31:0] alu_result,
    output logic        zero_flag,
    output logic [31:0] rs2_data_forwarded_out // NOVO: Saída para o dado de store
);
    
    logic [31:0] alu_in_a;
    logic [31:0] alu_in_b_reg;
    logic [31:0] alu_in_b;

    // MUX de Forwarding para o operando A (rs1)
    always_comb begin
        case (forward_a)
            2'b00:  alu_in_a = rs1_data;
            2'b01:  alu_in_a = alu_result_mem;
            2'b10:  alu_in_a = wb_data;
            default: alu_in_a = rs1_data;
        endcase
    end
    
    // MUX de Forwarding para o operando B (rs2)
    always_comb begin
        case (forward_b)
            2'b00:  alu_in_b_reg = rs2_data;
            2'b01:  alu_in_b_reg = alu_result_mem;
            2'b10:  alu_in_b_reg = wb_data;
            default: alu_in_b_reg = rs2_data;
        endcase
    end
    
    // NOVO: Expõe o valor de rs2 (potencialmente encaminhado) para o estágio de memória
    assign rs2_data_forwarded_out = alu_in_b_reg;

    // MUX original para selecionar entre registrador e imediato
    assign alu_in_b = (ALUSrc) ? immediate : alu_in_b_reg;

    // Instanciação da ULA
    alu alu_inst (
        .a(alu_in_a),
        .b(alu_in_b),
        .alu_op(alu_op),
        .result(alu_result),
        .zero(zero_flag)
    );

endmodule