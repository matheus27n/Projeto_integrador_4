/**
 * @file datapath.v
 * @brief Módulo final e corrigido do datapath para um processador RISC-V de 5 estágios.
 * @details Esta versão implementa a lógica correta de reset e stall, garantindo que
 * o reset tenha prioridade máxima sobre as condições de "freeze" da cache,
 * prevenindo a corrupção do estado do pipeline durante a inicialização.
 */
`timescale 1ns / 1ps

module datapath (
    // --- Entradas ---
    input  wire         clk,
    input  wire         reset,

    // --- Saídas de Depuração ---
    output wire [31:0]  o_pc_if,
    output wire [31:0]  o_instr_id,
    output wire [31:0]  o_instr_ex,
    output wire [31:0]  o_instr_mem,
    output wire [31:0]  o_instr_wb,
    output wire         o_stall,
    output wire         o_hazard_stall,
    output wire         o_cache_stall,
    output wire         o_cache_hit,
    output wire         o_flush,
    output wire [1:0]   o_forwardA,
    output wire [1:0]   o_forwardB,
    output wire         o_wb_MemWrite,
    output wire [31:0]  o_wb_mem_addr,
    output wire [31:0]  o_wb_mem_wdata
);

    // =================================================================================
    // 🧠 Declaração Centralizada de Sinais Internos
    // =================================================================================

    // --- Sinais Gerais e de Controle ---
    wire        stall;
    wire        flush;
    wire        RegWrite, MemRead, MemWrite, ALUSrc, ALUASrc, Branch;
    wire [1:0]  ResultSrc, ALUOp, Jump;
    reg  [31:0] pc;
    wire [31:0] pc_plus_4;
    wire [31:0] pc_next;
    wire [31:0] instr;
    wire [31:0] reg_data1, reg_data2;
    wire [31:0] imm;
    wire [3:0]  alu_control_out;
    wire [1:0]  forwardA, forwardB;
    wire [31:0] operandA, operandB;
    wire [31:0] alu_input_b;
    wire [31:0] alu_result;
    wire        alu_zero;
    wire [1:0]  pc_sel;
    wire        branch_cond;
    wire [31:0] branch_addr;
    wire [31:0] jump_addr;
    wire [31:0] jalr_addr;
    wire [31:0] mem_read_data;
    wire [31:0] wb_data;
    reg         reset_done;
    wire [31:0] branch_alu_result;
    wire        branch_alu_zero;
    wire [31:0] alu_a_mux_in;

    // --- Lógica de Stall Corrigida ---
    wire        hazard_bubble; // Stall que deve inserir uma bolha (load-use)
    wire        cache_freeze;  // Stall que deve congelar o pipeline (cache miss)
    assign      stall = hazard_bubble | cache_freeze;

    // --- Sinais de Conexão Cache <-> Memória Principal ---
    wire        cache_hit;
    wire [31:0] cache_mem_addr;
    wire [31:0] cache_mem_wdata;
    wire        cache_mem_read;
    wire        cache_mem_write;
    wire [31:0] mem_cache_rdata;
    wire        mem_busy = 1'b0;

    // --- Sinais do Pipeline IF/ID ---
    reg  [31:0] if_id_pc;
    reg  [31:0] if_id_instr;
    reg  [31:0] if_id_pc_plus_4;
    wire [6:0]  opcode = if_id_instr[6:0];
    wire [4:0]  rs1    = if_id_instr[19:15];
    wire [4:0]  rs2    = if_id_instr[24:20];
    wire [4:0]  rd     = if_id_instr[11:7];
    wire [2:0]  funct3 = if_id_instr[14:12];
    wire [6:0]  funct7 = if_id_instr[31:25];

    // --- Sinais do Pipeline ID/EX ---
    reg         id_ex_RegWrite, id_ex_MemRead, id_ex_MemWrite, id_ex_ALUSrc, id_ex_ALUASrc, id_ex_Branch;
    reg  [1:0]  id_ex_ResultSrc, id_ex_ALUOp, id_ex_Jump;
    reg  [31:0] id_ex_pc, id_ex_pc_plus_4, id_ex_reg_data1, id_ex_reg_data2, id_ex_imm, id_ex_instr;
    reg  [4:0]  id_ex_rs1, id_ex_rs2, id_ex_rd;
    reg  [2:0]  id_ex_funct3;
    reg  [6:0]  id_ex_funct7;

    // --- Sinais do Pipeline EX/MEM ---
    reg         ex_mem_RegWrite, ex_mem_MemRead, ex_mem_MemWrite;
    reg  [1:0]  ex_mem_ResultSrc;
    reg  [31:0] ex_mem_pc, ex_mem_pc_plus_4, ex_mem_alu_result, ex_mem_write_data, ex_mem_imm, ex_mem_instr;
    reg  [4:0]  ex_mem_rd;

    // --- Sinais do Pipeline MEM/WB ---
    reg         mem_wb_RegWrite;
    reg  [1:0]  mem_wb_ResultSrc;
    reg  [31:0] mem_wb_pc, mem_wb_pc_plus_4, mem_wb_mem_data, mem_wb_alu_result, mem_wb_imm, mem_wb_instr;
    reg  [4:0]  mem_wb_rd;
    reg         mem_wb_MemWrite;
    reg  [31:0] mem_wb_mem_wdata;

    // =================================================================================
    // ➡️ Estágio 1: IF (Busca da Instrução)
    // =================================================================================

    assign pc_plus_4 = pc + 4;
    assign flush = (pc_sel != 2'b00);

    instruction_memory imem (.addr(pc), .instruction(instr));

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc <= 32'h0;
            reset_done <= 1'b0;
        end else if (!reset_done) begin
            reset_done <= 1'b1;
            pc <= 32'h0;
        end else if (~stall) begin
            pc <= pc_next;
        end
    end

    assign pc_next = (pc_sel == 2'b01) ? branch_addr : (pc_sel == 2'b10) ? jump_addr : (pc_sel == 2'b11) ? jalr_addr : pc_plus_4;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            if_id_pc <= 32'h0;
            if_id_instr <= 32'h00000013;
            if_id_pc_plus_4 <= 32'h0;
        end else if (~stall) begin
            if (flush) begin
                if_id_pc <= 32'h0;
                if_id_instr <= 32'h00000013;
                if_id_pc_plus_4 <= 32'h0;
            end else begin
                if_id_pc <= pc;
                if_id_instr <= reset_done ? instr : 32'h00000013;
                if_id_pc_plus_4 <= pc_plus_4;
            end
        end
    end

    // =================================================================================
    // ➡️ Estágio 2: ID (Decodificação e Leitura de Registradores)
    // =================================================================================

    register_file regfile (.clk(clk), .RegWrite(mem_wb_RegWrite), .rs1(rs1), .rs2(rs2), .rd(mem_wb_rd), .write_data(wb_data), .read_data1(reg_data1), .read_data2(reg_data2));
    control_unit ctrl (.opcode(opcode), .RegWrite(RegWrite), .ResultSrc(ResultSrc), .MemRead(MemRead), .MemWrite(MemWrite), .ALUSrc(ALUSrc), .ALUASrc(ALUASrc), .ALUOp(ALUOp), .Branch(Branch), .Jump(Jump));
    imm_gen immediate_generator (.instruction(if_id_instr), .opcode(opcode), .imm(imm));
    hazard_unit hazard (.id_ex_MemRead(id_ex_MemRead), .id_ex_rd(id_ex_rd), .if_id_rs1(rs1), .if_id_rs2(rs2), .stall(hazard_bubble));

    // --- LÓGICA DO REGISTRADOR ID/EX CORRIGIDA ---
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            id_ex_RegWrite <= 1'b0; id_ex_ResultSrc <= 2'b0; id_ex_MemRead <= 1'b0;
            id_ex_MemWrite <= 1'b0; id_ex_Branch <= 1'b0; id_ex_Jump <= 2'b0;
            id_ex_ALUSrc <= 1'b0; id_ex_ALUASrc <= 1'b0; id_ex_ALUOp <= 2'b0;
            id_ex_pc <= 32'b0; id_ex_pc_plus_4 <= 32'b0; id_ex_reg_data1 <= 32'b0;
            id_ex_reg_data2 <= 32'b0; id_ex_imm <= 32'b0; id_ex_instr <= 32'h00000013;
            id_ex_rs1 <= 5'b0; id_ex_rs2 <= 5'b0; id_ex_rd <= 5'b0;
            id_ex_funct3 <= 3'b0; id_ex_funct7 <= 7'b0;
        end else if (~cache_freeze) begin
            if (hazard_bubble || flush) begin
                id_ex_RegWrite <= 1'b0; id_ex_ResultSrc <= 2'b0; id_ex_MemRead <= 1'b0;
                id_ex_MemWrite <= 1'b0; id_ex_Branch <= 1'b0; id_ex_Jump <= 2'b0;
                id_ex_ALUSrc <= 1'b0; id_ex_ALUASrc <= 1'b0; id_ex_ALUOp <= 2'b0;
                id_ex_pc <= 32'b0; id_ex_pc_plus_4 <= 32'b0; id_ex_reg_data1 <= 32'b0;
                id_ex_reg_data2 <= 32'b0; id_ex_imm <= 32'b0; id_ex_instr <= 32'h00000013;
                id_ex_rs1 <= 5'b0; id_ex_rs2 <= 5'b0; id_ex_rd <= 5'b0;
                id_ex_funct3 <= 3'b0; id_ex_funct7 <= 7'b0;
            end else begin
                id_ex_RegWrite <= RegWrite; id_ex_ResultSrc <= ResultSrc; id_ex_MemRead <= MemRead;
                id_ex_MemWrite <= MemWrite; id_ex_Branch <= Branch; id_ex_Jump <= Jump;
                id_ex_ALUSrc <= ALUSrc; id_ex_ALUASrc <= ALUASrc; id_ex_ALUOp <= ALUOp;
                id_ex_pc <= if_id_pc; id_ex_pc_plus_4 <= if_id_pc_plus_4;
                id_ex_reg_data1 <= reg_data1; id_ex_reg_data2 <= reg_data2;
                id_ex_imm <= imm; id_ex_instr <= if_id_instr;
                id_ex_rs1 <= rs1; id_ex_rs2 <= rs2; id_ex_rd <= rd;
                id_ex_funct3 <= funct3; id_ex_funct7 <= funct7;
            end
        end
    end

    // =================================================================================
    // ➡️ Estágio 3: EX (Execução)
    // =================================================================================
    
    alu_control alu_ctrl_unit (.ALUOp(id_ex_ALUOp), .funct3(id_ex_funct3), .funct7(id_ex_funct7), .alu_control(alu_control_out));
    forwarding_unit fwd (.id_ex_rs1(id_ex_rs1), .id_ex_rs2(id_ex_rs2), .ex_mem_rd(ex_mem_rd), .mem_wb_rd(mem_wb_rd), .ex_mem_RegWrite(ex_mem_RegWrite), .mem_wb_RegWrite(mem_wb_RegWrite), .forwardA(forwardA), .forwardB(forwardB));
    wire [31:0] wb_forward_data;
    assign wb_forward_data = (mem_wb_ResultSrc == 2'b01) ? mem_wb_mem_data : (mem_wb_ResultSrc == 2'b10) ? mem_wb_imm : (mem_wb_ResultSrc == 2'b11) ? mem_wb_pc_plus_4 : mem_wb_alu_result;
    assign alu_a_mux_in = (id_ex_ALUASrc) ? id_ex_pc : id_ex_reg_data1;
    assign operandA = (forwardA == 2'b10) ? ex_mem_alu_result : (forwardA == 2'b01) ? wb_forward_data : alu_a_mux_in;
    assign operandB = (forwardB == 2'b10) ? ex_mem_alu_result : (forwardB == 2'b01) ? wb_forward_data : id_ex_reg_data2;
    assign alu_input_b = (id_ex_ALUSrc) ? id_ex_imm : operandB;
    alu alu_main (.a(operandA), .b(alu_input_b), .alu_control(alu_control_out), .result(alu_result), .zero(alu_zero));
    alu branch_alu (.a(operandA), .b(operandB), .alu_control(alu_control_out), .result(branch_alu_result), .zero(branch_alu_zero));
    assign branch_cond = (id_ex_Branch) & ((id_ex_funct3 == 3'b000 && branch_alu_zero) || (id_ex_funct3 == 3'b001 && ~branch_alu_zero) || (id_ex_funct3 == 3'b100 && branch_alu_result == 1) || (id_ex_funct3 == 3'b101 && branch_alu_result == 0) || (id_ex_funct3 == 3'b110 && branch_alu_result == 1) || (id_ex_funct3 == 3'b111 && branch_alu_result == 0));
    assign branch_addr = id_ex_pc + id_ex_imm;
    assign jump_addr = id_ex_pc + id_ex_imm;
    assign jalr_addr = operandA + id_ex_imm;
    assign pc_sel = (id_ex_Jump == 2'b01) ? 2'b10 : (id_ex_Jump == 2'b10) ? 2'b11 : (branch_cond) ? 2'b01 : 2'b00;

    // =================================================================================
    // ➡️ Estágio 4: MEM (Acesso à Memória via Cache)
    // =================================================================================

    // --- LÓGICA DO REGISTRADOR EX/MEM CORRIGIDA ---
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            ex_mem_RegWrite <= 0; ex_mem_ResultSrc <= 0; ex_mem_MemRead <= 0;
            ex_mem_MemWrite <= 0; ex_mem_pc <= 0; ex_mem_pc_plus_4 <= 0;
            ex_mem_alu_result <= 0; ex_mem_write_data <= 0; ex_mem_imm <= 0;
            ex_mem_instr <= 32'h00000013; ex_mem_rd <= 0;
        end else if (~cache_freeze) begin
            ex_mem_RegWrite <= id_ex_RegWrite; ex_mem_ResultSrc <= id_ex_ResultSrc;
            ex_mem_MemRead <= id_ex_MemRead; ex_mem_MemWrite <= id_ex_MemWrite;
            ex_mem_pc <= id_ex_pc; ex_mem_pc_plus_4 <= id_ex_pc_plus_4;
            ex_mem_alu_result <= alu_result; ex_mem_write_data <= operandB;
            ex_mem_imm <= id_ex_imm; ex_mem_instr <= id_ex_instr; ex_mem_rd <= id_ex_rd;
        end
    end

    direct_mapped_cache dcache (.clk(clk), .reset(reset), .cpu_addr(ex_mem_alu_result), .cpu_write_data(ex_mem_write_data), .cpu_read(ex_mem_MemRead), .cpu_write(ex_mem_MemWrite), .cpu_read_data(mem_read_data), .cpu_stall(cache_freeze), .hit(cache_hit), .mem_read_data(mem_cache_rdata), .mem_busy(mem_busy), .mem_addr(cache_mem_addr), .mem_write_data(cache_mem_wdata), .mem_read(cache_mem_read), .mem_write(cache_mem_write));
    data_memory main_memory (.clk(clk), .MemRead(cache_mem_read), .MemWrite(cache_mem_write), .addr(cache_mem_addr), .write_data(cache_mem_wdata), .read_data(mem_cache_rdata));

    // --- LÓGICA DO REGISTRADOR MEM/WB CORRIGIDA ---
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            mem_wb_RegWrite <= 0; mem_wb_ResultSrc <= 0; mem_wb_pc <= 0;
            mem_wb_pc_plus_4 <= 0; mem_wb_mem_data <= 0; mem_wb_alu_result <= 0;
            mem_wb_imm <= 0; mem_wb_instr <= 32'h00000013; mem_wb_rd <= 0;
            mem_wb_MemWrite <= 0; mem_wb_mem_wdata <= 0;
        end else if (~cache_freeze) begin
            mem_wb_RegWrite <= ex_mem_RegWrite; mem_wb_ResultSrc <= ex_mem_ResultSrc;
            mem_wb_pc <= ex_mem_pc; mem_wb_pc_plus_4 <= ex_mem_pc_plus_4;
            mem_wb_mem_data <= mem_read_data; mem_wb_alu_result <= ex_mem_alu_result;
            mem_wb_imm <= ex_mem_imm; mem_wb_instr <= ex_mem_instr;
            mem_wb_rd <= ex_mem_rd; mem_wb_MemWrite <= ex_mem_MemWrite;
            mem_wb_mem_wdata <= ex_mem_write_data;
        end
    end

    // =================================================================================
    // ➡️ Estágio 5: WB (Escrita de Volta)
    // =================================================================================

    assign wb_data = (mem_wb_ResultSrc == 2'b01) ? mem_wb_mem_data : (mem_wb_ResultSrc == 2'b10) ? mem_wb_imm : (mem_wb_ResultSrc == 2'b11) ? mem_wb_pc_plus_4 : mem_wb_alu_result;

    // =================================================================================
    // 🛰️ Atribuição das Saídas do Módulo
    // =================================================================================
    assign o_pc_if        = pc;
    assign o_instr_id     = if_id_instr;
    assign o_instr_ex     = id_ex_instr;
    assign o_instr_mem    = ex_mem_instr;
    assign o_instr_wb     = mem_wb_instr;
    assign o_stall        = stall;
    assign o_hazard_stall = hazard_bubble;
    assign o_cache_stall  = cache_freeze;
    assign o_cache_hit    = cache_hit;
    assign o_flush        = flush;
    assign o_forwardA     = forwardA;
    assign o_forwardB     = forwardB;
    assign o_wb_MemWrite  = mem_wb_MemWrite;
    assign o_wb_mem_addr  = mem_wb_alu_result;
    assign o_wb_mem_wdata = mem_wb_mem_wdata;

endmodule