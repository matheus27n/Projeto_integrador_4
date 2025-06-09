`timescale 1ns / 1ps

module parte_operativa(
    input wire clk,
    input wire reset,
    input wire [3:0] ALUControl,
    input wire ALUSrc,
    input wire MemtoReg,
    input wire RegWrite,
    input wire MemRead,
    input wire MemWrite,
    input wire Branch,
    input wire Jump,
    output wire [6:0] opcode,
    output wire [2:0] funct3,
    output wire [6:0] funct7
);
    // Conexões internas
    wire [31:0] PC, PCNext, PCPlus4, PCBranch, PCTarget;
    wire [31:0] Instr;
    reg [31:0] ImmExt;
    wire [31:0] RD1, RD2;
    wire [31:0] SrcA, SrcB;
    reg [31:0] ALUResult;
    wire [31:0] ReadData;
    wire [31:0] Result;
    wire Zero;
    wire PCSrc;
    
    // PC (Program Counter)
    reg [31:0] PC_reg;
    always @(posedge clk or posedge reset) begin
        if (reset)
            PC_reg <= 32'h00000000;
        else
            PC_reg <= PCNext;
    end
    assign PC = PC_reg;
    
    // Memória de Instruções (1KB)
    reg [31:0] instr_mem [0:1023];
    
    // Inicialização da memória de instruções
    initial begin
        // ADDI x1, x0, 5
        instr_mem[0] = 32'b000000000101_00000_000_00001_0010011;
        // ADDI x2, x0, 3
        instr_mem[1] = 32'b000000000011_00000_000_00010_0010011;
        // ADD x3, x1, x2
        instr_mem[2] = 32'b0000000_00010_00001_000_00011_0110011;
        // SW x3, 0(x0)
        instr_mem[3] = 32'b0000000_00011_00000_010_00000_0100011;
        // LW x4, 0(x0)
        instr_mem[4] = 32'b000000000000_00000_010_00100_0000011;
        // BEQ x4, x3, 4
        instr_mem[5] = 32'b0_000000_00100_00011_000_0100_1100011;
        // JAL x5, 8
        instr_mem[6] = 32'b000000001000_00000_000_00101_1101111;
        // NOPs (ADDI x0, x0, 0)
        for (int i = 7; i < 1024; i = i + 1)
            instr_mem[i] = 32'b000000000000_00000_000_00000_0010011;
    end
    
    assign Instr = instr_mem[PC[9:0]];
    
    // Extração dos campos da instrução
    assign opcode = Instr[6:0];
    assign funct3 = Instr[14:12];
    assign funct7 = Instr[31:25];
    
     // Banco de Registradores - Implementação correta para síntese
    reg [31:0] reg_file [31:0];
    reg [31:0] rd1_reg, rd2_reg;  // Registros para saídas
    
    // Inicialização dos registradores
    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1)
            reg_file[i] = 32'b0;
    end
    
    // Leitura assíncrona (combinatória)
    always @(*) begin
        rd1_reg = (Instr[19:15] != 0) ? reg_file[Instr[19:15]] : 0;
        rd2_reg = (Instr[24:20] != 0) ? reg_file[Instr[24:20]] : 0;
    end
    
    assign RD1 = rd1_reg;
    assign RD2 = rd2_reg;
    
    // Escrita síncrona (edge-sensitive)
    always @(posedge clk) begin
        if (RegWrite && (Instr[11:7] != 0))
            reg_file[Instr[11:7]] <= Result;
    end
    
    // Extensor de Imediato
    always @(*) begin
        case(opcode)
            // I-type
            7'b0010011, 7'b0000011: 
                ImmExt = {{20{Instr[31]}}, Instr[31:20]};
            // S-type
            7'b0100011: 
                ImmExt = {{20{Instr[31]}}, Instr[31:25], Instr[11:7]};
            // B-type
            7'b1100011: 
                ImmExt = {{20{Instr[31]}}, Instr[7], Instr[30:25], Instr[11:8], 1'b0};
            // J-type
            7'b1101111: 
                ImmExt = {{12{Instr[31]}}, Instr[19:12], Instr[20], Instr[30:21], 1'b0};
            default: 
                ImmExt = 32'b0;
        endcase
    end
    
    // ALU
    assign SrcA = RD1;
    assign SrcB = ALUSrc ? ImmExt : RD2;
    
    always @(*) begin
        case(ALUControl)
            4'b0000: ALUResult = SrcA & SrcB;
            4'b0001: ALUResult = SrcA | SrcB;
            4'b0010: ALUResult = SrcA + SrcB;
            4'b0011: ALUResult = SrcA << SrcB[4:0];
            4'b0100: ALUResult = SrcA ^ SrcB;
            4'b0101: ALUResult = SrcA >> SrcB[4:0];
            4'b0110: ALUResult = SrcA - SrcB;
            4'b0111: ALUResult = ($signed(SrcA) < $signed(SrcB)) ? 32'b1 : 32'b0;
            default: ALUResult = 32'b0;
        endcase
    end
    
    assign Zero = (ALUResult == 32'b0);
    
    // Memória de Dados (1KB) - Implementação com always para síntese
    reg [31:0] data_mem [0:1023];
    reg [31:0] read_data_reg;  // Registro para saída da memória
    
    // Inicialização da memória de dados
    initial begin
        for (i = 0; i < 1024; i = i + 1)
            data_mem[i] = 32'b0;
    end
    
    // Leitura e escrita síncrona da memória de dados
    always @(posedge clk) begin
        if (MemWrite)
            data_mem[ALUResult[9:0]] <= RD2;
            
        // Registra a saída de leitura
        if (MemRead)
            read_data_reg <= data_mem[ALUResult[9:0]];
        else
            read_data_reg <= 32'b0;
    end
    
    assign ReadData = read_data_reg;
    
    // Lógica para o próximo PC
    assign PCPlus4 = PC + 4;
    assign PCBranch = PC + ImmExt;
    assign PCTarget = PC + ImmExt;
    assign PCSrc = (Branch & Zero) | Jump;
    
    assign PCNext = Jump ? PCTarget : (PCSrc ? PCBranch : PCPlus4);
    
    // MUX para escrever no banco de registradores
    assign Result = MemtoReg ? ReadData : (Jump ? PCPlus4 : ALUResult);
endmodule