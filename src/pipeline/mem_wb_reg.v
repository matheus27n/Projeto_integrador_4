// Módulo: mem_wb_reg.v
// Descrição: Registrador de pipeline entre os estágios MEM e WB.

module mem_wb_reg (
    input  logic        clk,
    input  logic        rst,

    // Sinais de Controle vindos do MEM
    input  logic        reg_write_en_in,
    input  logic        MemtoReg_in,
    
    // Dados vindos do MEM
    input  logic [31:0] alu_result_in,
    input  logic [31:0] mem_read_data_in,
    input  logic [4:0]  rd_addr_in,

    // Saídas para o estágio WB
    output logic        reg_write_en_out,
    output logic        MemtoReg_out,
    output logic [31:0] alu_result_out,
    output logic [31:0] mem_read_data_out,
    output logic [4:0]  rd_addr_out
);

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            reg_write_en_out <= 1'b0;
            MemtoReg_out     <= 1'b0;
            // Opcional zerar dados, mas bom para debug
            alu_result_out   <= 32'b0;
            mem_read_data_out<= 32'b0;
            rd_addr_out      <= 5'b0;
        end else begin
            // Operação normal: passa as entradas para as saídas
            reg_write_en_out  <= reg_write_en_in;
            MemtoReg_out      <= MemtoReg_in;
            alu_result_out    <= alu_result_in;
            mem_read_data_out <= mem_read_data_in;
            rd_addr_out       <= rd_addr_in;
        end
    end

endmodule