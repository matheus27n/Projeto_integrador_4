// Módulo: processor_top.v (CORRIGIDO COM ARQUITETURA HARVARD)
// Descrição: Módulo principal com memórias de instrução e dados separadas.

module processor_top (
    input  logic clk,
    input  logic rst,
    
    // Saídas para observação no testbench
    output logic [31:0] dbg_pc_if,
    output logic [31:0] dbg_instr_id,
    output logic [31:0] dbg_alu_result_ex,
    output logic [31:0] dbg_mem_read_data
);

    // --- Sinais Internos (Fios de Conexão) ---
    
    // Sinais IF
    logic [31:0] pc_for_mem;
    logic [31:0] instruction_from_mem;
    logic [31:0] pc_plus_4_if;
    
    // Sinais IF -> ID
    logic [31:0] instruction_id;
    
    // Sinais ID -> EX
    logic [31:0] rs1_data_id, rs2_data_id, immediate_id;
    logic [4:0]  rd_addr_id;
    logic        reg_write_en_id, ALUSrc_id, MemtoReg_id, MemRead_id, MemWrite_id;
    logic [3:0]  alu_op_id;

    // Sinais EX
    logic [31:0] rs1_data_ex, rs2_data_ex, immediate_ex;
    logic [4:0]  rd_addr_ex;
    logic        reg_write_en_ex, ALUSrc_ex, MemtoReg_ex, MemRead_ex, MemWrite_ex;
    logic [3:0]  alu_op_ex;
    logic [31:0] alu_result_ex;
    logic        zero_flag_ex;
    
    // Sinais MEM
    logic [31:0] alu_result_mem, rs2_data_mem;
    logic [4:0]  rd_addr_mem;
    logic        reg_write_en_mem, MemtoReg_mem, MemRead_mem, MemWrite_mem;
    logic [31:0] data_from_dmem;

    // --- Instanciação dos Módulos ---

    // Memória de Instruções (imem)
    memory imem_inst (
        .clk(clk),
        .mem_write_en(1'b0), // Nunca se escreve na memória de instruções
        .addr(pc_for_mem),   // Endereço vem do PC
        .write_data(32'b0),
        .read_data(instruction_from_mem) // Saída é a instrução
    );

    // Memória de Dados (dmem)
    memory dmem_inst (
        .clk(clk),
        .mem_write_en(MemWrite_mem),   // Controlado pelo estágio MEM
        .addr(alu_result_mem),         // Endereço vem do resultado da ULA
        .write_data(rs2_data_mem),     // Dado a ser escrito vem de rs2
        .read_data(data_from_dmem)     // Dado lido para o LW
    );

    if_stage if_stage_inst (
        .clk(clk),
        .rst(rst),
        .pc_out(pc_for_mem),
        .pc_plus_4_out(pc_plus_4_if)
    );

    if_id_reg if_id_reg_inst (
        .clk(clk),
        .rst(rst),
        .flush(1'b0),
        .instruction_in(instruction_from_mem),
        .pc_plus_4_in(pc_plus_4_if),
        .instruction_out(instruction_id),
        .pc_plus_4_out()
    );

    id_stage id_stage_inst (
        .clk(clk),
        .rst(rst),
        .instruction(instruction_id),
        .wb_reg_write_en(1'b0),
        .wb_rd_addr(5'b0),
        .wb_rd_data(32'b0),
        .reg_write_en_out(reg_write_en_id),
        .ALUSrc_out(ALUSrc_id),
        .MemtoReg_out(MemtoReg_id),
        .MemRead_out(MemRead_id),
        .MemWrite_out(MemWrite_id),
        .alu_op_out(alu_op_id),
        .rs1_data(rs1_data_id),
        .rs2_data(rs2_data_id),
        .immediate(immediate_id),
        .rd_addr(rd_addr_id)
    );
    
    id_ex_reg id_ex_reg_inst (
        .clk(clk),
        .rst(rst),
        .reg_write_en_in(reg_write_en_id),
        .ALUSrc_in(ALUSrc_id),
        .MemtoReg_in(MemtoReg_id),
        .MemRead_in(MemRead_id),
        .MemWrite_in(MemWrite_id),
        .alu_op_in(alu_op_id),
        .rs1_data_in(rs1_data_id),
        .rs2_data_in(rs2_data_id),
        .immediate_in(immediate_id),
        .rd_addr_in(rd_addr_id),
        .reg_write_en_out(reg_write_en_ex),
        .ALUSrc_out(ALUSrc_ex),
        .MemtoReg_out(MemtoReg_ex),
        .MemRead_out(MemRead_ex),
        .MemWrite_out(MemWrite_ex),
        .alu_op_out(alu_op_ex),
        .rs1_data_out(rs1_data_ex),
        .rs2_data_out(rs2_data_ex),
        .immediate_out(immediate_ex),
        .rd_addr_out(rd_addr_ex)
    );

    ex_stage ex_stage_inst (
        .rs1_data(rs1_data_ex),
        .rs2_data(rs2_data_ex),
        .immediate(immediate_ex),
        .ALUSrc(ALUSrc_ex),
        .alu_op(alu_op_ex),
        .alu_result(alu_result_ex),
        .zero_flag()
    );

    ex_mem_reg ex_mem_reg_inst(
        .clk(clk),
        .rst(rst),
        .reg_write_en_in(reg_write_en_ex),
        .MemtoReg_in(MemtoReg_ex),
        .MemRead_in(MemRead_ex),
        .MemWrite_in(MemWrite_ex),
        .alu_result_in(alu_result_ex),
        .rs2_data_in(rs2_data_ex),
        .rd_addr_in(rd_addr_ex),
        .reg_write_en_out(reg_write_en_mem),
        .MemtoReg_out(MemtoReg_mem),
        .MemRead_out(MemRead_mem),
        .MemWrite_out(MemWrite_mem),
        .alu_result_out(alu_result_mem),
        .rs2_data_out(rs2_data_mem),
        .rd_addr_out(rd_addr_mem)
    );
    
    // --- Atribuições para Debug ---
    assign dbg_pc_if         = pc_for_mem;
    assign dbg_instr_id      = instruction_id;
    assign dbg_alu_result_ex = alu_result_ex;
    assign dbg_mem_read_data = data_from_dmem;

endmodule