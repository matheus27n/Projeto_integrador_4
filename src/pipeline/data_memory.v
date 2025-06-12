// ========================================================
// Módulo: data_memory
// Descrição: Memória de dados para o processador RISC-V.
// ========================================================
module data_memory (
    input  wire        clk,
    input  wire        MemRead,     // Não é mais usado para a lógica de leitura, mas pode ser útil para depuração.
    input  wire        MemWrite,
    input  wire [31:0] addr,
    input  wire [31:0] write_data,
    output wire [31:0] read_data    // <<--- MUDANÇA 1: DEVE SER 'wire'
);

    // Memória de 256 palavras de 32 bits
    reg [31:0] memory [0:255];

    //MEMORIA DE DADOS SÃO REGISTRADORES
    // Escrita síncrona na memória (na borda de subida do clock)
    always @(posedge clk) begin
        if (MemWrite) begin
            memory[addr[9:2]] <= write_data;
        end
    end

    
    // O dado do endereço 'addr' está sempre disponível na saída.
    assign read_data = memory[addr[9:2]];


endmodule