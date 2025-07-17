// ================================================================
//                          REGISTER FILE
// ================================================================
// Implementa os 32 registradores do RISC-V (x0 - x31)
// - x0 é sempre zero (hard-wired)
// - Leitura assíncrona
// - Escrita síncrona na borda de subida do clock
// ================================================================

module register_file (
    input  wire        clk,          // Clock
    input  wire        RegWrite,     // Habilita escrita no registrador
    input  wire [4:0]  rs1,          // Endereço do registrador de leitura 1
    input  wire [4:0]  rs2,          // Endereço do registrador de leitura 2
    input  wire [4:0]  rd,           // Endereço do registrador de escrita
    input  wire [31:0] write_data,   // Dados para escrita
    output wire [31:0] read_data1,   // Saída de leitura 1
    output wire [31:0] read_data2    // Saída de leitura 2
);

    // Banco de registradores: 32 registradores de 32 bits
    reg [31:0] registers [31:0];

    // Leitura assíncrona com proteção para x0 (sempre 0)
    assign read_data1 = (rs1 != 5'd0) ? registers[rs1] : 32'd0;
    assign read_data2 = (rs2 != 5'd0) ? registers[rs2] : 32'd0;

    // Escrita síncrona na borda de subida do clock, exceto no x0
    always @(posedge clk) begin
        if (RegWrite && (rd != 5'd0)) begin
            registers[rd] <= write_data;
        end
    end

endmodule
