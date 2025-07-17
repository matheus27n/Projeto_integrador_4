// Módulo: id_ex_reg.v
// Descrição: Registrador de pipeline entre os estágios ID e EX.
// Armazena todos os dados e sinais de controle necessários para o estágio EX.

module id_ex_reg (
    input  logic       clk,
    input  logic       rst,
    input  logic       flush_id_ex, // Vem da unidade de detecção de hazard

    // Entradas de Controle e Dados do estágio ID
    input  logic       reg_write_en_in,
    input  logic       ALUSrc_in,
    input  logic       MemtoReg_in,
    input  logic       MemRead_in,
    input  logic       MemWrite_in,
    input  logic       Branch_in,
    input  logic       Jump_in,
    input  logic [3:0]  alu_op_in,
    input  logic [31:0] pc_plus_4_in,
    input  logic [31:0] rs1_data_in,
    input  logic [31:0] rs2_data_in,
    input  logic [31:0] immediate_in,
    input  logic [4:0]  rd_addr_in,
    input  logic [4:0]  rs1_addr_in,
    input  logic [4:0]  rs2_addr_in,

    // Saídas para o estágio EX
    output logic       reg_write_en_out,
    output logic       ALUSrc_out,
    output logic       MemtoReg_out,
    output logic       MemRead_out,
    output logic       MemWrite_out,
    output logic       Branch_out,
    output logic       Jump_out,
    output logic [3:0]  alu_op_out,
    output logic [31:0] pc_plus_4_out,
    output logic [31:0] rs1_data_out,
    output logic [31:0] rs2_data_out,
    output logic [31:0] immediate_out,
    output logic [4:0]  rd_addr_out,
    output logic [4:0]  rs1_addr_out,
    output logic [4:0]  rs2_addr_out
);

    always_ff @(posedge clk, posedge rst) begin
        // No reset ou em um flush (bolha), zera todos os sinais de controle.
        if (rst || flush_id_ex) begin
            reg_write_en_out <= 1'b0;
            ALUSrc_out       <= 1'b0;
            MemtoReg_out     <= 1'b0;
            MemRead_out      <= 1'b0;
            MemWrite_out     <= 1'b0;
            Branch_out       <= 1'b0;
            Jump_out         <= 1'b0;
            alu_op_out       <= 4'b0;
            // Zera os dados também para um estado limpo
            pc_plus_4_out    <= 32'b0;
            rs1_data_out     <= 32'b0;
            rs2_data_out     <= 32'b0;
            immediate_out    <= 32'b0;
            rd_addr_out      <= 5'b0;
            rs1_addr_out     <= 5'b0;
            rs2_addr_out     <= 5'b0;
        end else begin
            // Operação normal: passa todas as entradas para as saídas no pulso de clock.
            reg_write_en_out <= reg_write_en_in;
            ALUSrc_out       <= ALUSrc_in;
            MemtoReg_out     <= MemtoReg_in;
            MemRead_out      <= MemRead_in;
            MemWrite_out     <= MemWrite_in;
            Branch_out       <= Branch_in;
            Jump_out         <= Jump_in;
            alu_op_out       <= alu_op_in;
            pc_plus_4_out    <= pc_plus_4_in;
            rs1_data_out     <= rs1_data_in;
            rs2_data_out     <= rs2_data_in;
            immediate_out    <= immediate_in;
            rd_addr_out      <= rd_addr_in;
            rs1_addr_out     <= rs1_addr_in;
            rs2_addr_out     <= rs2_addr_in;
        end
    end

endmodule