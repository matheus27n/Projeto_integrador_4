module instruction_memory (
    input  wire [31:0] addr,
    output wire [31:0] instruction
);

reg [31:0] memory [0:255]; // 1KB (256 x 32 bits)

assign instruction = memory[addr[9:2]]; // palavra alinhada (word aligned)
initial begin

    //     // Usando a versão final e corrigida do programa de teste
    //     memory[0] = 32'h00000093; // 0x00: addi x1, x0, 0
    //     memory[1] = 32'h00500113; // 0x04: addi x2, x0, 5
    //     memory[2] = 32'h00108093; // 0x08: LOOP: addi x1, x1, 1
    //     memory[3] = 32'hFE209EE3; // 0x0C: bne  x1, x2, -4 (volta para 0x08) <--- CORREÇÃO AQUI
    //     memory[4] = 32'h00208463; // 0x10: beq  x1, x2, +8 (pula para 0x18)
    //     memory[5] = 32'h3E700493; // 0x14: addi x9, x0, 999 (FLUSHED)
    //     memory[6] = 32'h00418533; // 0x18: HAZARD_TEST: add x10, x3, x4
    //     memory[7] = 32'h00550633; // 0x1C: add x12, x10, x5
    //     memory[8] = 32'h00102023; // 0x20: sw x1, 0(x0)
    //     memory[9] = 32'h00002703; // 0x24: lw x14, 0(x0)
    //     memory[10]= 32'h001707B3; // 0x28: add x15, x14, x1
    //     memory[11]= 32'h06400A13; // 0x2C: addi x20, x0, 100
    //     memory[12]= 32'h00000013; // nop

    memory[0] = 32'h00A00093; // 0x00: addi x1, x0, 10
    memory[1] = 32'h01900113; // 0x04: addi x2, x0, 25
    memory[2] = 32'h00A00193; // 0x08: addi x3, x0, 10
    memory[3] = 32'h00208233; // 0x0C: add  x4, x1, x2
    memory[4] = 32'h401102B3; // 0x10: sub  x5, x2, x1
    memory[5] = 32'h00521463; // 0x14: bne  x4, x5, +8 (pula para 0x1C)
    memory[6] = 32'h3E700313; // 0x18: addi x6, x0, 999 (FLUSHED)
    memory[7] = 32'h008003EF; // 0x1C: L1_JUMP: jal x7, +8 (pula para 0x24)
    memory[8] = 32'h37800413; // 0x20: addi x8, x0, 888 (FLUSHED)
    memory[9] = 32'h06400A13; // 0x24: L2_END: addi x20, x0, 100
    
    // Preenche o resto com NOPs para segurança
    for (integer i = 10; i < 256; i = i + 1) begin
        memory[i] = 32'h00000013;
    end
end
endmodule
