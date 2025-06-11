`timescale 1ns / 1ps

module datapath (
    input  wire        clk,
    input  wire        reset,
    output wire [31:0] pc_out
);

//================================================================//
//                      SINAIS E REGISTRADORES                    //
//================================================================//

// --- Sinais de Controle do Pipeline ---
wire       pc_write;       // Habilita a escrita no PC
wire       if_id_write;    // Habilita a escrita no registrador IF/ID
wire       nop;            // Sinal para injetar uma bolha (NOP) no pipeline

// --- Sinais de Controle da Unidade Principal ---
wire       RegWrite, MemRead, MemWrite, MemToReg, ALUSrc, Branch, Jump;
wire [1:0] ALUOp;

// --- Sinais do Estágio IF ---
reg  [31:0] pc;
wire [31:0] pc_plus_4;
wire [31:0] pc_next;
wire [31:0] instr;

// --- Registrador IF/ID ---
reg  [31:0] if_id_pc;
reg  [31:0] if_id_instr;

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
wire       stall; // Vem da Hazard Unit para pausar
wire       flush; // Sinal para limpar o pipeline após um desvio

// --- Registrador ID/EX ---
reg        id_ex_RegWrite, id_ex_MemRead, id_ex_MemWrite, id_ex_MemToReg, id_ex_ALUSrc;
reg [1:0]  id_ex_ALUOp;
reg        id_ex_Branch, id_ex_Jump; // PRECISAMOS PASSAR ESSES SINAIS!
reg [31:0] id_ex_pc, id_ex_reg_data1, id_ex_reg_data2, id_ex_imm;
reg [4:0]  id_ex_rs1, id_ex_rs2, id_ex_rd;
reg [2:0]  id_ex_funct3;
reg [6:0]  id_ex_funct7;

// --- Sinais do Estágio EX ---
wire [3:0]  alu_control_out;
wire [1:0]  forwardA, forwardB;
reg [31:0] operandA, operandB;
wire [31:0] alu_input_b;
wire [31:0] alu_result;
wire        alu_zero;
wire        pc_src;
wire [31:0] branch_addr;

// --- Registrador EX/MEM ---
reg        ex_mem_RegWrite, ex_mem_MemRead, ex_mem_MemWrite, ex_mem_MemToReg;
reg [31:0] ex_mem_alu_result, ex_mem_write_data;
reg [4:0]  ex_mem_rd;

// --- Sinais do Estágio MEM ---
wire [31:0] mem_read_data;

// --- Registrador MEM/WB ---
reg        mem_wb_RegWrite, mem_wb_MemToReg;
reg [31:0] mem_wb_mem_data, mem_wb_alu_result;
reg [4:0]  mem_wb_rd;

// --- Sinais do Estágio WB ---
wire [31:0] wb_data;


//================================================================//
//                      ESTÁGIO IF (Instruction Fetch)            //
//================================================================//
assign pc_out = pc;
assign pc_plus_4 = pc + 4;
assign flush = pc_src; // Flusha se um desvio for tomado

instruction_memory imem (
    .addr(pc), 
    .instruction(instr)
);

// --- Lógica de controle do PC ---
// O PC só avança se pc_write for 1. Ele é parado por um stall.
always @(posedge clk or posedge reset) begin
    if (reset)
        pc <= 32'h00000000;
    else if (pc_write)
        pc <= pc_next;
end

// --- MUX para selecionar o próximo PC ---
// Seleciona entre PC+4 ou o endereço de desvio.
assign pc_next = pc_src ? branch_addr : pc_plus_4;

// --- Controle de escrita do PC e IF/ID ---
assign pc_write = ~stall;
assign if_id_write = ~stall;

// --- Registrador IF/ID ---
always @(posedge clk or posedge reset) begin
    if (reset) begin
        if_id_pc    <= 0;
        if_id_instr <= 0;
    end 
    // Se houver flush (desvio tomado), a instrução é zerada (NOP)
    else if (flush) begin 
        if_id_pc    <= 0;
        if_id_instr <= 32'h00000013; // NOP (addi x0, x0, 0)
    end
    else if (if_id_write) begin
        if_id_pc    <= pc;
        if_id_instr <= instr;
    end
end


//================================================================//
//                      ESTÁGIO ID (Instruction Decode)           //
//================================================================//
register_file regfile (
    .clk(clk), 
    .RegWrite(mem_wb_RegWrite), // Escrita ocorre no estágio WB
    .rs1(rs1), 
    .rs2(rs2), 
    .rd(mem_wb_rd), 
    .write_data(wb_data), 
    .read_data1(reg_data1), 
    .read_data2(reg_data2)
);

// --- Unidade de Controle Principal ---
control_unit ctrl (
    .opcode(opcode), 
    .RegWrite(RegWrite), 
    .MemRead(MemRead), 
    .MemWrite(MemWrite), 
    .MemToReg(MemToReg), 
    .ALUSrc(ALUSrc), 
    .ALUOp(ALUOp), 
    .Branch(Branch), 
    .Jump(Jump)
);

// --- Gerador de Imediato (simplificado para I-type) ---
imm_gen immediate_generator (
    .instruction(if_id_instr), // MUDANÇA: Passa a instrução inteira
    .opcode(opcode),
    .imm(imm)
);

// --- Unidade de Detecção de Riscos ---
hazard_unit hazard (
    .id_ex_MemRead(id_ex_MemRead), // Sinal do estágio EX
    .id_ex_rd(id_ex_rd),           // Destino do estágio EX
    .if_id_rs1(rs1),               // Origem do estágio ID
    .if_id_rs2(rs2),               // Origem do estágio ID
    .stall(stall)
);

// --- Lógica da Bolha (NOP) ---
// Se houver um stall, os sinais de controle para o próximo estágio são zerados.
assign nop = stall;

// --- Registrador ID/EX ---
always @(posedge clk or posedge reset) begin
    if (reset || nop) begin // Se for reset ou stall, zera tudo (insere NOP)
        id_ex_RegWrite <= 0; id_ex_MemRead <= 0; id_ex_MemWrite <= 0; id_ex_MemToReg <= 0;
        id_ex_ALUSrc <= 0; id_ex_ALUOp <= 0; id_ex_Branch <= 0; id_ex_Jump <= 0;
        id_ex_pc <= 0; id_ex_reg_data1 <= 0; id_ex_reg_data2 <= 0;
        id_ex_imm <= 0; id_ex_rs1 <= 0; id_ex_rs2 <= 0; id_ex_rd <= 0;
        id_ex_funct3 <= 0; id_ex_funct7 <= 0;
    end else begin
        id_ex_RegWrite <= RegWrite; id_ex_MemRead <= MemRead; id_ex_MemWrite <= MemWrite; id_ex_MemToReg <= MemToReg;
        id_ex_ALUSrc <= ALUSrc; id_ex_ALUOp <= ALUOp; id_ex_Branch <= Branch; id_ex_Jump <= Jump; // Passando os sinais
        id_ex_pc <= if_id_pc; id_ex_reg_data1 <= reg_data1; id_ex_reg_data2 <= reg_data2;
        id_ex_imm <= imm; id_ex_rs1 <= rs1; id_ex_rs2 <= rs2; id_ex_rd <= rd;
        id_ex_funct3 <= funct3; id_ex_funct7 <= funct7;
    end
end


//================================================================//
//                      ESTÁGIO EX (Execute)                      //
//================================================================//
alu_control alu_ctrl_unit (
    .ALUOp(id_ex_ALUOp), 
    .funct3(id_ex_funct3), 
    .funct7(id_ex_funct7), 
    .alu_control(alu_control_out)
);

forwarding_unit fwd (
    .id_ex_rs1(id_ex_rs1), 
    .id_ex_rs2(id_ex_rs2),
    .ex_mem_rd(ex_mem_rd), 
    .mem_wb_rd(mem_wb_rd),
    .ex_mem_RegWrite(ex_mem_RegWrite), 
    .mem_wb_RegWrite(mem_wb_RegWrite),
    .forwardA(forwardA), 
    .forwardB(forwardB)
);

// --- MUX de Forwarding para Operando A ---
always @(*) begin
    case (forwardA)
        2'b00: operandA = id_ex_reg_data1;
        2'b01: operandA = wb_data;           // Forward do estágio WB
        2'b10: operandA = ex_mem_alu_result; // Forward do estágio MEM
        default: operandA = id_ex_reg_data1;
    endcase
end

// --- MUX de Forwarding para Operando B ---
always @(*) begin
    case (forwardB)
        2'b00: operandB = id_ex_reg_data2;
        2'b01: operandB = wb_data;           // Forward do estágio WB
        2'b10: operandB = ex_mem_alu_result; // Forward do estágio MEM
        default: operandB = id_ex_reg_data2;
    endcase
end

assign alu_input_b = (id_ex_ALUSrc) ? id_ex_imm : operandB;

alu alu_main (
    .a(operandA), 
    .b(alu_input_b), 
    .alu_control(alu_control_out),
    .result(alu_result), 
    .zero(alu_zero)
);

// --- Lógica de Decisão do Desvio ---
assign pc_src = id_ex_Branch & alu_zero;
assign branch_addr = id_ex_pc + id_ex_imm; // B-type precisa de shift left 1

// --- Registrador EX/MEM ---
always @(posedge clk or posedge reset) begin
    if (reset) begin
        ex_mem_RegWrite <= 0; ex_mem_MemRead <= 0; ex_mem_MemWrite <= 0;
        ex_mem_MemToReg <= 0; ex_mem_alu_result <= 0;
        ex_mem_write_data <= 0; ex_mem_rd <= 0;
    end else begin
        ex_mem_RegWrite <= id_ex_RegWrite; ex_mem_MemRead <= id_ex_MemRead;
        ex_mem_MemWrite <= id_ex_MemWrite; ex_mem_MemToReg <= id_ex_MemToReg;
        ex_mem_alu_result <= alu_result;
        ex_mem_write_data <= operandB; // Dado a ser escrito na memória (para SW)
        ex_mem_rd <= id_ex_rd;
    end
end


//================================================================//
//                      ESTÁGIO MEM (Memory Access)               //
//================================================================//
data_memory dmem (
    .clk(clk),
    .MemRead(ex_mem_MemRead), 
    .MemWrite(ex_mem_MemWrite),
    .addr(ex_mem_alu_result), 
    .write_data(ex_mem_write_data),
    .read_data(mem_read_data)
);

// --- Registrador MEM/WB ---
always @(posedge clk or posedge reset) begin
    if (reset) begin
        mem_wb_RegWrite <= 0; mem_wb_MemToReg <= 0;
        mem_wb_mem_data <= 0; mem_wb_alu_result <= 0;
        mem_wb_rd <= 0;
    end else begin
        mem_wb_RegWrite <= ex_mem_RegWrite; mem_wb_MemToReg <= ex_mem_MemToReg;
        mem_wb_mem_data <= mem_read_data; 
        mem_wb_alu_result <= ex_mem_alu_result;
        mem_wb_rd <= ex_mem_rd;
    end
end


//================================================================//
//                      ESTÁGIO WB (Write Back)                   //
//================================================================//
assign wb_data = (mem_wb_MemToReg) ? mem_wb_mem_data : mem_wb_alu_result;

endmodule