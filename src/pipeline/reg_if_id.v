`timescale 1ns / 1ps

// --------------------------------------------------------------------
// Módulo: reg_if_id
// Função: Armazena a instrução e o PC entre os estágios IF e ID.
// --------------------------------------------------------------------
module reg_if_id (
    input clk, input reset,
    input [31:0] if_pc,
    input [31:0] if_instruction,
    output reg [31:0] id_pc,
    output reg [31:0] id_instruction
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            id_pc <= 32'h0;
            id_instruction <= 32'h0; // NOP
        end else begin
            id_pc <= if_pc;
            id_instruction <= if_instruction;
        end
    end
endmodule


// --------------------------------------------------------------------
// Módulo: reg_id_ex
// Função: Armazena todos os dados e sinais de controle entre ID e EX.
// --------------------------------------------------------------------
module reg_id_ex (
    input clk, input reset,
    input [31:0] id_pc,
    input [31:0] id_instruction,
    input id_MemtoReg, id_RegWrite, id_MemRead, id_MemWrite, id_ALUSrc,
    input [3:0] id_ALUControl,
    input [31:0] id_rd1, id_rd2,
    input [31:0] id_imm_ext,
    input [4:0]  id_rd_addr,
    
    output reg [31:0] ex_pc,
    output reg [31:0] ex_instruction,
    output reg ex_MemtoReg, ex_RegWrite, ex_MemRead, ex_MemWrite, ex_ALUSrc,
    output reg [3:0]  ex_ALUControl,
    output reg [31:0] ex_rd1, ex_rd2,
    output reg [31:0] ex_imm_ext,
    output reg [4:0]  ex_rd_addr
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            {ex_MemtoReg, ex_RegWrite, ex_MemRead, ex_MemWrite, ex_ALUSrc} <= 0;
            ex_ALUControl <= 4'b0; ex_pc <= 0; ex_instruction <= 0; ex_rd1 <= 0;
            ex_rd2 <= 0; ex_imm_ext <= 0; ex_rd_addr <= 0;
        end else begin
            ex_pc<=id_pc; ex_instruction<=id_instruction; ex_MemtoReg<=id_MemtoReg; 
            ex_RegWrite<=id_RegWrite; ex_MemRead<=id_MemRead; ex_MemWrite<=id_MemWrite; 
            ex_ALUControl<=id_ALUControl; ex_ALUSrc<=id_ALUSrc; ex_rd1<=id_rd1; 
            ex_rd2<=id_rd2; ex_imm_ext<=id_imm_ext; ex_rd_addr<=id_rd_addr;
        end
    end
endmodule


// --------------------------------------------------------------------
// Módulo: reg_ex_mem
// Função: Armazena o resultado da ULA e outros sinais entre EX e MEM.
// --------------------------------------------------------------------
module reg_ex_mem(
    input clk, input reset,
    input [31:0] ex_pc,
    input [31:0] ex_instruction,
    input ex_MemtoReg, ex_RegWrite, ex_MemRead, ex_MemWrite,
    input [31:0] ex_alu_result,
    input [31:0] ex_rd2,
    input [4:0]  ex_rd_addr,
    
    output reg [31:0] mem_pc,
    output reg [31:0] mem_instruction,
    output reg mem_MemtoReg, mem_RegWrite, mem_MemRead, mem_MemWrite,
    output reg [31:0] mem_alu_result,
    output reg [31:0] mem_rd2,
    output reg [4:0]  mem_rd_addr
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            {mem_MemtoReg, mem_RegWrite, mem_MemRead, mem_MemWrite} <= 0;
            mem_pc <= 0; mem_instruction <= 0; mem_alu_result <= 0;
            mem_rd2 <= 0; mem_rd_addr <= 0;
        end else begin
            mem_pc<=ex_pc; mem_instruction<=ex_instruction; mem_MemtoReg<=ex_MemtoReg; 
            mem_RegWrite<=ex_RegWrite; mem_MemRead<=ex_MemRead; mem_MemWrite<=ex_MemWrite; 
            mem_alu_result<=ex_alu_result; mem_rd2<=ex_rd2; mem_rd_addr<=ex_rd_addr;
        end
    end
endmodule


// --------------------------------------------------------------------
// Módulo: reg_mem_wb
// Função: Armazena o resultado final (da ULA ou da memória) entre MEM e WB.
// --------------------------------------------------------------------
module reg_mem_wb(
    input clk, input reset,
    input [31:0] mem_pc,
    input [31:0] mem_instruction,
    input mem_MemtoReg, mem_RegWrite,
    input [31:0] mem_read_data,
    input [31:0] mem_alu_result,
    input [4:0]  mem_rd_addr,
    
    output reg [31:0] wb_pc,
    output reg [31:0] wb_instruction,
    output reg wb_MemtoReg, wb_RegWrite,
    output reg [31:0] wb_read_data,
    output reg [31:0] wb_alu_result,
    output reg [4:0]  wb_rd_addr
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            {wb_MemtoReg, wb_RegWrite} <= 0;
            wb_pc <= 0; wb_instruction <= 0; wb_read_data <= 0;
            wb_alu_result <= 0; wb_rd_addr <= 0;
        end else begin
            wb_pc<=mem_pc; wb_instruction<=mem_instruction; wb_MemtoReg<=mem_MemtoReg; 
            wb_RegWrite<=mem_RegWrite; wb_read_data<=mem_read_data; 
            wb_alu_result<=mem_alu_result; wb_rd_addr<=mem_rd_addr;
        end
    end
endmodule