`timescale 1ns / 1ps

module datapath (
    input  wire        clk,
    input  wire        reset,
    output wire [31:0] o_pc_if,
    output wire [31:0] o_instr_id,
    output wire [31:0] o_instr_ex,
    output wire [31:0] o_instr_mem,
    output wire [31:0] o_instr_wb,
    output wire        o_stall,
    output wire        o_flush,
    output wire [1:0]  o_forwardA,
    output wire [1:0]  o_forwardB,
    output wire        o_wb_MemWrite,
    output wire [31:0] o_wb_mem_addr,
    output wire [31:0] o_wb_mem_wdata
);

    // ===================================================
    // Sinais principais
    // ===================================================
    wire stall;
    wire flush;
    wire RegWrite, MemRead, MemWrite, ALUSrc, ALUASrc, Branch;
    wire [1:0] ResultSrc, ALUOp, Jump;
    reg  [31:0] pc;
    wire [31:0] pc_plus_4, pc_next, instr;
    wire [31:0] reg_data1, reg_data2, imm;
    wire [3:0]  alu_control_out;
    wire [1:0]  forwardA, forwardB;
    wire [31:0] operandA, operandB;
    wire [31:0] alu_input_b, alu_result;
    wire        alu_zero;
    wire [1:0]  pc_sel;
    wire        branch_cond;
    wire [31:0] branch_addr, jump_addr, jalr_addr;
    wire [31:0] mem_read_data;
    wire [31:0] wb_data;

    // ===================================================
    // Registradores de Pipeline IF/ID
    // ===================================================
    reg  [31:0] if_id_pc, if_id_instr, if_id_pc_plus_4;
    wire [6:0]  opcode  = if_id_instr[6:0];
    wire [4:0]  rs1     = if_id_instr[19:15];
    wire [4:0]  rs2     = if_id_instr[24:20];
    wire [4:0]  rd      = if_id_instr[11:7];
    wire [2:0]  funct3  = if_id_instr[14:12];
    wire [6:0]  funct7  = if_id_instr[31:25];

    // ===================================================
    // Registradores de Pipeline ID/EX
    // ===================================================
    reg         id_ex_RegWrite, id_ex_MemRead, id_ex_MemWrite, id_ex_ALUSrc, id_ex_ALUASrc, id_ex_Branch;
    reg  [1:0]  id_ex_ResultSrc, id_ex_ALUOp, id_ex_Jump;
    reg  [31:0] id_ex_pc, id_ex_pc_plus_4, id_ex_reg_data1, id_ex_reg_data2, id_ex_imm, id_ex_instr;
    reg  [4:0]  id_ex_rs1, id_ex_rs2, id_ex_rd;
    reg  [2:0]  id_ex_funct3;
    reg  [6:0]  id_ex_funct7;

    // ===================================================
    // Registradores de Pipeline EX/MEM
    // ===================================================
    reg         ex_mem_RegWrite, ex_mem_MemRead, ex_mem_MemWrite;
    reg  [1:0]  ex_mem_ResultSrc;
    reg  [31:0] ex_mem_pc, ex_mem_pc_plus_4, ex_mem_alu_result, ex_mem_write_data, ex_mem_imm, ex_mem_instr;
    reg  [4:0]  ex_mem_rd;

    // ===================================================
    // Registradores de Pipeline MEM/WB
    // ===================================================
    reg         mem_wb_RegWrite;
    reg  [1:0]  mem_wb_ResultSrc;
    reg  [31:0] mem_wb_pc, mem_wb_pc_plus_4, mem_wb_mem_data, mem_wb_alu_result, mem_wb_imm, mem_wb_instr;
    reg  [4:0]  mem_wb_rd;

    // ===================== Estágio IF/ID =====================
    assign pc_plus_4 = pc + 4;
    assign flush = (pc_sel != 2'b00);

    instruction_memory imem (.addr(pc), .instruction(instr));

    reg reset_done;

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

    assign pc_next = (pc_sel == 2'b01) ? branch_addr :
                     (pc_sel == 2'b10) ? jump_addr   :
                     (pc_sel == 2'b11) ? jalr_addr   :
                     pc_plus_4;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            if_id_pc <= 32'h0;
            if_id_instr <= 32'h00000013; // NOP
            if_id_pc_plus_4 <= 32'h0;
        end else if (~stall) begin
            if (flush) begin
                if_id_pc <= 32'h0;
                if_id_instr <= 32'h00000013;
                if_id_pc_plus_4 <= 32'h0;
            end else begin
                if_id_pc <= pc;
                if_id_instr <= reset_done ? instr : 32'h00000013; // Só pega a instrução real depois do reset_done
                if_id_pc_plus_4 <= pc_plus_4;
            end
        end
    end

    register_file regfile (
        .clk(clk), .RegWrite(mem_wb_RegWrite),
        .rs1(rs1), .rs2(rs2), .rd(mem_wb_rd),
        .write_data(wb_data),
        .read_data1(reg_data1), .read_data2(reg_data2)
    );

    control_unit ctrl (
        .opcode(opcode),
        .RegWrite(RegWrite), .ResultSrc(ResultSrc),
        .MemRead(MemRead), .MemWrite(MemWrite),
        .ALUSrc(ALUSrc), .ALUASrc(ALUASrc),
        .ALUOp(ALUOp), .Branch(Branch), .Jump(Jump)
    );

    imm_gen immediate_generator (
        .instruction(if_id_instr), .opcode(opcode), .imm(imm)
    );

    hazard_unit hazard (
        .id_ex_MemRead(id_ex_MemRead), .id_ex_rd(id_ex_rd),
        .if_id_rs1(rs1), .if_id_rs2(rs2), .stall(stall)
    );

    reg mem_wb_MemWrite;
    reg [31:0] mem_wb_mem_wdata;

    always @(posedge clk or posedge reset) begin
        // CORREÇÃO: O flush agora também zera o estágio ID/EX
        if (reset || stall || flush) begin
            id_ex_RegWrite <= 1'b0; id_ex_ResultSrc <= 2'b0; id_ex_MemRead <= 1'b0;
            id_ex_MemWrite <= 1'b0; id_ex_Branch <= 1'b0; id_ex_Jump <= 2'b0;
            id_ex_ALUSrc <= 1'b0; id_ex_ALUASrc <= 1'b0; id_ex_ALUOp <= 2'b0;
            id_ex_instr <= 32'h00000013; // Injeta NOP explícito
            // Zera os outros regs...
            id_ex_pc <= 0; id_ex_pc_plus_4 <= 0; id_ex_reg_data1 <= 0; id_ex_reg_data2 <= 0;
            id_ex_imm <= 0; id_ex_rs1 <= 0; id_ex_rs2 <= 0; id_ex_rd <= 0;
            id_ex_funct3 <= 0; id_ex_funct7 <= 0;
        end else begin
            // Passa os sinais normalmente
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

    // ===================== Estágio EX =====================
    alu_control alu_ctrl_unit (.ALUOp(id_ex_ALUOp), .funct3(id_ex_funct3), .funct7(id_ex_funct7), .alu_control(alu_control_out));

    forwarding_unit fwd (
        .id_ex_rs1(id_ex_rs1), .id_ex_rs2(id_ex_rs2), .ex_mem_rd(ex_mem_rd), .mem_wb_rd(mem_wb_rd),
        .ex_mem_RegWrite(ex_mem_RegWrite), .mem_wb_RegWrite(mem_wb_RegWrite), .forwardA(forwardA), .forwardB(forwardB)
    );

    // MUXes de Forwarding (agora como 'assign' para garantir timing)
    wire [31:0] alu_a_mux_in = (id_ex_ALUASrc) ? id_ex_pc : id_ex_reg_data1;
    assign operandA = (forwardA == 2'b10) ? ex_mem_alu_result :
                    (forwardA == 2'b01) ? wb_data :
                                            alu_a_mux_in;

    assign operandB = (forwardB == 2'b10) ? ex_mem_alu_result :
                    (forwardB == 2'b01) ? wb_data :
                                            id_ex_reg_data2;

    // ULA principal para a maioria das operações
    assign alu_input_b = (id_ex_ALUSrc) ? id_ex_imm : operandB;
    alu alu_main (.a(operandA), .b(alu_input_b), .alu_control(alu_control_out), .result(alu_result), .zero(alu_zero));


    // --- LÓGICA DE DESVIO E SALTO (CORRIGIDA) ---

    // ULA dedicada para desvios, para garantir que use os operandos corretos
    wire [31:0] branch_alu_result;
    wire        branch_alu_zero;
    alu branch_alu (
        .a(operandA), // Usa o operando A já corrigido pelo forwarding
        .b(operandB), // Usa o operando B já corrigido pelo forwarding
        .alu_control(alu_control_out), // Usa o mesmo controle (SUB, SLT, etc.)
        .result(branch_alu_result), 
        .zero(branch_alu_zero)
    );

    // A condição do branch agora usa o resultado da ULA de desvio
    assign branch_cond = (id_ex_Branch) &
                        ( (id_ex_funct3 == 3'b000 && branch_alu_zero)        || // beq
                        (id_ex_funct3 == 3'b001 && ~branch_alu_zero)       || // bne
                        (id_ex_funct3 == 3'b100 && branch_alu_result == 1) || // blt
                        (id_ex_funct3 == 3'b101 && branch_alu_result == 0) || // bge
                        (id_ex_funct3 == 3'b110 && branch_alu_result == 1) || // bltu
                        (id_ex_funct3 == 3'b111 && branch_alu_result == 0) );  // bgeu

    // O cálculo do endereço do JALR também usa o operando corrigido
    assign branch_addr = id_ex_pc + id_ex_imm;
    assign jump_addr   = id_ex_pc + id_ex_imm;
    assign jalr_addr   = operandA + id_ex_imm;

    assign pc_sel = (id_ex_Jump == 2'b01) ? 2'b10 : // JAL
                    (id_ex_Jump == 2'b10) ? 2'b11 : // JALR
                    (branch_cond)         ? 2'b01 : // Branch
                                            2'b00 ; // PC+4


    // ===================== Estágio MEM =====================
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            {ex_mem_RegWrite, ex_mem_ResultSrc, ex_mem_MemRead, ex_mem_MemWrite} <= 0;
            {ex_mem_pc, ex_mem_pc_plus_4, ex_mem_alu_result, ex_mem_write_data, ex_mem_imm, ex_mem_instr, ex_mem_rd} <= 0;
        end else begin
            {ex_mem_RegWrite, ex_mem_ResultSrc, ex_mem_MemRead, ex_mem_MemWrite} <=
                {id_ex_RegWrite, id_ex_ResultSrc, id_ex_MemRead, id_ex_MemWrite};
            {ex_mem_pc, ex_mem_pc_plus_4, ex_mem_alu_result, ex_mem_write_data, ex_mem_imm, ex_mem_instr, ex_mem_rd} <=
                {id_ex_pc, id_ex_pc_plus_4, alu_result, operandB, id_ex_imm, id_ex_instr, id_ex_rd};
        end
    end

    data_memory dmem (
        .clk(clk), .MemRead(ex_mem_MemRead), .MemWrite(ex_mem_MemWrite),
        .addr(ex_mem_alu_result), .write_data(ex_mem_write_data),
        .read_data(mem_read_data)
    );

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            {mem_wb_RegWrite, mem_wb_ResultSrc} <= 0;
            {mem_wb_pc, mem_wb_pc_plus_4, mem_wb_mem_data, mem_wb_alu_result, mem_wb_imm, mem_wb_instr, mem_wb_rd} <= 0;
        end else begin
            {mem_wb_RegWrite, mem_wb_ResultSrc} <= {ex_mem_RegWrite, ex_mem_ResultSrc};
            {mem_wb_pc, mem_wb_pc_plus_4, mem_wb_mem_data, mem_wb_alu_result, mem_wb_imm, mem_wb_instr, mem_wb_rd} <=
                {ex_mem_pc, ex_mem_pc_plus_4, mem_read_data, ex_mem_alu_result, ex_mem_imm, ex_mem_instr, ex_mem_rd};
        end
    end

    // ===================== Estágio WB =====================
    assign wb_data = (mem_wb_ResultSrc == 2'b01) ? mem_wb_mem_data :
                     (mem_wb_ResultSrc == 2'b10) ? mem_wb_imm      :
                     (mem_wb_ResultSrc == 2'b11) ? mem_wb_pc_plus_4 : mem_wb_alu_result;

    assign o_pc_if      = pc;
    assign o_instr_id   = if_id_instr;
    assign o_instr_ex   = id_ex_instr;
    assign o_instr_mem  = ex_mem_instr;
    assign o_instr_wb   = mem_wb_instr;
    assign o_stall      = stall;
    assign o_flush      = flush;
    assign o_forwardA   = forwardA;
    assign o_forwardB   = forwardB;
    assign o_wb_MemWrite = mem_wb_MemWrite;
    assign o_wb_mem_addr = mem_wb_alu_result;
    assign o_wb_mem_wdata = mem_wb_mem_wdata;

endmodule
