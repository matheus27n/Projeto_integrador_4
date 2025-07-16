// Módulo: id_ex_reg.v (VERSÃO FINAL E CORRIGIDA)
// Descrição: Registrador de pipeline entre os estágios ID e EX.

module id_ex_reg (
    input  logic        clk,
    input  logic        rst,

    // --- Sinais de Controle vindos do ID (Entradas) ---
    input  logic        reg_write_en_in,
    input  logic        ALUSrc_in,
    input  logic        MemtoReg_in,
    input  logic        MemRead_in,
    input  logic        MemWrite_in,
    input  logic [3:0]  alu_op_in,
    
    // --- Dados vindos do ID (Entradas) ---
    input  logic [31:0] rs1_data_in,
    input  logic [31:0] rs2_data_in,
    input  logic [31:0] immediate_in,
    input  logic [4:0]  rd_addr_in,

    // --- Saídas para o estágio EX e para o próximo registrador ---
    output logic        reg_write_en_out,
    output logic        ALUSrc_out,
    output logic        MemtoReg_out,
    output logic        MemRead_out,
    output logic        MemWrite_out,
    output logic [3:0]  alu_op_out,
    output logic [31:0] rs1_data_out,
    output logic [31:0] rs2_data_out,
    output logic [31:0] immediate_out,
    output logic [4:0]  rd_addr_out
);

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            // Zera todos os sinais de controle no reset
            reg_write_en_out <= 1'b0;
            ALUSrc_out       <= 1'b0;
            MemtoReg_out     <= 1'b0;
            MemRead_out      <= 1'b0;
            MemWrite_out     <= 1'b0;
            alu_op_out       <= 4'b0;
            // Zera dados também
            rs1_data_out     <= 32'b0;
            rs2_data_out     <= 32'b0;
            immediate_out    <= 32'b0;
            rd_addr_out      <= 5'b0;
        end else begin
            // Operação normal: passa todas as entradas para as saídas
            reg_write_en_out <= reg_write_en_in;
            ALUSrc_out       <= ALUSrc_in;
            MemtoReg_out     <= MemtoReg_in;
            MemRead_out      <= MemRead_in;
            MemWrite_out     <= MemWrite_in;
            alu_op_out       <= alu_op_in;
            rs1_data_out     <= rs1_data_in;
            rs2_data_out     <= rs2_data_in;
            immediate_out    <= immediate_in;
            rd_addr_out      <= rd_addr_in;
        end
    end

endmodule