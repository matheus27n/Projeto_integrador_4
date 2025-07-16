// Módulo: reg_file.v
// Descrição: Implementa o banco de 32 registradores de 32 bits do RISC-V.

module reg_file (
    input  logic         clk,         // Clock
    input  logic         rst,         // Reset
    input  logic         we,          // Write Enable
    input  logic [4:0]   rs1_addr,    // Endereço do registrador de leitura 1
    input  logic [4:0]   rs2_addr,    // Endereço do registrador de leitura 2
    input  logic [4:0]   rd_addr,     // Endereço do registrador de escrita
    input  logic [31:0]  rd_data,     // Dado de escrita
    output logic [31:0]  rs1_data,    // Dado de saída 1
    output logic [31:0]  rs2_data     // Dado de saída 2
);

    // Declaração do banco de registradores: um array de 32 posições, cada uma com 32 bits.
    logic [31:0] registers[31:0];

    // Lógica de Escrita Síncrona (sensível à borda de subida do clock)
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            // Com o reset, zera todos os registradores (bom para simulação inicial)
            for (int i = 0; i < 32; i = i + 1) begin
                registers[i] <= 32'b0;
            end
        end else if (we && (rd_addr != 5'b0)) begin
            // Se o write enable estiver ativo E o endereço de destino NÃO for x0,
            // escreve o dado no registrador correspondente.
            registers[rd_addr] <= rd_data;
        end
    end

    // Lógica de Leitura Assíncrona (combinacional)
    // A leitura reflete o estado atual dos registradores.
    // Se o endereço for x0, retorna 0. Senão, retorna o valor do registrador.
    assign rs1_data = (rs1_addr == 5'b0) ? 32'b0 : registers[rs1_addr];
    assign rs2_data = (rs2_addr == 5'b0) ? 32'b0 : registers[rs2_addr];

endmodule