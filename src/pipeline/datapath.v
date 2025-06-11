`timescale 1ns / 1ps

module datapath (
    input  wire        clk,
    input  wire        reset,
    output wire [31:0] pc_out,
    output wire        o_stall,
    output wire        o_flush
);

//================================================================//
//                      SINAIS E REGISTRADORES                    //
//================================================================//

// --- Sinais de Controle do Pipeline ---
wire       pc_write;
wire       if_id_write;
wire       nop_bubble;

// --- Sinais de Controle da Unidade Principal (com ALUASrc) ---
wire       RegWrite, MemRead, MemWrite, ALUSrc, ALUASrc, Branch;
wire [1:0] ResultSrc, ALUOp, Jump;

// --- Sinais do Estágio IF ---
reg  [31:0] pc;
wire [31:0] pc_plus_4;
wire [31:0] pc_next;
wire [31:0] instr;

// --- Registrador IF/ID ---
reg  [31:0] if_id_pc;
reg  [31:0] if_id_instr;
reg  [31:0] if_id_pc_plus_4;

// --- Sinais do Estágio ID ---
wire [6:0]  opcode = if_id_instr[6:0];
wire [4:0]  rs1    = if_id_instr[19:15];
wire [4:0]  rs2    = if_id_instr[24:20];
wire [4:0]  rd     = if_id_instr[11:7];
wire [2:0]  funct3 = if_id_instr[14:12];
wire [6:0]  funct7 = if_id_instr[31:25];
wire [31:0] reg_data1, reg_data2;
wire [31:0] imm;

// --- Sinais da Unidade de Risco ---
wire       stall; 
wire       flush;

// --- Registrador ID/EX (com ALUASrc) ---
reg        id_ex_RegWrite, id_ex_MemRead, id_ex_MemWrite, id_ex_ALUSrc, id_ex_ALUASrc, id_ex_Branch;
reg [1:0]  id_ex_ResultSrc, id_ex_ALUOp, id_ex_Jump;
reg [31:0] id_ex_pc, id_ex_pc_plus_4, id_ex_reg_data1, id_ex_reg_data2, id_ex_imm;
reg [4:0]  id_ex_rs1, id_ex_rs2, id_ex_rd;
reg [2:0]  id_ex_funct3;
reg [6:0]  id_ex_funct7;

// --- Sinais do Estágio EX ---
wire [3:0]  alu_control_out;
wire [1:0]  forwardA, forwardB;
reg  [31:0] operandA, operandB;
wire [31:0] alu_input_b;
wire [31:0] alu_result;
wire        alu_zero;
wire [1:0]  pc_sel;
wire        branch_cond;
wire [31:0] branch_addr, jump_addr, jalr_addr;

// --- Registrador EX/MEM ---
reg        ex_mem_RegWrite;
reg [1:0]  ex_mem_ResultSrc;
reg [31:0] ex_mem_pc_plus_4, ex_mem_alu_result, ex_mem_write_data, ex_mem_imm;
reg [4:0]  ex_mem_rd;
reg        ex_mem_MemRead, ex_mem_MemWrite; // CORREÇÃO: Devem ser regs para passar pelo pipeline

// --- Sinais do Estágio MEM ---
wire [31:0] mem_read_data;

// --- Registrador MEM/WB ---
reg        mem_wb_RegWrite;
reg [1:0]  mem_wb_ResultSrc;
reg [31:0] mem_wb_pc_plus_4, mem_wb_mem_data, mem_wb_alu_result, mem_wb_imm;
reg [4:0]  mem_wb_rd;

// --- Sinais do Estágio WB ---
wire [31:0] wb_data;


//================================================================//
//                      ESTÁGIO IF (Instruction Fetch)            //
//================================================================//
assign pc_out = pc;
assign pc_plus_4 = pc + 4;
assign flush = (pc_sel != 2'b00);

instruction_memory imem (.addr(pc), .instruction(instr));

always @(posedge clk or posedge reset) begin
    if (reset)         pc <= 32'h00000000;
    else if (pc_write) pc <= pc_next;
end

assign pc_next = (pc_sel == 2'b01) ? branch_addr :
                 (pc_sel == 2'b10) ? jump_addr   :
                 (pc_sel == 2'b11) ? jalr_addr   :
                                     pc_plus_4;

assign pc_write = ~stall;
assign if_id_write = ~stall;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        if_id_pc <= 0; if_id_instr <= 0; if_id_pc_plus_4 <= 0;
    end else if (flush) begin
        if_id_pc <= 0; if_id_instr <= 32'h00000013; if_id_pc_plus_4 <= 0; // NOP
    end else if (if_id_write) begin
        if_id_pc <= pc; if_id_instr <= instr; if_id_pc_plus_4 <= pc_plus_4;
    end
end


//================================================================//
//                      ESTÁGIO ID (Instruction Decode)           //
//================================================================//
register_file regfile (
    .clk(clk), .RegWrite(mem_wb_RegWrite), .rs1(rs1), .rs2(rs2), 
    .rd(mem_wb_rd), .write_data(wb_data), .read_data1(reg_data1), .read_data2(reg_data2)
);

control_unit ctrl (
    .opcode(opcode), .RegWrite(RegWrite), .ResultSrc(ResultSrc), .MemRead(MemRead), .MemWrite(MemWrite),
    .ALUSrc(ALUSrc), .ALUASrc(ALUASrc), .ALUOp(ALUOp), .Branch(Branch), .Jump(Jump)
);

imm_gen immediate_generator (.instruction(if_id_instr), .opcode(opcode), .imm(imm));

// CORREÇÃO NA CONEXÃO DO HAZARD UNIT
hazard_unit hazard (
    .id_ex_MemRead(id_ex_MemRead), // DEVE usar o MemRead do estágio ID/EX
    .id_ex_rd(id_ex_rd), 
    .if_id_rs1(rs1), 
    .if_id_rs2(rs2), 
    .stall(stall)
);

assign nop_bubble = stall;

always @(posedge clk or posedge reset) begin
    if (reset || nop_bubble) begin
        id_ex_RegWrite <= 0; id_ex_MemRead <= 0; id_ex_MemWrite <= 0; id_ex_ResultSrc <= 0;
        id_ex_ALUSrc <= 0; id_ex_ALUASrc <= 0; id_ex_ALUOp <= 0; id_ex_Branch <= 0; id_ex_Jump <= 0;
        id_ex_pc <= 0; id_ex_pc_plus_4 <= 0; id_ex_reg_data1 <= 0; id_ex_reg_data2 <= 0;
        id_ex_imm <= 0; id_ex_rs1 <= 0; id_ex_rs2 <= 0; id_ex_rd <= 0;
        id_ex_funct3 <= 0; id_ex_funct7 <= 0;
    end else begin
        id_ex_RegWrite <= RegWrite; id_ex_MemRead <= MemRead; id_ex_MemWrite <= MemWrite; id_ex_ResultSrc <= ResultSrc;
        id_ex_ALUSrc <= ALUSrc; id_ex_ALUASrc <= ALUASrc; id_ex_ALUOp <= ALUOp; id_ex_Branch <= Branch; id_ex_Jump <= Jump;
        id_ex_pc <= if_id_pc; id_ex_pc_plus_4 <= if_id_pc_plus_4;
        id_ex_reg_data1 <= reg_data1; id_ex_reg_data2 <= reg_data2;
        id_ex_imm <= imm; id_ex_rs1 <= rs1; id_ex_rs2 <= rs2; id_ex_rd <= rd;
        id_ex_funct3 <= funct3; id_ex_funct7 <= funct7;
    end
end


//================================================================//
//                      ESTÁGIO EX (Execute)                      //
//================================================================//
alu_control alu_ctrl_unit (.ALUOp(id_ex_ALUOp), .funct3(id_ex_funct3), .funct7(id_ex_funct7), .alu_control(alu_control_out));

forwarding_unit fwd (
    .id_ex_rs1(id_ex_rs1), .id_ex_rs2(id_ex_rs2), .ex_mem_rd(ex_mem_rd), .mem_wb_rd(mem_wb_rd),
    .ex_mem_RegWrite(ex_mem_RegWrite), .mem_wb_RegWrite(mem_wb_RegWrite), .forwardA(forwardA), .forwardB(forwardB)
);

// LÓGICA ATUALIZADA PARA O OPERANDO A (SUPORTE A AUIPC)
wire [31:0] alu_a_mux_in;
assign alu_a_mux_in = (id_ex_ALUASrc) ? id_ex_pc : id_ex_reg_data1;

always @(*) begin
    case (forwardA)
        2'b00:   operandA = alu_a_mux_in;
        2'b01:   operandA = wb_data;
        2'b10:   operandA = ex_mem_alu_result;
        default: operandA = alu_a_mux_in;
    endcase
    case (forwardB)
        2'b00:   operandB = id_ex_reg_data2;
        2'b01:   operandB = wb_data;
        2'b10:   operandB = ex_mem_alu_result;
        default: operandB = id_ex_reg_data2;
    endcase
end

assign alu_input_b = (id_ex_ALUSrc) ? id_ex_imm : operandB;

alu alu_main (.a(operandA), .b(alu_input_b), .alu_control(alu_control_out), .result(alu_result), .zero(alu_zero));

// LÓGICA DE DESVIO CONDICIONAL ATUALIZADA
assign branch_cond = (id_ex_Branch) &
                     ( (id_ex_funct3 == 3'b000 && alu_zero)        || // beq
                       (id_ex_funct3 == 3'b001 && ~alu_zero)       || // bne
                       (id_ex_funct3 == 3'b100 && alu_result == 1) || // blt
                       (id_ex_funct3 == 3'b101 && alu_result == 0) || // bge
                       (id_ex_funct3 == 3'b110 && alu_result == 1) || // bltu
                       (id_ex_funct3 == 3'b111 && alu_result == 0) );  // bgeu

// Lógica de cálculo de endereço de pulo
assign branch_addr = id_ex_pc + id_ex_imm;
assign jump_addr   = id_ex_pc + id_ex_imm;
assign jalr_addr   = id_ex_reg_data1 + id_ex_imm;

// Lógica de seleção do próximo PC
assign pc_sel = (id_ex_Jump == 2'b01) ? 2'b10 : // JAL
                (id_ex_Jump == 2'b10) ? 2'b11 : // JALR
                (branch_cond)         ? 2'b01 : // Branch
                                        2'b00 ; // PC+4

always @(posedge clk or posedge reset) begin
    if (reset) begin
        ex_mem_RegWrite <= 0; ex_mem_ResultSrc <= 0; ex_mem_pc_plus_4 <= 0;
        ex_mem_alu_result <= 0; ex_mem_write_data <= 0; ex_mem_imm <= 0; ex_mem_rd <= 0;
        ex_mem_MemRead <= 0; ex_mem_MemWrite <= 0;
    end else begin
        ex_mem_RegWrite <= id_ex_RegWrite; ex_mem_ResultSrc <= id_ex_ResultSrc;
        ex_mem_pc_plus_4 <= id_ex_pc_plus_4; ex_mem_alu_result <= alu_result;
        ex_mem_write_data <= operandB; ex_mem_imm <= id_ex_imm; ex_mem_rd <= id_ex_rd;
        ex_mem_MemRead <= id_ex_MemRead; ex_mem_MemWrite <= id_ex_MemWrite;
    end
end


//================================================================//
//                      ESTÁGIO MEM (Memory Access)               //
//================================================================//
data_memory dmem (
    .clk(clk), .MemRead(ex_mem_MemRead), .MemWrite(ex_mem_MemWrite),
    .addr(ex_mem_alu_result), .write_data(ex_mem_write_data), .read_data(mem_read_data)
);

always @(posedge clk or posedge reset) begin
    if (reset) begin
        mem_wb_RegWrite <= 0; mem_wb_ResultSrc <= 0; mem_wb_pc_plus_4 <= 0;
        mem_wb_mem_data <= 0; mem_wb_alu_result <= 0; mem_wb_imm <= 0; mem_wb_rd <= 0;
    end else begin
        mem_wb_RegWrite <= ex_mem_RegWrite; mem_wb_ResultSrc <= ex_mem_ResultSrc;
        mem_wb_pc_plus_4 <= ex_mem_pc_plus_4; mem_wb_mem_data <= mem_read_data; 
        mem_wb_alu_result <= ex_mem_alu_result; mem_wb_imm <= ex_mem_imm; mem_wb_rd <= ex_mem_rd;
    end
end


//================================================================//
//                      ESTÁGIO WB (Write Back)                   //
//================================================================//
assign wb_data = (mem_wb_ResultSrc == 2'b01) ? mem_wb_mem_data   : // 01: Vem da Memória
                 (mem_wb_ResultSrc == 2'b10) ? mem_wb_imm        : // 10: Vem do Imediato (LUI)
                 (mem_wb_ResultSrc == 2'b11) ? mem_wb_pc_plus_4  : // 11: Vem do PC+4 (JAL/JALR)
                                              mem_wb_alu_result;  // 00: Default: Vem da ULA

// Saídas para o testbench
assign o_stall = stall;
assign o_flush = flush;

endmodule