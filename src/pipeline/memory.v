// Módulo: memory.v (ATUALIZADO COM INICIALIZAÇÃO INTERNA)
// Descrição: Memória síncrona de 1024 palavras de 32 bits.

module memory (
    input  logic        clk,
    input  logic        mem_write_en,
    input  logic [31:0] addr,
    input  logic [31:0] write_data,
    output logic [31:0] read_data
);
    // Declara a memória
    logic [31:0] mem_array[1023:0];
    
    wire [9:0] word_addr = addr[11:2];

    // --- BLOCO DE INICIALIZAÇÃO PARA SIMULAÇÃO ---
    // Este bloco agora escreve as instruções diretamente na memória
    // assim que a simulação começa.
    initial begin
        // (Boa prática) Primeiro, zera toda a memória para um estado limpo
        for (int i = 0; i < 1024; i = i + 1) begin
            mem_array[i] = 32'b0;
        end
        
        // Agora, escreve as instruções do nosso programa de teste
        mem_array[0] = 32'h0062A223; // sw x6, 4(x5)
        mem_array[1] = 32'h0042A383; // lw x7, 4(x5)
    end
    
    // Lógica de Escrita Síncrona
    always_ff @(posedge clk) begin
        if (mem_write_en) begin
            mem_array[word_addr] <= write_data;
        end
    end

    // Lógica de Leitura Assíncrona
    assign read_data = mem_array[word_addr];

endmodule