// ========================================================
// Modulo: instruction_memory
// Descricao: Contem um programa de teste robusto que executa
//            um contador em loop e um salto incondicional,
//            validando a logica de forwarding e de desvio
//            sem depender da cache.
// ========================================================
module instruction_memory (
    input  wire [31:0] addr,
    output wire [31:0] instruction
);

reg [31:0] memory [0:255];
assign instruction = memory[addr[9:2]];

initial begin
    // ====================================================================================
    // ===           TESTE DE ESTRESSE: CONTADOR EM LOOP E SALTO INCONDICIONAL          ===
    // ====================================================================================
    // Este programa valida o nucleo do processador em um cenario complexo.
    //
    // Fluxo esperado:
    // 1. x1 (contador) sera incrementado de 1 ate 5.
    // 2. O desvio BNE sera tomado 4 vezes, voltando para o inicio do loop.
    // 3. Na 5a iteracao, x1 se torna 5, o BNE nao e tomado.
    // 4. A instrucao JAL saltara sobre o codigo "morto".
    // 5. O programa terminara com x1=5, x2=5, e x20=100.
    // ------------------------------------------------------------------------------------

    reg [31:0] NOP = 32'h00000013;
    integer i;

    // Inicializa toda a memoria com NOPs
    for (i = 0; i < 256; i = i + 1) begin
        memory[i] = NOP;
    end

    // --- Parte 1: Setup ---
    memory[0] = 32'h00000093; // addi x1, x0, 0        ; x1 (contador) = 0
    memory[1] = 32'h00500113; // addi x2, x0, 5        ; x2 (limite) = 5

    // --- Parte 2: Loop (Endereco 0x08) ---
    // LOOP_START:
    // Hazard de Dados (RAW): 'bne' depende do novo valor de x1.
    // ESPERADO: Forwarding do resultado do 'addi' para a logica de desvio.
    memory[2] = 32'h00108093; // addi x1, x1, 1        ; contador++
    
    // O desvio para tras (-4 bytes) volta para a instrucao 'addi' acima.
    // ESPERADO: FLUSH do pipeline toda vez que o desvio for tomado.
    memory[3] = 32'hfe209ee3; // bne x1, x2, -4        ; if (contador != limite) goto LOOP_START
    
    // --- Parte 3: Salto Incondicional (Apos o fim do loop) ---
    // O salto pula 2 instrucoes (+8 bytes) para o endereco 0x1C (memory[7]).
    // ESPERADO: FLUSH da instrucao seguinte.
    memory[4] = 32'h0080006f; // jal x0, +8            ; Salta para a instrucao final.
    
    // --- Parte 4: Codigo Morto (Deve ser pulado pelo JAL) ---
    memory[5] = 32'hdeadbeef; // addi x6, x0, 999      ; Esta instrucao NAO deve ser executada.
    memory[6] = NOP;          // Espaco vazio.
    
    // --- Parte 5: Fim da Simulacao ---
    memory[7] = 32'h06400A13; // END: addi x20, x0, 100 ; Condicao de termino.
    memory[8] = NOP;          // Garante que a instrucao final chegue ao WB.
    memory[9] = NOP;

end
endmodule