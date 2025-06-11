// top.v - Versão Final
module top (
    input  wire        clk,
    input  wire        reset,
    // Saídas para o testbench decodificador
    output wire [31:0] wb_pc,
    output wire [31:0] wb_instruction,
    output wire [31:0] wb_write_data,
    output wire [4:0]  wb_rd_addr,
    output wire        wb_RegWrite,
    output wire        wb_MemWrite,
    output wire [31:0] wb_mem_addr,
    output wire [31:0] wb_mem_wdata
);

    datapath dp (
        .clk(clk),
        .reset(reset),
        // Conecta todas as novas saídas do datapath
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