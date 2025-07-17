// ========================================================
// Módulo: instruction_memory
// Descrição: Programa de teste com 4 NOPs ("bolhas")
//            inseridos manualmente entre cada instrução
//            para isolar e depurar a lógica do pipeline.
// ========================================================
module instruction_memory (
    input  wire [31:0] addr,
    output wire [31:0] instruction
);

// A memória deve ter tamanho suficiente para o teste.
// Assumindo 1024 posições, conforme a correção anterior.
reg [31:0] memory [0:1023];

// Leitura assíncrona (comportamento de ROM)
// O endereçamento deve corresponder ao da data_memory (1024 posições -> bits 11:2)
// No entanto, para a memória de instrução, o PC avança de 4 em 4, então o
// endereçamento por palavra (addr[9:2]) para 256 palavras é suficiente para este teste.
assign instruction = memory[addr[9:2]];

initial begin
    // ====================================================================================
    // ===        PROGRAMA DE TESTE COM BOLHAS MANUAIS PARA ISOLAR HAZARDS              ===
    // ====================================================================================
    // Se este programa funcionar, significa que a lógica de execução de cada
    // instrução está correta, e qualquer erro anterior estava na lógica de
    // detecção/resolução de hazards (forwarding/stall).
    // Endereços 32 (0x20) e 1056 (0x420) garantem um conflito no índice 8 da cache.
    // ------------------------------------------------------------------------------------

    // Instrução NOP (addi x0, x0, 0) para ser usada como bolha
    reg [31:0] NOP = 32'h00000013;
    integer i;

    // Inicializa toda a memória com NOPs para garantir um estado limpo
    for (i = 0; i < 256; i = i + 1) begin
        memory[i] = NOP;
    end

    // --- Parte 1: Setup ---
    memory[0]  = 32'h02000113; // addi x2, x0, 32       ; x2 = 32 (Endereço A, índice 8)
    // 4 bolhas manuais
    memory[5]  = 32'h42000193; // addi x3, x0, 1056     ; x3 = 1056 (Endereço B, índice 8 - CONFLITO)
    // 4 bolhas manuais
    memory[10] = 32'h04D00093; // addi x1, x0, 77       ; x1 = 77
    // 4 bolhas manuais

    // --- Parte 2: Teste de Write Miss ---
    memory[15] = 32'h00112023; // sw x1, 0(x2)          ; Salva 77 no endereço 32.
    // 4 bolhas manuais

    // --- Parte 3: Teste de Leitura (com bolhas, será um HIT) ---
    memory[20] = 32'h00012283; // lw x5, 0(x2)          ; Lê do endereço 32. Deverá carregar 77.
    // 4 bolhas manuais

    // --- Parte 4: Teste de Conflito ---
    memory[25] = 32'h0001A303; // lw x6, 0(x3)          ; Lê do endereço 1056 (ejeta o bloco do end. 32).
    // 4 bolhas manuais

    // --- Parte 5: Verificação do Conflito ---
    memory[30] = 32'h00012383; // lw x7, 0(x2)          ; Lê do endereço 32 novamente (deve causar miss).
    // 4 bolhas manuais

    // --- Parte 6: Fim da Simulação ---
    memory[35] = 32'h06400A13; // addi x20, x0, 100     ; Condição de término.
    memory[36] = NOP;          // Garante que a instrução final chegue ao WB.

end
endmodule
