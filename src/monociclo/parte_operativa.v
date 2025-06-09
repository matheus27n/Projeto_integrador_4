`timescale 1ns / 1ps

module parte_operativa(
    input wire clk,
    input wire reset,
    // Sinais da Unidade de Controle
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
    wire        PCSrc;
    
    // === 1. Lógica do Program Counter (PC) ===
    // O PC é um registrador que aponta para a instrução atual.
    reg [31:0] PC_reg;
    always @(posedge clk or posedge reset) begin
        if (reset)
            PC_reg <= 32'h0;
        else
            PC_reg <= PCNext;
    end
    assign PC = PC_reg;
    
    // === 2. Memória de Instruções (1KB) ===
    // Armazena o programa a ser executado.
    reg [31:0] instr_mem [0:1023];
    
    // Inicialização da memória de instruções (seu programa de teste)
    initial begin
        instr_mem[0] = 32'h00500093; // ADDI x1, x0, 5
        instr_mem[1] = 32'h00300113; // ADDI x2, x0, 3
        instr_mem[2] = 32'h002081B3; // ADD x3, x1, x2
        instr_mem[3] = 32'h00302023; // SW x3, 0(x0)
        instr_mem[4] = 32'h00002203; // LW x4, 0(x0)
        instr_mem[5] = 32'h00418463; // BEQ x3, x4, offset 8 (pula 2 inst)
        instr_mem[6] = 32'h00000293; // ADDI x5, x0, 0 (inst a ser pulada)
        instr_mem[7] = 32'h00100293; // ADDI x5, x0, 1 (inst a ser pulada)
        instr_mem[8] = 32'h008002EF; // JAL x5, 8
    end
    
    // CORREÇÃO CRÍTICA: O PC é um endereço em bytes (0, 4, 8...). A memória é um
    // array de palavras (índice 0, 1, 2...). Para converter, dividimos por 4,
    // o que é o mesmo que ignorar os 2 bits menos significativos.
    assign Instr = instr_mem[PC[11:2]];
    
    // Extração dos campos da instrução
    assign opcode = Instr[6:0];
    assign funct3 = Instr[14:12];
    assign funct7 = Instr[31:25];
    
    // === 3. Banco de Registradores ===
    reg [31:0] reg_file [0:31];
    
    // MELHORIA: A leitura é feita de forma combinacional direta.
    // Garante que a leitura do registrador x0 sempre retorne 0.
    assign RD1 = (Instr[19:15] == 5'b0) ? 32'h0 : reg_file[Instr[19:15]];
    assign RD2 = (Instr[24:20] == 5'b0) ? 32'h0 : reg_file[Instr[24:20]];
    
    // A escrita ocorre na borda de subida do clock, se RegWrite estiver ativo.
    always @(posedge clk) begin
        if (RegWrite && (Instr[11:7] != 5'b0)) // Não escreve no registrador x0
            reg_file[Instr[11:7]] <= Result;
    end
    
    // === 4. Extensor de Imediato ===
    // Gera o valor imediato de 32 bits a partir do formato da instrução.
    always @(*) begin
        case(opcode)
            7'b0010011, 7'b0000011:  // I-type (ADDI, LW)
                ImmExt = {{20{Instr[31]}}, Instr[31:20]};
            7'b0100011:              // S-type (SW)
                ImmExt = {{20{Instr[31]}}, Instr[31:25], Instr[11:7]};
            7'b1100011:              // B-type (BEQ)
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
            4'b0011: ALUResult = SrcA << SrcB[4:0]; // SLL
            4'b0101: ALUResult = SrcA >> SrcB[4:0]; // SRL
            4'b0100: ALUResult = SrcA ^ SrcB; // XOR
            4'b0111: ALUResult = ($signed(SrcA) < $signed(SrcB)) ? 32'h1 : 32'h0; // SLT
            default: ALUResult = 32'h0;
        endcase
    end
    
    // Flag Zero para desvios (BEQ, BNE)
    assign Zero = (RD1 == RD2);
    
    // === 6. Memória de Dados (1KB) ===
    reg [31:0] data_mem [0:1023];
    
    // CORREÇÃO: A escrita na memória é síncrona.
    always @(posedge clk) begin
        if (MemWrite)
            // CORREÇÃO CRÍTICA: Endereçamento com [11:2]
            data_mem[ALUResult[11:2]] <= RD2;
    end
    
    // CORREÇÃO: A leitura é combinacional em um processador monociclo.
    assign ReadData = MemRead ? data_mem[ALUResult[11:2]] : 32'h0;
    
    // === 7. Lógica de Seleção do Próximo PC ===
    assign PCPlus4 = PC + 4;
    assign PCBranch = PC + ImmExt;
    assign PCTarget = PC + ImmExt; // Para JAL. Para JALR seria diferente.
    
    // MELHORIA: Lógica de seleção do PC mais clara e correta.
    wire TakeBranch = Branch & Zero; // Condição para BEQ. Para BNE seria Branch & ~Zero.
    wire [31:0] PC_temp = TakeBranch ? PCBranch : PCPlus4;
    assign PCNext = Jump ? PCTarget : PC_temp;
    
    // === 8. MUX para escrita no Banco de Registradores ===
    // Seleciona o dado que será escrito de volta no banco de registradores.
    assign Result = MemtoReg ? ReadData : (Jump ? PCPlus4 : ALUResult);
endmodule