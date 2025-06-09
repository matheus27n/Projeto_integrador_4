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
    // Sinais internos...
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

    // PC Logic
    reg [31:0] PC_reg;
    always @(posedge clk or posedge reset) begin
        if (reset) PC_reg <= 32'h0;
        else PC_reg <= PCNext;
    end
    assign PC = PC_reg;
    
    // Memória de Instruções com PROGRAMA DE TESTE CORRIGIDO
    reg [31:0] instr_mem [0:1023];
    initial begin
        // FASE 1: SETUP
        instr_mem[0]  = 32'h06400093; // 0x00: addi x1, x0, 100
        instr_mem[1]  = 32'hFCE00113; // 0x04: addi x2, x0, -50
        instr_mem[2]  = 32'h00400E13; // 0x08: addi x28, x0, 4
        // FASE 2: TESTES TIPO-R
        instr_mem[3]  = 32'h002081B3; // 0x0C: add  x3, x1, x2
        instr_mem[4]  = 32'h40208233; // 0x10: sub  x4, x1, x2
        instr_mem[5]  = 32'h0020F2B3; // 0x14: and  x5, x1, x2
        instr_mem[6]  = 32'h0020E333; // 0x18: or   x6, x1, x2
        instr_mem[7]  = 32'h001123B3; // 0x1C: slt  x7, x2, x1
        instr_mem[8]  = 32'h00113433; // 0x20: sltu x8, x2, x1
        instr_mem[9]  = 32'h01C094B3; // 0x24: sll  x9, x1, x28
        // FASE 3: TESTES DE MEMÓRIA (com SW corrigido)
       instr_mem[10] = 32'h02902423;
         // 0x28: sw x9, 40(x0)
        instr_mem[11] = 32'h02802503; // 0x2C: lw x10, 40(x0)
        // FASE 4: TESTES DE DESVIOS
        instr_mem[12] = 32'h00A49463; // 0x30: bne x9, x10, 8 (NÃO deve tomar)
        instr_mem[13] = 32'h00100593; // 0x34: addi x11, x0, 1
        instr_mem[14] = 32'h00A48663; // 0x38: beq x9, x10, 8 (DEVE tomar)
        instr_mem[15] = 32'h06300613; // 0x3C: addi x12, x0, 99 (NÃO deve executar)
        instr_mem[16] = 32'h00114463; // 0x40: blt x2, x1, 8 (DEVE tomar)
        instr_mem[17] = 32'h06300693; // 0x44: addi x13, x0, 99 (NÃO deve executar)
        instr_mem[18] = 32'h0020D463; // 0x48: bge x1, x2, 8 (DEVE tomar)
        instr_mem[19] = 32'h06300713; // 0x4C: addi x14, x0, 99 (NÃO deve executar)
        // FASE 5: TESTE DE SALTO
        instr_mem[20] = 32'h014007EF; // 0x50: jal x15, 20
        instr_mem[21] = 32'hDEADBEEF; // 0x54: Instrução pulada
        // FIM DO PROGRAMA
        instr_mem[22] = 32'h0000006F; // 0x58: jal x0, 0 (loop infinito)
    end
    
    assign Instr = instr_mem[PC[11:2]];
    assign opcode = Instr[6:0];
    assign funct3 = Instr[14:12];
    assign funct7 = Instr[31:25];
    
    // Banco de Registradores
    reg [31:0] reg_file [0:31];
    assign RD1 = (Instr[19:15] == 5'b0) ? 32'h0 : reg_file[Instr[19:15]];
    assign RD2 = (Instr[24:20] == 5'b0) ? 32'h0 : reg_file[Instr[24:20]];
    always @(posedge clk) begin
        if (RegWrite && (Instr[11:7] != 5'b0))
            reg_file[Instr[11:7]] <= Result;
    end
    
    // Extensor de Imediato
    always @(*) begin
        case(opcode) // I-type, S-type, B-type, J-type...
           // (Lógica completa como antes)
           7'b0010011, 7'b0000011: ImmExt = {{20{Instr[31]}}, Instr[31:20]};
           7'b0100011: ImmExt = {{20{Instr[31]}}, Instr[31:25], Instr[11:7]};
           7'b1100011: ImmExt = {{19{Instr[31]}}, Instr[31], Instr[7], Instr[30:25], Instr[11:8], 1'b0};
           7'b1101111: ImmExt = {{11{Instr[31]}}, Instr[31], Instr[19:12], Instr[20], Instr[30:21], 1'b0};
           default: ImmExt = 32'h0;
        endcase
    end
    
    // ULA com SLL CORRIGIDO
    assign SrcA = RD1;
    assign SrcB = ALUSrc ? ImmExt : RD2;
    always @(*) begin
        case(ALUControl)
            4'b0010: ALUResult = SrcA + SrcB;
            4'b0110: ALUResult = SrcA - SrcB;
            4'b0000: ALUResult = SrcA & SrcB;
            4'b0001: ALUResult = SrcA | SrcB;
            4'b0100: ALUResult = SrcA ^ SrcB;
            // CORREÇÃO SUTIL: O valor do shift vem apenas dos 5 bits menos significativos de SrcB
            4'b0011: ALUResult = SrcA << SrcB[4:0]; // SLL
            4'b0101: ALUResult = SrcA >> SrcB[4:0]; // SRL
            4'b0111: ALUResult = ($signed(SrcA) < $signed(SrcB)) ? 32'h1 : 32'h0;
            4'b1000: ALUResult = (SrcA < SrcB) ? 32'h1 : 32'h0;
            default: ALUResult = 32'h0;
        endcase
    end
    
    // Memória de Dados
    reg [31:0] data_mem [0:1023];
    always @(posedge clk) begin
        if (MemWrite) data_mem[ALUResult[11:2]] <= RD2;
    end
    assign ReadData = MemRead ? data_mem[ALUResult[11:2]] : 32'h0;
    
    // Lógica do Próximo PC
    assign PCPlus4 = PC + 4;
    assign PCBranch = PC + ImmExt;
    assign PCTarget = PC + ImmExt;
    reg take_branch_decision;
    assign Zero = (RD1 == RD2); 
    always @(*) begin
        take_branch_decision = 1'b0;
        if (Branch) begin
            case(funct3) // BEQ, BNE, BLT, BGE, BLTU, BGEU...
               3'b000: if (Zero) take_branch_decision = 1'b1;
               3'b001: if (!Zero) take_branch_decision = 1'b1;
               3'b100: if (ALUResult == 1) take_branch_decision = 1'b1;
               3'b101: if (ALUResult == 0) take_branch_decision = 1'b1;
               3'b110: if (ALUResult == 1) take_branch_decision = 1'b1;
               3'b111: if (ALUResult == 0) take_branch_decision = 1'b1;
            endcase
        end
    end
    assign TakeBranch = take_branch_decision;
    wire [31:0] PC_temp = TakeBranch ? PCBranch : PCPlus4;
    assign PCNext = Jump ? PCTarget : PC_temp;
    
    // MUX Final
    assign Result = MemtoReg ? ReadData : (Jump ? PCPlus4 : ALUResult);
    
endmodule