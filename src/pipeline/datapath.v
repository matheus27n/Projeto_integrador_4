`timescale 1ns / 1ps

module datapath (
    input  wire        clk,
    input  wire        reset,
    output wire [31:0] pc_out
);

//==== Declaração de fios e registradores principais ====
wire       stall;
wire [1:0] forwardA, forwardB;
wire [31:0] wb_data;

reg [31:0] pc;
wire [31:0] pc_next;

wire [31:0] instr;
reg  [31:0] if_id_pc;
reg  [31:0] if_id_instr;

wire [4:0]  rs1, rs2, rd;
wire [6:0]  opcode;
wire [2:0]  funct3;
wire [6:0]  funct7;
wire [31:0] reg_data1, reg_data2;
wire        RegWrite, MemRead, MemWrite, MemToReg, ALUSrc, Branch, Jump;
wire [1:0]  ALUOp;
wire [31:0] imm;

reg        id_ex_RegWrite, id_ex_MemRead, id_ex_MemWrite, id_ex_MemToReg, id_ex_ALUSrc;
reg [1:0]  id_ex_ALUOp;
reg [31:0] id_ex_pc, id_ex_reg_data1, id_ex_reg_data2, id_ex_imm;
reg [4:0]  id_ex_rs1, id_ex_rs2, id_ex_rd;
reg [2:0]  id_ex_funct3;
reg [6:0]  id_ex_funct7;

wire [3:0] alu_ctrl;
wire [31:0] alu_input_b, alu_result;
wire        alu_zero;
reg  [31:0] operandA, operandB;

reg        ex_mem_RegWrite, ex_mem_MemRead, ex_mem_MemWrite, ex_mem_MemToReg;
reg [31:0] ex_mem_alu_result, ex_mem_write_data;
reg [4:0]  ex_mem_rd;

wire [31:0] mem_read_data;

reg        mem_wb_RegWrite, mem_wb_MemToReg;
reg [31:0] mem_wb_mem_data, mem_wb_alu_result;
reg [4:0]  mem_wb_rd;

//==== Estágio IF ====
assign pc_out = pc;
assign pc_next = pc + 4;

instruction_memory imem (.addr(pc), .instruction(instr));

always @(posedge clk or posedge reset) begin
    if (reset) pc <= 0;
    else if (!stall) pc <= pc_next;
end

always @(posedge clk or posedge reset) begin
    if (reset) begin
        if_id_pc <= 0;
        if_id_instr <= 0;
    end else if (!stall) begin
        if_id_pc <= pc;
        if_id_instr <= instr;
    end
end

//==== Estágio ID ====
assign rs1 = if_id_instr[19:15];
assign rs2 = if_id_instr[24:20];
assign rd  = if_id_instr[11:7];
assign opcode = if_id_instr[6:0];
assign funct3 = if_id_instr[14:12];
assign funct7 = if_id_instr[31:25];

register_file regfile (
    .clk(clk),
    .RegWrite(mem_wb_RegWrite),
    .rs1(rs1), .rs2(rs2), .rd(mem_wb_rd),
    .write_data(wb_data),
    .read_data1(reg_data1), .read_data2(reg_data2)
);

control_unit ctrl (
    .opcode(opcode),
    .RegWrite(RegWrite), .MemRead(MemRead), .MemWrite(MemWrite),
    .MemToReg(MemToReg), .ALUSrc(ALUSrc), .ALUOp(ALUOp),
    .Branch(Branch), .Jump(Jump)
);

assign imm = {{20{if_id_instr[31]}}, if_id_instr[31:20]};

hazard_unit hazard (
    .id_ex_MemRead(id_ex_MemRead),
    .id_ex_rd(id_ex_rd),
    .if_id_rs1(rs1), .if_id_rs2(rs2),
    .stall(stall)
);

//==== ID/EX ====
always @(posedge clk or posedge reset) begin
    if (reset) begin
        id_ex_RegWrite <= 0; id_ex_MemRead <= 0; id_ex_MemWrite <= 0; id_ex_MemToReg <= 0;
        id_ex_ALUSrc <= 0; id_ex_ALUOp <= 0; id_ex_pc <= 0;
        id_ex_reg_data1 <= 0; id_ex_reg_data2 <= 0;
        id_ex_imm <= 0; id_ex_rs1 <= 0; id_ex_rs2 <= 0; id_ex_rd <= 0;
        id_ex_funct3 <= 0; id_ex_funct7 <= 0;
    end else begin
        id_ex_RegWrite <= RegWrite; id_ex_MemRead <= MemRead; id_ex_MemWrite <= MemWrite; id_ex_MemToReg <= MemToReg;
        id_ex_ALUSrc <= ALUSrc; id_ex_ALUOp <= ALUOp; id_ex_pc <= if_id_pc;
        id_ex_reg_data1 <= reg_data1; id_ex_reg_data2 <= reg_data2;
        id_ex_imm <= imm; id_ex_rs1 <= rs1; id_ex_rs2 <= rs2; id_ex_rd <= rd;
        id_ex_funct3 <= funct3; id_ex_funct7 <= funct7;
    end
end

//==== Estágio EX ====
alu_control alu_ctrl_unit (
    .ALUOp(id_ex_ALUOp), .funct3(id_ex_funct3), .funct7(id_ex_funct7),
    .alu_control(alu_ctrl)
);

forwarding_unit fwd (
    .id_ex_rs1(id_ex_rs1), .id_ex_rs2(id_ex_rs2),
    .ex_mem_rd(ex_mem_rd), .mem_wb_rd(mem_wb_rd),
    .ex_mem_RegWrite(ex_mem_RegWrite), .mem_wb_RegWrite(mem_wb_RegWrite),
    .forwardA(forwardA), .forwardB(forwardB)
);

always @(*) begin
    case (forwardA)
        2'b00: operandA = id_ex_reg_data1;
        2'b01: operandA = wb_data;
        2'b10: operandA = ex_mem_alu_result;
        default: operandA = id_ex_reg_data1;
    endcase
    case (forwardB)
        2'b00: operandB = id_ex_reg_data2;
        2'b01: operandB = wb_data;
        2'b10: operandB = ex_mem_alu_result;
        default: operandB = id_ex_reg_data2;
    endcase
end

assign alu_input_b = (id_ex_ALUSrc) ? id_ex_imm : operandB;

alu alu_main (
    .a(operandA), .b(alu_input_b), .alu_control(alu_ctrl),
    .result(alu_result), .zero(alu_zero)
);

//==== EX/MEM ====
always @(posedge clk or posedge reset) begin
    if (reset) begin
        ex_mem_RegWrite <= 0; ex_mem_MemRead <= 0; ex_mem_MemWrite <= 0;
        ex_mem_MemToReg <= 0; ex_mem_alu_result <= 0;
        ex_mem_write_data <= 0; ex_mem_rd <= 0;
    end else begin
        ex_mem_RegWrite <= id_ex_RegWrite; ex_mem_MemRead <= id_ex_MemRead;
        ex_mem_MemWrite <= id_ex_MemWrite; ex_mem_MemToReg <= id_ex_MemToReg;
        ex_mem_alu_result <= alu_result; ex_mem_write_data <= operandB;
        ex_mem_rd <= id_ex_rd;
    end
end

//==== MEM ====
data_memory dmem (
    .clk(clk),
    .MemRead(ex_mem_MemRead), .MemWrite(ex_mem_MemWrite),
    .addr(ex_mem_alu_result), .write_data(ex_mem_write_data),
    .read_data(mem_read_data)
);

//==== MEM/WB ====
always @(posedge clk or posedge reset) begin
    if (reset) begin
        mem_wb_RegWrite <= 0; mem_wb_MemToReg <= 0;
        mem_wb_mem_data <= 0; mem_wb_alu_result <= 0;
        mem_wb_rd <= 0;
    end else begin
        mem_wb_RegWrite <= ex_mem_RegWrite; mem_wb_MemToReg <= ex_mem_MemToReg;
        mem_wb_mem_data <= mem_read_data; mem_wb_alu_result <= ex_mem_alu_result;
        mem_wb_rd <= ex_mem_rd;
    end
end

//==== WB ====
assign wb_data = (mem_wb_MemToReg) ? mem_wb_mem_data : mem_wb_alu_result;

endmodule