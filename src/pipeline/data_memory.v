// ========================================================
// Módulo: data_memory
// Descrição: Versão corrigida com tamanho expandido para
//            1024 palavras (4KB) para evitar acesso
//            fora dos limites.
// ========================================================
module data_memory (
    input  wire         clk,
    input  wire         MemRead,
    input  wire         MemWrite,
    input  wire [31:0]  addr,
    input  wire [31:0]  write_data,
    output wire [31:0]  read_data
);

    // Memória expandida para 1024 palavras de 32 bits (4KB)
    reg [31:0] memory [0:1023];

    // Escrita síncrona na memória
    always @(posedge clk) begin
        if (MemWrite) begin
            // O endereçamento agora usa os bits [11:2] para cobrir as 1024 posições
            memory[addr[11:2]] <= write_data;
        end
    end

    // Leitura assíncrona
    assign read_data = memory[addr[11:2]];

endmodule