module wb_stage (
    // Entradas do registrador MEM/WB
    input  logic [31:0] alu_result,
    input  logic [31:0] mem_read_data,
    input  logic        MemtoReg,

    // Saída final para o banco de registradores
    output logic [31:0] wb_data
);
    // MUX final: seleciona o dado que será escrito de volta.
    // Se MemtoReg=1, o dado vem da memória (lw).
    // Se MemtoReg=0, o dado vem do resultado da ULA (Tipo-R, Tipo-I).
    assign wb_data = (MemtoReg) ? mem_read_data : alu_result;
endmodule