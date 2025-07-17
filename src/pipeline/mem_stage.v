module mem_stage (
    // Entradas do registrador EX/MEM
    input  logic [31:0] alu_result,
    input  logic [31:0] rs2_data,
    input  logic        MemRead,
    input  logic        MemWrite,

    // Conexão com a memória de dados
    output logic [31:0] dmem_addr,
    output logic [31:0] dmem_write_data,
    input  logic [31:0] dmem_read_data,

    // Saídas para o registrador MEM/WB
    output logic [31:0] mem_read_data_out
);
    // O endereço da memória de dados é o resultado da ULA
    assign dmem_addr = alu_result;
    
    // O dado a ser escrito na memória é o valor de rs2
    assign dmem_write_data = rs2_data;

    // A saída deste estágio é simplesmente o dado lido da memória.
    // Se MemRead for 0, o valor não importa, mas o fio está conectado.
    assign mem_read_data_out = dmem_read_data;

    // Os sinais MemRead e MemWrite são apenas passados para a memória
    // através do módulo top.
endmodule