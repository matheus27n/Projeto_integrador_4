module instruction_memory (
    input  wire [31:0] addr,
    output wire [31:0] instruction
);

reg [31:0] memory [0:255]; // 1KB (256 x 32 bits)

assign instruction = memory[addr[9:2]]; // palavra alinhada (word aligned)

initial begin
    // ==============================================================================
    // ||                    PROGRAMA DE TESTE COMPLETO (RV32I)                    ||
    // ==============================================================================

    // Assembly:
    // Objetivo: Testar LUI, AUIPC, SLLI, XORI, SLTIU, BNE, e JALR (chamada/retorno).
    
    // --- Parte 1: Setup e Testes Lógicos ---
    // PC=0x00: lui   x1, 0xAAAAA         // x1 = 0xAAAAA000. Carrega 20 bits superiores.
    // PC=0x04: auipc x2, 0               // x2 = 0x00000004. Endereço da própria instrução.
    // PC=0x08: slli  x3, x1, 4           // x3 = 0xAAAA0000. Shift left.
    // PC=0x0C: xori  x4, x3, 0x555       // x4 = 0xAAAA5555. Xor com imediato.
    // PC=0x10: sltiu x5, x4, 1           // x5 = (x4 < 1) ? 1:0. Será 0 pois x4 é um nº grande.

    // --- Parte 2: Teste de Desvio (BNE) ---
    // PC=0x14: bne   x4, x3, L1_BNE      // x4 != x3, então o desvio DEVE ser tomado. Pula para 0x20.
    // PC=0x18: addi  x6, x0, 999         // !! DEVE SER IGNORADO (FLUSH) !!
    // PC=0x1C: nop                     // Preenchimento

    // --- Parte 3: Teste de JALR (Simulando uma chamada de função) ---
    // PC=0x20: L1_BNE: addi x1, x1, 1540 // x1 = 0xAAAAA000 + 1540 = 0xAAAAA604. Endereço da "função".
    // PC=0x24: jalr  x7, 0(x1)           // Salta para endereço em x1 (0xAAAAA604). Salva PC+4 (0x28) em x7.
    // PC=0x28: addi  x8, x0, 888         // !! DEVE SER IGNORADO (FLUSH) !!
    // PC=0x2C: nop                     // Preenchimento
    
    // As instruções abaixo estão "longe" na memória, no endereço para o qual o JALR saltou.
    // --- Parte 4: O Código da "Função" ---
    // PC=...604: L2_FUNC: addi x9, x0, 111 // Código dentro da "função".
    // PC=...608: addi x10, x9, 111       // x10 = 222
    // PC=...60C: jalr  x0, 0(x7)           // Retorna para o endereço salvo em x7 (0x28). x0 significa não salvar link.
    // PC=...610: nop
    
    // --- Parte 5: Após o Retorno da Função ---
    // PC=0x30: L3_RET: addi x11, x0, 777 // Código executado após o retorno. TESTE FINAL.

    // ==============================================================================
    // Código de Máquina (Hex)
    // ==============================================================================
    
    // Parte 1 e 2
    memory[0] = 32'hAAAAA0B7; // 0x00: lui   x1, 0xAAAAA
    memory[1] = 32'h00000117; // 0x04: auipc x2, 0
    memory[2] = 32'h00409193; // 0x08: slli  x3, x1, 4
    memory[3] = 32'h5551C213; // 0x0C: xori  x4, x3, 0x555
    memory[4] = 32'h00123293; // 0x10: sltiu x5, x4, 1
    memory[5] = 32'h00321463; // 0x14: bne   x4, x3, +8 bytes (pula para 0x1C)
    memory[6] = 32'h3E700313; // 0x18: addi  x6, x0, 999 (FLUSHED)
    memory[7] = 32'h00000013; // 0x1C: nop

    // Parte 3 e 5
    // O PC saltou do bne para 0x20
    memory[8]  = 32'h60408093; // 0x20: L1_BNE: addi x1, x1, 1540 (0x604)
    memory[9]  = 32'h000083E7; // 0x24: jalr  x7, 0(x1)
    memory[10] = 32'h37800413; // 0x28: addi  x8, x0, 888 (FLUSHED)
    memory[11] = 32'h00000013; // 0x2C: nop
    memory[12] = 32'h30900593; // 0x30: L3_RET: addi x11, x0, 777

    // Parte 4: A "Função" em um endereço de memória distante (0x...604)
    // O endereço 0xAAAAA604 será mapeado para o endereço de palavra 0x2AAAA981, que é muito grande.
    // Para simplificar e manter na nossa memória de 1KB, vamos usar um endereço menor.
    // O programa de teste real usará um endereço dentro da nossa memória.
    // Vamos corrigir o programa para usar endereços realistas.
    
    // ==============================================================================
    // ||              PROGRAMA DE TESTE COMPLETO (VERSÃO CORRIGIDA)                 ||
    // ==============================================================================
    
    // Parte 1 e 2 (Mesma lógica, mas com valores diferentes para funcionar na memória)
    memory[0]  = 32'h000000B7; // lui   x1, 0         (x1=0)
    memory[1]  = 32'h04008093; // addi  x1, x1, 64    (x1=64, endereço da "função")
    memory[2]  = 32'h00000117; // auipc x2, 0         (x2=8, endereço desta instrução)
    memory[3]  = 32'h00411193; // slli  x3, x2, 4     (x3=128)
    memory[4]  = 32'h1001C213; // xori  x4, x3, 256   (x4=384)
    memory[5]  = 32'h00123293; // sltiu x5, x4, 1     (x5=0)
    memory[6]  = 32'h00321463; // bne   x4, x3, L1    (x4!=x3, tomado. Pula de 0x18 para 0x24)
    memory[7]  = 32'h3E700313; // addi  x6, x0, 999 (FLUSHED)
    memory[8]  = 32'h00000013; // nop
    
    // Parte 3 e 5
    memory[9]  = 32'h000083E7; // 0x24: L1: jalr x7, 0(x1) (Pula para 0x40 (64), salva 0x2C em x7)
    memory[10] = 32'h37800413; // 0x28: addi x8, x0, 888 (FLUSHED)
    memory[11] = 32'h00000013; // 0x2C: nop
    memory[12] = 32'h30900593; // 0x30: L3_RET: addi x11, x0, 777 (Executado após retorno)
    memory[13] = 32'h00000013; // nop para parar a execução
    
    // Parte 4: Código da "Função" no endereço 64 (0x40)
    memory[16] = 32'h06F00493; // 0x40: L2: addi x9, x0, 111
    memory[17] = 32'h06F48513; // 0x44: addi x10, x9, 111 (x10 = 222)
    memory[18] = 32'h00038067; // 0x48: jalr x0, 0(x7) (Retorna para 0x2C salvo em x7)
end

endmodule
