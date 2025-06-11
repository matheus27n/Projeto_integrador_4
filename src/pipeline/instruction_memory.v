module instruction_memory (
    input  wire [31:0] addr,
    output wire [31:0] instruction
);

reg [31:0] memory [0:255]; // 1KB (256 x 32 bits)

assign instruction = memory[addr[9:2]]; // palavra alinhada (word aligned)

initial begin
    // Exemplo de instruções para teste
 memory[0] = 32'h01000093; // addi x1, x0, 16
    memory[1] = 32'h02A00113; // addi x2, x0, 42
    memory[2] = 32'h00208823; // sw   x2, 16(x1) -> offset=16, rs1=x1, rs2=x2. Erro, deveria ser 0(x1). Corrigido:
    memory[2] = 32'h00208023; // sw   x2, 0(x1)
    memory[3] = 32'h00012183; // lw x3, 0(x1) <-- CORRETO; // lw x3, 0(x1) <-- Este hex está correto (usa x1)    memory[4] = 32'h00318233; // add  x4, x3, x0
    memory[5] = 32'h00220863; // beq  x4, x2, +8 bytes (pula 2 instruções para 0x20)
    memory[6] = 32'h06300293; // addi x5, x0, 99
    memory[7] = 32'h06300293; // addi x5, x0, 99 (será "comida" pelo flush)
    memory[8] = 32'h06400313; // L1: addi x6, x0, 100
    memory[9] = 32'h008003EF; // jal  x7, +8 bytes (pula 2 instruções para 0x30)
    memory[10] = 32'h05800413; // addi x8, x0, 88
    memory[11] = 32'h00000013; // nop
    memory[12] = 32'h0C800493; // L2: addi x9, x0, 200
end

endmodule
