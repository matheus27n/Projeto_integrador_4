// ========================================================
// Módulo: instruction_memory
// Descrição: Contém o programa de teste final, sem bolhas
//            manuais, para validar a lógica de hazard
//            automática do processador (forwarding/stall).
// ========================================================
module instruction_memory (
    input  wire [31:0] addr,
    output wire [31:0] instruction
);

// A memória deve ter tamanho suficiente para o teste.
reg [31:0] memory [0:255];

// Leitura assíncrona (comportamento de ROM)
assign instruction = memory[addr[9:2]];

initial begin
    // ====================================================================================
    // ===       TESTE FINAL DO PIPELINE - HAZARDS DE DADOS E DE CONTROLE               ===
    // ====================================================================================
    // Este programa executa a mesma lógica do teste anterior, mas sem as bolhas
    // manuais. Ele força o processador a usar suas unidades de forwarding e de
    // stall para resolver os hazards de dados (RAW) automaticamente.
    //
    // O resultado final nos registradores deve ser IDÊNTICO ao do teste com bolhas.
    // ------------------------------------------------------------------------------------

    // Instrução NOP (addi x0, x0, 0)
    reg [31:0] NOP = 32'h00000013;
    integer i;

    // Inicializa toda a memória com NOPs para garantir um estado limpo
    for (i = 0; i < 256; i = i + 1) begin
        memory[i] = NOP;
    end

    // --- Sequência de Teste Contínua ---
    memory[0] = 32'h00A00093; // addi x1, x0, 10       ; x1 = 10
    memory[1] = 32'h01400113; // addi x2, x0, 20       ; x2 = 20
    
    // Hazard de Dados (RAW): slt depende de x1 e x2.
    // ESPERADO: Forwarding dos valores de x1 e x2 para a ULA.
    memory[2] = 32'h001121b3; // slt x3, x2, x1        ; x3 = (20 < 10) ? 1 : 0  => x3 = 0
    
    // Hazard de Dados (RAW): bne depende de x3.
    // ESPERADO: Forwarding do resultado do slt (0) para a unidade de branch.
    // O desvio NÃO será tomado (0 == 0).
    memory[3] = 32'h00019663; // bne x3, x0, +12       ; Salta para o endereço 0x1C se x3 != x0
    
    // Esta instrução DEVE ser executada.
    memory[4] = 32'h06F00293; // addi x5, x0, 111      ; x5 = 111
    
    // Salto incondicional.
    // ESPERADO: FLUSH da instrução seguinte.
    memory[5] = 32'h0080006f; // jal x0, +8            ; Salta para o endereço 0x1C
    
    // Esta instrução NÃO deve ser executada (será "flushed").
    memory[6] = 32'h0DE00313; // addi x6, x0, 222      ; x6 não deve ser alterado.
    
    // --- Fim da Simulação ---
    memory[7] = 32'h06400A13; // END: addi x20, x0, 100 ; Condição de término.
    memory[8] = NOP;          // Garante que a instrução final chegue ao WB.
    memory[9] = NOP;
    memory[10]= NOP;

end
endmodule