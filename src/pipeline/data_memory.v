module data_memory (
    input  wire        clk,
    input  wire        MemRead,
    input  wire        MemWrite,
    input  wire [31:0] addr,
    input  wire [31:0] write_data,
    output reg  [31:0] read_data
);

// Memória de 1024 Bytes (256 palavras de 32 bits)
reg [31:0] memory [0:255];

// A escrita ocorre na borda de subida do clock se MemWrite estiver ativo
always @(posedge clk) begin
    if (MemWrite) begin
        memory[addr[9:2]] <= write_data;
    end
end

// A leitura também é síncrona. O dado estará disponível no *próximo* ciclo.
// O pipeline já lida com essa latência de 1 ciclo.
always @(posedge clk) begin
    if (MemRead) begin
        read_data <= memory[addr[9:2]];
    end
end

endmodule