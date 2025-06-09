`timescale 1ns / 1ps

module parte_operativa_pipeline(
    input clk, input reset,
    // Sinais de controle vindos da Unidade de Controle
    input id_ALUSrc, input id_MemtoReg, input id_RegWrite,
    input id_MemRead, input id_MemWrite, input id_Branch, input id_Jump,
    input [3:0] id_ALUControl,
    
    // Saídas para a Unidade de Controle (lidos no estágio ID)
    output wire [6:0] id_opcode,
    output wire [2:0] id_funct3,
    output wire [6:0] id_funct7
);
    // === FIOS DE CONEXÃO ENTRE ESTÁGIOS ===
    wire [31:0] if_pc_plus_4, if_instruction;
    wire [31:0] id_pc_plus_4, id_instruction;
    wire [31:0] id_rd1, id_rd2;
    reg  [31:0] id_imm_ext;
    wire [4:0]  id_rd_addr;
    wire [31:0] ex_pc_plus_4, ex_rd1, ex_rd2, ex_imm_ext;
    wire [4:0]  ex_rd_addr;
    wire        ex_MemtoReg, ex_RegWrite, ex_MemRead, ex_MemWrite, ex_ALUSrc;
    wire [3:0]  ex_ALUControl;
    reg  [31:0] ex_alu_result;
    wire [31:0] ex_alu_src_b;
    wire [31:0] mem_alu_result, mem_rd2;
    wire [4:0]  mem_rd_addr;
    wire        mem_MemtoReg, mem_RegWrite, mem_MemRead, mem_MemWrite;
    wire [31:0] mem_read_data;
    wire [31:0] wb_read_data, wb_alu_result;
    wire [4:0]  wb_rd_addr;
    wire        wb_MemtoReg, wb_RegWrite;
    wire [31:0] wb_write_data;

    //==================================================
    // ESTÁGIO IF: Instruction Fetch
    //==================================================
    reg [31:0] PC;
    wire [31:0] pc_next = PC + 4;

    always @(posedge clk or posedge reset) begin
        if (reset) PC <= 32'h0;
        else PC <= pc_next;
    end
    
    assign if_pc_plus_4 = PC + 4;
    reg [31:0] instr_mem [0:1023];

    // CORREÇÃO: Programa de teste agora embutido diretamente no código.
    initial begin
        // Programa de teste sem hazards para o pipeline
        instr_mem[0] = 32'h00100093; // addi x1, x0, 1
        instr_mem[1] = 32'h00200113; // addi x2, x0, 2
        instr_mem[2] = 32'h00300193; // addi x3, x0, 3
        instr_mem[3] = 32'h00400213; // addi x4, x0, 4
        instr_mem[4] = 32'h00500293; // addi x5, x0, 5
    end
    
    assign if_instruction = instr_mem[PC[11:2]];

    // --- REGISTRADOR DE PIPELINE IF/ID ---
    reg_if_id r_if_id (.*);

    //==================================================
    // ESTÁGIO ID: Instruction Decode & Register Read
    //==================================================
    assign id_opcode = id_instruction[6:0];
    assign id_funct3 = id_instruction[14:12];
    assign id_funct7 = id_instruction[31:25];
    assign id_rd_addr = id_instruction[11:7];
    
    always @(*) begin
        case(id_opcode)
           7'b0010011, 7'b0000011: id_imm_ext = {{20{id_instruction[31]}}, id_instruction[31:20]};
           7'b0100011: id_imm_ext = {{20{id_instruction[31]}}, id_instruction[31:25], id_instruction[11:7]};
           7'b1100011: id_imm_ext = {{19{id_instruction[31]}}, id_instruction[31], id_instruction[7], id_instruction[30:25], id_instruction[11:8], 1'b0};
           7'b1101111: id_imm_ext = {{11{id_instruction[31]}}, id_instruction[31], id_instruction[19:12], id_instruction[20], id_instruction[30:21], 1'b0};
           default: id_imm_ext = 32'h0;
        endcase
    end
    
    reg [31:0] reg_file [0:31];
    assign id_rd1 = (id_instruction[19:15] == 0) ? 0 : reg_file[id_instruction[19:15]];
    assign id_rd2 = (id_instruction[24:20] == 0) ? 0 : reg_file[id_instruction[24:20]];
    always @(posedge clk) begin
        if(wb_RegWrite && wb_rd_addr != 0)
            reg_file[wb_rd_addr] <= wb_write_data;
    end

    // --- REGISTRADOR DE PIPELINE ID/EX ---
    reg_id_ex r_id_ex (.*);
    
    //==================================================
    // ESTÁGIO EX: Execute
    //==================================================
    assign ex_alu_src_b = ex_ALUSrc ? ex_imm_ext : ex_rd2;
    always @(*) begin
        case(ex_ALUControl)
            4'b0010: ex_alu_result = ex_rd1 + ex_alu_src_b;
            4'b0110: ex_alu_result = ex_rd1 - ex_alu_src_b;
            4'b0000: ex_alu_result = ex_rd1 & ex_alu_src_b;
            4'b0001: ex_alu_result = ex_rd1 | ex_alu_src_b;
            4'b0111: ex_alu_result = ($signed(ex_rd1) < $signed(ex_alu_src_b)) ? 32'h1 : 32'h0;
            4'b1000: ex_alu_result = (ex_rd1 < ex_alu_src_b) ? 32'h1 : 32'h0;
            default: ex_alu_result = 32'h0;
        endcase
    end
    
    // --- REGISTRADOR DE PIPELINE EX/MEM ---
    reg_ex_mem r_ex_mem (.*);

    //==================================================
    // ESTÁGIO MEM: Memory Access
    //==================================================
    reg [31:0] data_mem [0:1023];
    always @(posedge clk) begin
        if (mem_MemWrite) data_mem[mem_alu_result[11:2]] <= mem_rd2;
    end
    assign mem_read_data = mem_MemRead ? data_mem[mem_alu_result[11:2]] : 32'h0;

    // --- REGISTRADOR DE PIPELINE MEM/WB ---
    reg_pipeline_mem_wb r_mem_wb(.*);
    
    //==================================================
    // ESTÁGIO WB: Write Back
    //==================================================
    assign wb_write_data = wb_MemtoReg ? wb_read_data : wb_alu_result;
    
endmodule