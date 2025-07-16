// Módulo: id_stage.v (VERSÃO FINAL E CORRIGIDA)
// Descrição: Estágio de Decodificação (ID).

module id_stage (
    input  logic        clk,
    input  logic        rst,
    
    // Entrada vinda do registrador IF/ID
    input  logic [31:0] instruction,
    
    // Conexão com o banco de registradores (para a escrita que vem do estágio WB)
    input  logic        wb_reg_write_en,
    input  logic [4:0]  wb_rd_addr,
    input  logic [31:0] wb_rd_data,

    // <<-- SAÍDAS ATUALIZADAS PARA TODOS OS SINAIS DE CONTROLE -->>
    output logic        reg_write_en_out,
    output logic        ALUSrc_out,
    output logic        MemtoReg_out,
    output logic        MemRead_out,
    output logic        MemWrite_out,
    output logic [3:0]  alu_op_out,

    // Saídas de dados para o próximo estágio
    output logic [31:0] rs1_data,
    output logic [31:0] rs2_data,
    output logic [31:0] immediate,
    output logic [4:0]  rd_addr
);

    // --- Decodificação dos campos da instrução ---
    wire [6:0] opcode = instruction[6:0];
    wire [4:0] rd     = instruction[11:7];
    wire [4:0] rs1    = instruction[19:15];
    wire [4:0] rs2    = instruction[24:20];

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
        // Conectando todas as saídas de controle
        .reg_write_en(reg_write_en_out),
        .ALUSrc(ALUSrc_out),
        .MemtoReg(MemtoReg_out),
        .MemRead(MemRead_out),
        .MemWrite(MemWrite_out),
        .alu_op(alu_op_out)
    );

    // --- Geração do Imediato (com extensão de sinal) ---
    always_comb begin
        case (opcode)
            // I-Type (addi, lw)
            7'b0010011, 7'b0000011: begin
                immediate = {{20{instruction[31]}}, instruction[31:20]};
            end
            // S-Type (sw)
            7'b0100011: begin
                immediate = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
            end
            default: immediate = 32'hxxxxxxxx;
        endcase
    end
    
    assign rd_addr = rd;

endmodule