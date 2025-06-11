// ====================================================================
//                            TOP MODULE
// ====================================================================
// Módulo de topo responsável por instanciar o datapath completo.
// Encaminha sinais importantes para o testbench de monitoramento.
// ====================================================================

module top (
    input  wire        clk,            // Clock principal
    input  wire        reset,          // Sinal de reset síncrono

    // Sinais de saída conectados ao estágio de Write-Back (WB)
    output wire [31:0] wb_pc,          // Valor do PC no estágio WB
    output wire [31:0] wb_instruction, // Instrução em WB
    output wire [31:0] wb_write_data,  // Dado a ser escrito no registrador
    output wire [4:0]  wb_rd_addr,     // Registrador de destino (rd)
    output wire        wb_RegWrite,    // Sinal de escrita no registrador
    output wire        wb_MemWrite,    // Sinal de escrita na memória
    output wire [31:0] wb_mem_addr,    // Endereço de memória para escrita
    output wire [31:0] wb_mem_wdata    // Dado a ser escrito na memória
);

    // Instanciação do datapath com mapeamento explícito das saídas
    datapath dp (
        .clk(clk),
        .reset(reset),
        .o_wb_pc(wb_pc),
        .o_wb_instr(wb_instruction),
        .o_wb_write_data(wb_write_data),
        .o_wb_rd_addr(wb_rd_addr),
        .o_wb_RegWrite(wb_RegWrite),
        .o_wb_MemWrite(wb_MemWrite),
        .o_wb_mem_addr(wb_mem_addr),
        .o_wb_mem_wdata(wb_mem_wdata)
    );

endmodule
