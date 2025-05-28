`timescale 1ns / 1ps

module processador_riscv(
    input wire clk,
    input wire reset
);
    // Parâmetros da memória
    parameter IMEM_SIZE = 1024;  // Tamanho da memória de instruções (1KB)
    parameter DMEM_SIZE = 1024;  // Tamanho da memória de dados (1KB)
    
    // Sinais internos
    wire [31:0] pc, pc_next, pc_plus4, pc_target;
    wire [31:0] instr;
    wire [4:0] rs1, rs2, rd;
    wire [31:0] rs1_data, rs2_data, rd_data;
    wire [31:0] imm_ext;
    wire [2:0] alu_control;
    wire [31:0] alu_result;
    wire alu_zero;
    wire [31:0] dmem_data;
    wire [31:0] wb_data;
    wire reg_write, alu_src, mem_write, mem_to_reg, branch, pc_src;
    
    // Registro PC
    reg [31:0] pc_reg;
    always @(posedge clk or posedge reset)
        if (reset) pc_reg <= 0;
        else pc_reg <= pc_next;
    assign pc = pc_reg;
    
    // Memória de instruções
    reg [31:0] imem [0:IMEM_SIZE-1];
initial $readmemh("C:/Users/Matheus/Desktop/faculdade/PROJETO INTEGRADOR 4/processador_ricv/src/monociclo/programa.hex", imem);
    assign instr = imem[pc[31:2]];  // Divisão por 4 pois os endereços são de palavras
    
    // Decodificação de instruções
    assign rs1 = instr[19:15];
    assign rs2 = instr[24:20];
    assign rd = instr[11:7];
    
    // Banco de registradores
    reg [31:0] reg_file [0:31];
    always @(posedge clk)
        if (reg_write && rd != 0)  // x0 é sempre zero
            reg_file[rd] <= wb_data;
    assign rs1_data = (rs1 != 0) ? reg_file[rs1] : 0;
    assign rs2_data = (rs2 != 0) ? reg_file[rs2] : 0;
    
    // Gerador de imediatos
    wire [31:0] imm_i = {{20{instr[31]}}, instr[31:20]};
    wire [31:0] imm_s = {{20{instr[31]}}, instr[31:25], instr[11:7]};
    wire [31:0] imm_b = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
    wire [31:0] imm_j = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
    assign imm_ext = (instr[6:0] == 7'b1100011) ? imm_b :  // Branch
                    (instr[6:0] == 7'b0100011) ? imm_s :  // Store
                    (instr[6:0] == 7'b1101111) ? imm_j :  // Jal
                    imm_i;  // Default: I-type
    
    // Unidade de controle
    control_unit ctrl(
        .opcode(instr[6:0]),
        .funct3(instr[14:12]),
        .funct7(instr[31:25]),
        .reg_write(reg_write),
        .alu_src(alu_src),
        .mem_write(mem_write),
        .mem_to_reg(mem_to_reg),
        .branch(branch),
        .alu_control(alu_control)
    );
    
    // MUX para entrada B da ULA
    wire [31:0] alu_src_b = alu_src ? imm_ext : rs2_data;
    
    // ULA
    alu alu(
        .a(rs1_data),
        .b(alu_src_b),
        .alu_control(alu_control),
        .result(alu_result),
        .zero(alu_zero)
    );
    
    // Memória de dados
    reg [31:0] dmem [0:DMEM_SIZE-1];
initial $readmemh("C:/Users/Matheus/Desktop/faculdade/PROJETO INTEGRADOR 4/processador_ricv/src/monociclo/data.hex", dmem);
    always @(posedge clk)
        if (mem_write)
            dmem[alu_result[31:2]] <= rs2_data;  // Divisão por 4
    assign dmem_data = dmem[alu_result[31:2]];
    
    // Lógica de write-back
    assign wb_data = mem_to_reg ? dmem_data : alu_result;
    
    // Lógica do PC
    assign pc_plus4 = pc + 4;
    assign pc_target = pc + imm_ext;
    assign pc_src = branch & alu_zero;
    assign pc_next = pc_src ? pc_target : pc_plus4;
endmodule

// Unidade de controle
module control_unit(
    input wire [6:0] opcode,
    input wire [2:0] funct3,
    input wire [6:0] funct7,
    output reg reg_write,
    output reg alu_src,
    output reg mem_write,
    output reg mem_to_reg,
    output reg branch,
    output reg [2:0] alu_control
);
    always @(*) begin
        case(opcode)
            7'b0110011: begin // R-type
                reg_write = 1; alu_src = 0; mem_write = 0; 
                mem_to_reg = 0; branch = 0;
                case(funct3)
                    3'b000: alu_control = funct7[5] ? 3'b001 : 3'b000; // ADD/SUB
                    3'b010: alu_control = 3'b101; // SLT
                    3'b110: alu_control = 3'b011; // OR
                    3'b111: alu_control = 3'b010; // AND
                    default: alu_control = 3'b000;
                endcase
            end
            7'b0010011: begin // I-type
                reg_write = 1; alu_src = 1; mem_write = 0; 
                mem_to_reg = 0; branch = 0;
                case(funct3)
                    3'b000: alu_control = 3'b000; // ADDI
                    3'b010: alu_control = 3'b101; // SLTI
                    default: alu_control = 3'b000;
                endcase
            end
            7'b0000011: begin // Load
                reg_write = 1; alu_src = 1; mem_write = 0; 
                mem_to_reg = 1; branch = 0;
                alu_control = 3'b000;
            end
            7'b0100011: begin // Store
                reg_write = 0; alu_src = 1; mem_write = 1; 
                mem_to_reg = 0; branch = 0;
                alu_control = 3'b000;
            end
            7'b1100011: begin // Branch
                reg_write = 0; alu_src = 0; mem_write = 0; 
                mem_to_reg = 0; branch = 1;
                case(funct3)
                    3'b000: alu_control = 3'b001; // BEQ
                    3'b001: alu_control = 3'b001; // BNE
                    default: alu_control = 3'b000;
                endcase
            end
            default: begin
                reg_write = 0; alu_src = 0; mem_write = 0; 
                mem_to_reg = 0; branch = 0;
                alu_control = 3'b000;
            end
        endcase
    end
endmodule

// Unidade Lógica e Aritmética (ULA)
module alu(
    input wire [31:0] a, b,
    input wire [2:0] alu_control,
    output reg [31:0] result,
    output wire zero
);
    always @(*) begin
        case(alu_control)
            3'b000: result = a + b;      // ADD
            3'b001: result = a - b;      // SUB
            3'b010: result = a & b;      // AND
            3'b011: result = a | b;      // OR
            3'b101: result = ($signed(a) < $signed(b)) ? 1 : 0; // SLT
            default: result = 0;
        endcase
    end
    assign zero = (result == 0);
endmodule