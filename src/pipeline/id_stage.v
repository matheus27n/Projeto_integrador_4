// Módulo: id_stage.v (CORRIGIDO)
// Descrição: Estágio de Decodificação (ID).
module id_stage (
    input  logic       clk,
    input  logic       rst,
    
    // Entrada vinda do registrador IF/ID
    input  logic [31:0] instruction,
    
    // Conexão com o banco de registradores (para a escrita que vem do estágio WB)
    input  logic       wb_reg_write_en,
    input  logic [4:0]  wb_rd_addr,
    input  logic [31:0] wb_rd_data,

    // Saídas de controle para o próximo estágio
    output logic       reg_write_en_out,
    output logic       ALUSrc_out,
    output logic       MemtoReg_out,
    output logic       MemRead_out,
    output logic       MemWrite_out,
    output logic       Branch_out,
    output logic       Jump_out,
    output logic [3:0]  alu_op_out,

    // Saídas de dados para o próximo estágio
    output logic [31:0] rs1_data,
    output logic [31:0] rs2_data,
    output logic [31:0] immediate,
    output logic [4:0]  rd_addr,
    output logic [4:0]  rs1_addr, // Saída para unidade de hazard
    output logic [4:0]  rs2_addr  // Saída para unidade de hazard
);

    // --- Decodificação dos campos da instrução ---
    wire [6:0] opcode = instruction[6:0];
    wire [4:0] rd     = instruction[11:7];
    wire [2:0] funct3 = instruction[14:12]; // CORREÇÃO: Extrair funct3
    wire [4:0] rs1    = instruction[19:15];
    wire [4:0] rs2    = instruction[24:20];
    wire [6:0] funct7 = instruction[31:25]; // CORREÇÃO: Extrair funct7

    // --- Instanciação dos Módulos Internos ---
    
    reg_file reg_file_inst (
        .clk(clk),
        .rst(rst),
        .we(wb_reg_write_en),
        .rs1_addr(rs1),
        .rs2_addr(rs2),
        .rd_addr(wb_rd_addr),
        .rd_data(wb_rd_data),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );

    control_unit control_unit_inst (
        .opcode(opcode),
        .funct3(funct3), // CORREÇÃO: Passar funct3
        .funct7(funct7), // CORREÇÃO: Passar funct7
        // Conectando todas as saídas de controle
        .reg_write_en(reg_write_en_out),
        .ALUSrc(ALUSrc_out),
        .MemtoReg(MemtoReg_out),
        .MemRead(MemRead_out),
        .MemWrite(MemWrite_out),
        .Branch(Branch_out),
        .Jump(Jump_out),
        .alu_op(alu_op_out)
    );

    // --- Geração do Imediato (com extensão de sinal) ---
    // NOTA: Ainda faltam os imediatos dos tipos B e J. Adicionaremos depois.
    always_comb begin
        case (opcode)
            // I-Type (addi, lw, slli, slti)
            7'b0010011, 7'b0000011: begin
                immediate = {{20{instruction[31]}}, instruction[31:20]};
            end
            // S-Type (sw)
            7'b0100011: begin
                immediate = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
            end
            // B-Type (beq, bne)
            7'b1100011: begin
                immediate = {{20{instruction[31]}}, instruction[7], instruction[30:25], instruction[11:8], 1'b0};
            end
            // J-Type (jal)
            7'b1101111: begin
                immediate = {{12{instruction[31]}}, instruction[19:12], instruction[20], instruction[30:21], 1'b0};
            end
            default: immediate = 32'hxxxxxxxx;
        endcase
    end
    
    assign rd_addr = rd;
    assign rs1_addr = rs1;
    assign rs2_addr = rs2;

endmodule