// ========================================================
// Módulo: data_memory
// Descrição: Memória de dados síncrona para o processador RISC-V.
//            Suporta operações de leitura e escrita de 32 bits.
// ========================================================
module data_memory (
    input  wire        clk,          // Clock principal
    input  wire        MemRead,      // Sinal de leitura da memória
    input  wire        MemWrite,     // Sinal de escrita na memória
    input  wire [31:0] addr,         // Endereço de acesso (byte-addressable)
    input  wire [31:0] write_data,   // Dados a serem escritos
    output reg  [31:0] read_data     // Dados lidos da memória
);

    // ----------------------------------------------------
    // Memória de 1024 bytes = 256 palavras de 32 bits
    // A indexação usa addr[9:2] para obter o endereço da palavra
    // ----------------------------------------------------
    reg [31:0] memory [0:255];

    // ----------------------------------------------------
    // Escrita síncrona na memória
    // Ocorre na borda de subida do clock se MemWrite = 1
    // ----------------------------------------------------
    always @(posedge clk) begin
        if (MemWrite) begin
            memory[addr[9:2]] <= write_data;
        end
    end

    // ----------------------------------------------------
    // Leitura síncrona da memória
    // O dado lido estará disponível no próximo ciclo
    // Isso é compatível com o pipeline que já lida com essa latência
    // ----------------------------------------------------
    always @(posedge clk) begin
        if (MemRead) begin
            read_data <= memory[addr[9:2]];
        end
    end

endmodule
