
module processor_top (
    input  logic clk,
    input  logic rst
);

    // --- Sinais Internos ---
    // ... (outros sinais permanecem os mesmos)
    logic [31:0] pc_for_mem, instruction_from_mem, pc_plus_4_if;
    logic [31:0] instruction_id, pc_plus_4_id;
    logic [31:0] rs1_data_id, rs2_data_id, immediate_id;
    logic [4:0]  rd_addr_id, rs1_addr_id, rs2_addr_id;
    logic        reg_write_en_id, ALUSrc_id, MemtoReg_id, MemRead_id, MemWrite_id, Branch_id, Jump_id;
    logic [3:0]  alu_op_id;
    logic [31:0] pc_plus_4_ex;
    logic [31:0] rs1_data_ex, rs2_data_ex, immediate_ex;
    logic [4:0]  rd_addr_ex, rs1_addr_ex, rs2_addr_ex;
    logic        reg_write_en_ex, ALUSrc_ex, MemtoReg_ex, MemRead_ex, MemWrite_ex, Branch_ex, Jump_ex;
    logic [3:0]  alu_op_ex;
    logic [31:0] alu_result_ex;
    logic        zero_flag_ex;
    logic [31:0] rs2_data_forwarded_ex; // NOVO
    logic [31:0] alu_result_mem, rs2_data_mem;
    logic [4:0]  rd_addr_mem;
    logic        reg_write_en_mem, MemtoReg_mem, MemRead_mem, MemWrite_mem;
    logic [31:0] dmem_read_data;
    logic [31:0] alu_result_wb, mem_data_wb;
    logic [4:0]  rd_addr_wb;
    logic        reg_write_en_wb, MemtoReg_wb;
    logic [31:0] wb_data;
    logic [1:0] forward_a_ctrl, forward_b_ctrl;
    logic       stall_pipeline;
    logic       flush_id_ex;
    logic       PCSrc;
    logic [31:0] pc_branch;

    // --- Instanciação dos Módulos ---
    memory imem_inst ( .clk(clk), .mem_write_en(1'b0), .addr(pc_for_mem), .write_data(32'b0), .read_data(instruction_from_mem) );
    memory dmem_inst ( .clk(clk), .mem_write_en(MemWrite_mem), .addr(alu_result_mem), .write_data(rs2_data_mem), .read_data(dmem_read_data) );

    if_stage if_stage_inst ( .clk(clk), .rst(rst), .stall_pipeline(stall_pipeline), .PCSrc(PCSrc), .pc_branch(pc_branch), .pc_out(pc_for_mem), .pc_plus_4_out(pc_plus_4_if) );
    if_id_reg if_id_reg_inst ( .clk(clk), .rst(rst), .flush(PCSrc), .stall_pipeline(stall_pipeline), .instruction_in(instruction_from_mem), .pc_plus_4_in(pc_plus_4_if), .instruction_out(instruction_id), .pc_plus_4_out(pc_plus_4_id) );
    id_stage id_stage_inst (
        .clk(clk), .rst(rst), .instruction(instruction_id),
        .wb_reg_write_en(reg_write_en_wb), .wb_rd_addr(rd_addr_wb), .wb_rd_data(wb_data),
        .reg_write_en_out(reg_write_en_id), .ALUSrc_out(ALUSrc_id), .MemtoReg_out(MemtoReg_id), .MemRead_out(MemRead_id), .MemWrite_out(MemWrite_id), .Branch_out(Branch_id), .Jump_out(Jump_id), .alu_op_out(alu_op_id),
        .rs1_data(rs1_data_id), .rs2_data(rs2_data_id), .immediate(immediate_id), .rd_addr(rd_addr_id), .rs1_addr(rs1_addr_id), .rs2_addr(rs2_addr_id)
    );
    
    id_ex_reg id_ex_reg_inst (
        .clk(clk), .rst(rst), .flush_id_ex(flush_id_ex),
        .reg_write_en_in(reg_write_en_id), .ALUSrc_in(ALUSrc_id), .MemtoReg_in(MemtoReg_id), .MemRead_in(MemRead_id), .MemWrite_in(MemWrite_id), .Branch_in(Branch_id), .Jump_in(Jump_id), .alu_op_in(alu_op_id),
        .pc_plus_4_in(pc_plus_4_id), .rs1_data_in(rs1_data_id), .rs2_data_in(rs2_data_id), .immediate_in(immediate_id), .rd_addr_in(rd_addr_id), .rs1_addr_in(rs1_addr_id), .rs2_addr_in(rs2_addr_id),
        .reg_write_en_out(reg_write_en_ex), .ALUSrc_out(ALUSrc_ex), .MemtoReg_out(MemtoReg_ex), .MemRead_out(MemRead_ex), .MemWrite_out(MemWrite_ex), .Branch_out(Branch_ex), .Jump_out(Jump_ex), .alu_op_out(alu_op_ex),
        .pc_plus_4_out(pc_plus_4_ex), .rs1_data_out(rs1_data_ex), .rs2_data_out(rs2_data_ex), .immediate_out(immediate_ex), .rd_addr_out(rd_addr_ex), .rs1_addr_out(rs1_addr_ex), .rs2_addr_out(rs2_addr_ex)
    );

    ex_stage ex_stage_inst (
        .rs1_data(rs1_data_ex), .rs2_data(rs2_data_ex), .immediate(immediate_ex), .ALUSrc(ALUSrc_ex), .alu_op(alu_op_ex),
        .forward_a(forward_a_ctrl), .forward_b(forward_b_ctrl), .alu_result_mem(alu_result_mem), .wb_data(wb_data),
        .alu_result(alu_result_ex), .zero_flag(zero_flag_ex),
        .rs2_data_forwarded_out(rs2_data_forwarded_ex) // NOVO
    );

    ex_mem_reg ex_mem_reg_inst(
        .clk(clk), .rst(rst),
        .reg_write_en_in(reg_write_en_ex), .MemtoReg_in(MemtoReg_ex), .MemRead_in(MemRead_ex), .MemWrite_in(MemWrite_ex),
        .alu_result_in(alu_result_ex), 
        .rs2_data_in(rs2_data_forwarded_ex), // MUDANÇA: Usa o dado encaminhado para SW
        .rd_addr_in(rd_addr_ex),
        .reg_write_en_out(reg_write_en_mem), .MemtoReg_out(MemtoReg_mem), .MemRead_out(MemRead_mem), .MemWrite_out(MemWrite_mem),
        .alu_result_out(alu_result_mem), .rs2_data_out(rs2_data_mem), .rd_addr_out(rd_addr_mem)
    );

    // ... (restante do código permanece o mesmo)
    mem_wb_reg mem_wb_reg_inst (
        .clk(clk), .rst(rst),
        .reg_write_en_in(reg_write_en_mem), .MemtoReg_in(MemtoReg_mem),
        .alu_result_in(alu_result_mem), .mem_read_data_in(dmem_read_data), .rd_addr_in(rd_addr_mem),
        .reg_write_en_out(reg_write_en_wb), .MemtoReg_out(MemtoReg_wb), .alu_result_out(alu_result_wb), .mem_read_data_out(mem_data_wb), .rd_addr_out(rd_addr_wb)
    );
    
    wb_stage wb_stage_inst (
        .alu_result(alu_result_wb), .mem_read_data(mem_data_wb), .MemtoReg(MemtoReg_wb),
        .wb_data(wb_data)
    );

    assign PCSrc = Branch_ex & zero_flag_ex;
    assign pc_branch = alu_result_ex;

    forwarding_unit fwd_unit (
        .rs1_addr_ex(rs1_addr_ex), .rs2_addr_ex(rs2_addr_ex),
        .rd_addr_mem(rd_addr_mem), .reg_write_en_mem(reg_write_en_mem),
        .rd_addr_wb(rd_addr_wb), .reg_write_en_wb(reg_write_en_wb),
        .forward_a(forward_a_ctrl), .forward_b(forward_b_ctrl)
    );

    hazard_detection_unit hazard_unit (
        .MemRead_ex(MemRead_ex),
        .rd_addr_ex(rd_addr_ex),
        .rs1_addr_id(rs1_addr_id),
        .rs2_addr_id(rs2_addr_id),
        .stall_pipeline(stall_pipeline),
        .flush_id_ex(flush_id_ex)
    );

endmodule