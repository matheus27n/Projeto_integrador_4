`timescale 1ns / 1ps

// Módulo da Parte Operativa para o processador Pipeline
// Contém todos os estágios do datapath e os registradores de pipeline.
module parte_operativa_pipeline(
    input clk, input reset,
    
    // --- Entradas: Sinais de controle vindos da Unidade de Controle (gerados no estágio ID) ---
    input id_ALUSrc, input id_MemtoReg, input id_RegWrite,
    input id_MemRead, input id_MemWrite, input id_Branch, input id_Jump,
    input [3:0] id_ALUControl,
    
    // --- Saídas: Campos da instrução para a Unidade de Controle (lidos no estágio ID) ---
    output wire [6:0] id_opcode,
    output wire [2:0] id_funct3,
    output wire [6:0] id_funct7,

    // --- Saídas: Sinais para o Testbench (lidos no estágio WB para depuração) ---
    output wire [31:0] wb_pc,
    output wire [31:0] wb_instruction,
    output wire [31:0] wb_write_data,
    output wire [4:0]  wb_rd_addr,
    output wire        wb_RegWrite
);

    //==================================================================
    // --- FIOS DE CONEXÃO DO PIPELINE ---
    //==================================================================

    // Sinais entre IF e ID
    wire [31:0] if_pc, if_pc_plus_4, if_instruction;
    wire [31:0] id_pc, id_instruction;
    
    // Sinais gerados no estágio ID
    wire [31:0] id_rd1, id_rd2;
    reg  [31:0] id_imm_ext;
    wire [4:0]  id_rd_addr;
    
    // Sinais entre ID e EX
    wire [31:0] ex_pc, ex_instruction, ex_rd1, ex_rd2, ex_imm_ext;
    wire [4:0]  ex_rd_addr;
    wire        ex_MemtoReg, ex_RegWrite, ex_MemRead, ex_MemWrite, ex_ALUSrc;
    wire [3:0]  ex_ALUControl;
    
    // Sinais gerados no estágio EX
    reg  [31:0] ex_alu_result;
    wire [31:0] ex_alu_src_b;
    
    // Sinais entre EX e MEM
    wire [31:0] mem_pc, mem_instruction, mem_alu_result, mem_rd2;
    wire [4:0]  mem_rd_addr;
    wire        mem_MemtoReg, mem_RegWrite, mem_MemRead, mem_MemWrite;
    
    // Sinais gerados no estágio MEM
    wire [31:0] mem_read_data;

    // Sinais entre MEM e WB
    // Nota: Os fios wb_* são declarados como portas de saída do módulo acima
    wire wb_MemtoReg;
    wire [31:0] wb_read_data, wb_alu_result;

    //==================================================
    // ESTÁGIO IF: Instruction Fetch
    //==================================================
    reg [31:0] PC;
    // Lógica do próximo PC (ainda sem desvios nesta fase inicial)
    wire [31:0] pc_next = PC + 4;

    always @(posedge clk or posedge reset) begin
        if (reset) PC <= 32'h0;
        else PC <= pc_next;
    end
    
    assign if_pc = PC;
    
    // Memória de Instruções com programa de teste embutido
    reg [31:0] instr_mem [0:1023];
    initial begin
        // Programa de teste simples e SEM DEPENDÊNCIAS (hazards)
        instr_mem[0] = 32'h00100093; // 0x00: addi x1, x0, 1
        instr_mem[1] = 32'h00200113; // 0x04: addi x2, x0, 2
        instr_mem[2] = 32'h00300193; // 0x08: addi x3, x0, 3
        instr_mem[3] = 32'h00400213; // 0x0C: addi x4, x0, 4
        instr_mem[4] = 32'h00500293; // 0x10: addi x5, x0, 5
        // Preenche o resto com NOPs
        for (integer i = 5; i < 1024; i = i + 1) begin
            instr_mem[i] = 32'h00000013; // addi x0, x0, 0
        end
    end
    assign if_instruction = instr_mem[PC[11:2]];

    // --- REGISTRADOR DE PIPELINE IF/ID ---
    reg_if_id r_if_id (
        .clk(clk), .reset(reset),
        .if_pc(if_pc), .if_instruction(if_instruction),
        .id_pc(id_pc), .id_instruction(id_instruction)
    );

    //==================================================
    // ESTÁGIO ID: Instruction Decode & Register Read
    //==================================================
    // As saídas id_opcode, id_funct3, id_funct7 são conectadas diretamente ao Controle
    assign id_opcode = id_instruction[6:0];
    assign id_funct3 = id_instruction[14:12];
    assign id_funct7 = id_instruction[31:25];
    assign id_rd_addr = id_instruction[11:7];
    
    // Lógica do Extensor de Imediato
    always @(*) begin
        case(id_opcode)
           7'b0010011, 7'b0000011: id_imm_ext = {{20{id_instruction[31]}}, id_instruction[31:20]};
           7'b0100011: id_imm_ext = {{20{id_instruction[31]}}, id_instruction[31:25], id_instruction[11:7]};
           7'b1100011: id_imm_ext = {{19{id_instruction[31]}}, id_instruction[31], id_instruction[7], id_instruction[30:25], id_instruction[11:8], 1'b0};
           7'b1101111: id_imm_ext = {{11{id_instruction[31]}}, id_instruction[31], id_instruction[19:12], id_instruction[20], id_instruction[30:21], 1'b0};
           default: id_imm_ext = 32'h0;
        endcase
    end
    
    // Banco de Registradores: A leitura acontece aqui no estágio ID.
    reg [31:0] reg_file [0:31];
    assign id_rd1 = (id_instruction[19:15] == 0) ? 0 : reg_file[id_instruction[19:15]];
    assign id_rd2 = (id_instruction[24:20] == 0) ? 0 : reg_file[id_instruction[24:20]];
    
    // A escrita no banco de registradores é controlada pelo estágio WB.
    always @(posedge clk) begin
        if(wb_RegWrite && wb_rd_addr != 0)
            reg_file[wb_rd_addr] <= wb_write_data;
    end

    // --- REGISTRADOR DE PIPELINE ID/EX ---
    reg_id_ex r_id_ex (
        .clk(clk), .reset(reset),
        .id_pc(id_pc), .id_instruction(id_instruction),
        .id_MemtoReg(id_MemtoReg), .id_RegWrite(id_RegWrite), .id_MemRead(id_MemRead),
        .id_MemWrite(id_MemWrite), .id_ALUControl(id_ALUControl), .id_ALUSrc(id_ALUSrc),
        .id_rd1(id_rd1), .id_rd2(id_rd2), .id_imm_ext(id_imm_ext), .id_rd_addr(id_rd_addr),
        .ex_pc(ex_pc), .ex_instruction(ex_instruction), .ex_MemtoReg(ex_MemtoReg),
        .ex_RegWrite(ex_RegWrite), .ex_MemRead(ex_MemRead), .ex_MemWrite(ex_MemWrite),
        .ex_ALUControl(ex_ALUControl), .ex_ALUSrc(ex_ALUSrc), .ex_rd1(ex_rd1),
        .ex_rd2(ex_rd2), .ex_imm_ext(ex_imm_ext), .ex_rd_addr(ex_rd_addr)
    );
    
    //==================================================
    // ESTÁGIO EX: Execute
    //==================================================
    // MUX para selecionar a segunda entrada da ULA
    assign ex_alu_src_b = ex_ALUSrc ? ex_imm_ext : ex_rd2;
    
    // Lógica da ULA
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
    reg_ex_mem r_ex_mem (
        .clk(clk), .reset(reset),
        .ex_pc(ex_pc), .ex_instruction(ex_instruction), .ex_MemtoReg(ex_MemtoReg),
        .ex_RegWrite(ex_RegWrite), .ex_MemRead(ex_MemRead), .ex_MemWrite(ex_MemWrite),
        .ex_alu_result(ex_alu_result), .ex_rd2(ex_rd2), .ex_rd_addr(ex_rd_addr),
        .mem_pc(mem_pc), .mem_instruction(mem_instruction), .mem_MemtoReg(mem_MemtoReg),
        .mem_RegWrite(mem_RegWrite), .mem_MemRead(mem_MemRead), .mem_MemWrite(mem_MemWrite),
        .mem_alu_result(mem_alu_result), .mem_rd2(mem_rd2), .mem_rd_addr(mem_rd_addr)
    );

    //==================================================
    // ESTÁGIO MEM: Memory Access
    //==================================================
    reg [31:0] data_mem [0:1023];
    always @(posedge clk) begin
        if (mem_MemWrite) data_mem[mem_alu_result[11:2]] <= mem_rd2;
    end
    assign mem_read_data = mem_MemRead ? data_mem[mem_alu_result[11:2]] : 32'h0;

    // --- REGISTRADOR DE PIPELINE MEM/WB ---
    reg_mem_wb r_mem_wb (
        .clk(clk), .reset(reset),
        .mem_pc(mem_pc), .mem_instruction(mem_instruction), .mem_MemtoReg(mem_MemtoReg),
        .mem_RegWrite(mem_RegWrite), .mem_read_data(mem_read_data),
        .mem_alu_result(mem_alu_result), .mem_rd_addr(mem_rd_addr),
        .wb_pc(wb_pc), .wb_instruction(wb_instruction), .wb_MemtoReg(wb_MemtoReg),
        .wb_RegWrite(wb_RegWrite), .wb_read_data(wb_read_data),
        .wb_alu_result(wb_alu_result), .wb_rd_addr(wb_rd_addr)
    );
    
    //==================================================
    // ESTÁGIO WB: Write Back
    //==================================================
    // MUX final para selecionar o que será escrito de volta no banco de registradores
    assign wb_write_data = wb_MemtoReg ? wb_read_data : wb_alu_result;
    
endmodule