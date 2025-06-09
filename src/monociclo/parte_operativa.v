`timescale 1ns / 1ps

module parte_operativa(
    input wire clk,
    input wire reset,
    // Sinais da Unidade de Controle (Entradas)
    input wire [3:0] ALUControl,
    input wire ALUSrc,
    input wire MemtoReg,
    input wire RegWrite,
    input wire MemRead,
    input wire MemWrite,
    input wire Branch,
    input wire Jump,
    // Saídas para a Unidade de Controle
    output wire [6:0] opcode,
    output wire [2:0] funct3,
    output wire [6:0] funct7
);
    // === Sinais Internos ===
    wire [31:0] PC, PCNext, PCPlus4, PCBranch, PCTarget;
    wire [31:0] Instr;
    reg  [31:0] ImmExt;
    wire [31:0] RD1, RD2;
    wire [31:0] SrcA, SrcB;
    reg  [31:0] ALUResult;
    wire [31:0] ReadData;
    wire [31:0] Result;
    wire        Zero;
    wire        TakeBranch;

    // === 1. Lógica do Program Counter (PC) ===
    reg [31:0] PC_reg;
    always @(posedge clk or posedge reset) begin
        if (reset)
            PC_reg <= 32'h0;
        else
            PC_reg <= PCNext;
    end
    assign PC = PC_reg;
    
    // === 2. Memória de Instruções (1KB) ===
    reg [31:0] instr_mem [0:1023];
    
    initial begin
        // Programa de teste para BNE e BLT
        instr_mem[0] = 32'h00500093; // 0x00: addi x1, x0, 5
        instr_mem[1] = 32'h00A00113; // 0x04: addi x2, x0, 10
        instr_mem[2] = 32'h00209463; // 0x08: bne x1, x2, 8 
        instr_mem[3] = 32'hDEADBEEF; // 0x0C: Instrução pulada
        instr_mem[4] = 32'h00100193; // 0x10: addi x3, x0, 1 
        instr_mem[5] = 32'h0020C463; // 0x14: blt x1, x2, 8
        instr_mem[6] = 32'hCAFEBABE; // 0x18: Instrução pulada
        instr_mem[7] = 32'h00200213; // 0x1C: addi x4, x0, 2
    end
    
    assign Instr = instr_mem[PC[11:2]];
    
    assign opcode = Instr[6:0];
    assign funct3 = Instr[14:12];
    assign funct7 = Instr[31:25];
    
    // === 3. Banco de Registradores ===
    reg [31:0] reg_file [0:31];
    
    assign RD1 = (Instr[19:15] == 5'b0) ? 32'h0 : reg_file[Instr[19:15]];
    assign RD2 = (Instr[24:20] == 5'b0) ? 32'h0 : reg_file[Instr[24:20]];
    
    always @(posedge clk) begin
        if (RegWrite && (Instr[11:7] != 5'b0))
            reg_file[Instr[11:7]] <= Result;
    end
    
    // === 4. Extensor de Imediato ===
    // Este bloco agora tem a única responsabilidade de gerar o imediato.
    always @(*) begin
        case(opcode)
            7'b0010011, 7'b0000011:  // I-type (ADDI, LW)
                ImmExt = {{20{Instr[31]}}, Instr[31:20]};
            7'b0100011:              // S-type (SW)
                ImmExt = {{20{Instr[31]}}, Instr[31:25], Instr[11:7]};
            7'b1100011:              // B-type (BEQ, etc)
                ImmExt = {{19{Instr[31]}}, Instr[31], Instr[7], Instr[30:25], Instr[11:8], 1'b0};
            7'b1101111:              // J-type (JAL)
                ImmExt = {{11{Instr[31]}}, Instr[31], Instr[19:12], Instr[20], Instr[30:21], 1'b0};
            default: 
                ImmExt = 32'h0;
        endcase
    end
    
    // === 5. ULA (Unidade Lógica e Aritmética) ===
    assign SrcA = RD1;
    assign SrcB = ALUSrc ? ImmExt : RD2;
    
    always @(*) begin
        case(ALUControl)
            4'b0010: ALUResult = SrcA + SrcB; // ADD
            4'b0110: ALUResult = SrcA - SrcB; // SUB
            4'b0000: ALUResult = SrcA & SrcB; // AND
            4'b0001: ALUResult = SrcA | SrcB; // OR
            4'b0111: ALUResult = ($signed(SrcA) < $signed(SrcB)) ? 32'h1 : 32'h0; // SLT (Signed)
            4'b1000: ALUResult = (SrcA < SrcB) ? 32'h1 : 32'h0; // SLTU (Unsigned)
            default: ALUResult = 32'h0;
        endcase
    end
    
    // === 6. Memória de Dados (1KB) ===
    reg [31:0] data_mem [0:1023];
    
    always @(posedge clk) begin
        if (MemWrite)
            data_mem[ALUResult[11:2]] <= RD2;
    end
    
    assign ReadData = MemRead ? data_mem[ALUResult[11:2]] : 32'h0;
    
    // === 7. Lógica de Seleção do Próximo PC ===
    assign PCPlus4 = PC + 4;
    assign PCBranch = PC + ImmExt;
    assign PCTarget = PC + ImmExt;
    
    // Lógica que decide se o desvio deve ser tomado
    reg take_branch_decision;
    assign Zero = (RD1 == RD2); 

    always @(*) begin
        take_branch_decision = 1'b0;
        if (Branch) begin
            case(funct3)
                3'b000: if (Zero) take_branch_decision = 1'b1;     // BEQ
                3'b001: if (!Zero) take_branch_decision = 1'b1;    // BNE
                3'b100: if (ALUResult == 1) take_branch_decision = 1'b1; // BLT
                3'b101: if (ALUResult == 0) take_branch_decision = 1'b1; // BGE
                3'b110: if (ALUResult == 1) take_branch_decision = 1'b1; // BLTU
                3'b111: if (ALUResult == 0) take_branch_decision = 1'b1; // BGEU
            endcase
        end
    end
    assign TakeBranch = take_branch_decision;

    // MUX final que seleciona o próximo PC
    wire [31:0] PC_temp = TakeBranch ? PCBranch : PCPlus4;
    assign PCNext = Jump ? PCTarget : PC_temp;
    
    // === 8. MUX para escrita no Banco de Registradores ===
    assign Result = MemtoReg ? ReadData : (Jump ? PCPlus4 : ALUResult);
    
endmodule