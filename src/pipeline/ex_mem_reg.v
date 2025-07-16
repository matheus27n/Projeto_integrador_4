// Módulo: ex_mem_reg.v
// Descrição: Registrador de pipeline entre os estágios EX e MEM.
module ex_mem_reg(
    input  logic        clk,
    input  logic        rst,

    // Sinais de Controle vindos do EX
    input  logic        reg_write_en_in,
    input  logic        MemtoReg_in,
    input  logic        MemRead_in,
    input  logic        MemWrite_in,

    // Dados vindos do EX
    input  logic [31:0] alu_result_in,
    input  logic [31:0] rs2_data_in, // Dado para ser escrito pelo SW
    input  logic [4:0]  rd_addr_in,

    // Saídas para o estágio MEM
    output logic        reg_write_en_out,
    output logic        MemtoReg_out,
    output logic        MemRead_out,
    output logic        MemWrite_out,
    output logic [31:0] alu_result_out,
    output logic [31:0] rs2_data_out,
    output logic [4:0]  rd_addr_out
);

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            reg_write_en_out <= 1'b0;
            MemtoReg_out     <= 1'b0;
            MemRead_out      <= 1'b0;
            MemWrite_out     <= 1'b0;
        end else begin
            reg_write_en_out <= reg_write_en_in;
            MemtoReg_out     <= MemtoReg_in;
            MemRead_out      <= MemRead_in;
            MemWrite_out     <= MemWrite_in;
            alu_result_out   <= alu_result_in;
            rs2_data_out     <= rs2_data_in;
            rd_addr_out      <= rd_addr_in;
        end
    end
endmodule