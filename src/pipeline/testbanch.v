`timescale 1ns / 1ps

module testbench;

    // --- Sinais de Conexão com o Processador ---
    reg  clk;
    reg  reset;
    wire [31:0] pc_out;
    wire stall_from_cpu; // Fio para capturar o sinal de stall
    wire flush_from_cpu; // Fio para capturar o sinal de flush

    // --- Instanciação do Módulo Top ---
    top uut (
        .clk(clk),
        .reset(reset),
        .pc_out(pc_out),
        .stall_out(stall_from_cpu), // Conecta a nova saída do top
        .flush_out(flush_from_cpu)  // Conecta a nova saída do top
    );

    // --- Geração de Clock e Reset ---
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $display("===============================================================================");
        $display("||          INICIANDO SIMULAÇÃO COM TESTBENCH DIDÁTICO DE PIPELINE           ||");
        $display("===============================================================================");
        
        reset = 1;
        #20;
        reset = 0;

        #500; 
        $display("Simulação atingiu o TIMEOUT! Verifique se há algum problema.");
        $stop;
    end
    
    // --- Geração de Waveform (VCD) ---
    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, uut); 
    end


    // ============================================================================== //
    //                      LÓGICA DO TESTBENCH DIDÁTICO                              //
    // ============================================================================== //

    // 1. "Memória de Instruções" em formato de texto para o display
    reg [8*40:1] instruction_text [0:255]; // Array de 256 strings de 40 caracteres

    initial begin
        // Inicializa com NOPs
        for (integer i = 0; i < 256; i = i + 1) begin
            instruction_text[i] = "nop";
        end

        // Preenche com o programa de teste atual
        instruction_text[0] = "addi x1, x0, 16";
        instruction_text[1] = "addi x2, x0, 42";
        instruction_text[2] = "sw   x2, 0(x1)";
        instruction_text[3] = "lw   x3, 0(x1)";
        instruction_text[4] = "add  x4, x3, x0";
        instruction_text[5] = "beq  x4, x2, L1 (PC=0x20)";
        instruction_text[6] = "addi x5, x0, 99";
        instruction_text[7] = "nop (bolha do desvio)";
        instruction_text[8] = "L1: addi x6, x0, 100";
        instruction_text[9] = "jal  x7, L2 (PC=0x30)";
        instruction_text[10] = "addi x8, x0, 88";
        instruction_text[11] = "nop (bolha do desvio)";
        instruction_text[12] = "L2: addi x9, x0, 200";
    end

    // 2. Registradores "sombra" para PC e texto da instrução em cada estágio
    reg [31:0] pc_if, pc_id, pc_ex, pc_mem, pc_wb;
    reg [8*40:1] instr_if, instr_id, instr_ex, instr_mem, instr_wb;

    // 3. Lógica do pipeline "sombra" que imita o pipeline real
    always @(posedge clk) begin
        if (reset) begin
            // Reseta todos os estágios para NOP
            pc_if <= 0; instr_if <= "nop";
            pc_id <= 0; instr_id <= "nop";
            pc_ex <= 0; instr_ex <= "nop";
            pc_mem <= 0; instr_mem <= "nop";
            pc_wb <= 0; instr_wb <= "nop";
        end else begin
            // Estágio IF sempre busca a instrução apontada pelo PC
            pc_if <= pc_out;
            instr_if <= instruction_text[pc_out >> 2];

            // Estágio ID avança SE não houver stall
            if (!stall_from_cpu) begin
                pc_id <= pc_if;
                // Se o estágio anterior foi limpo, ID recebe um NOP
                instr_id <= flush_from_cpu ? "--- FLUSHED ---" : instr_if;
            end
            // Se houver stall, ID mantém seu valor anterior (não fazemos nada)

            // Estágio EX sempre avança, mas pode receber uma bolha
            pc_ex <= pc_id;
            // Se houver stall, EX recebe uma bolha (NOP). Senão, recebe de ID.
            instr_ex <= stall_from_cpu ? "--- STALL BUBBLE ---" : instr_id;

            // Estágios MEM e WB sempre avançam
            pc_mem <= pc_ex;
            instr_mem <= instr_ex;

            pc_wb <= pc_mem;
            instr_wb <= instr_mem;
        end
    end
    
    // 4. Lógica de display inteligente de registradores e pipeline
    reg [31:0] reg_prev [0:31]; // Armazena o valor anterior dos registradores

 // Monitoramento completo, inteligente e condição de parada
    always @(posedge clk) begin
        // Durante o reset, inicializamos os valores de checagem com 'x'
        if (reset) begin
            for (integer i = 0; i < 32; i = i + 1) begin
                // MUDANÇA: Inicializa com 'x' para evitar a falsa detecção de mudança de 0->x no início.
                reg_prev[i] <= 32'bx; 
            end
        // Fora do reset, a lógica principal de display e checagem é executada
        end else begin
            $display("-------------------[ CICLO DE CLOCK @ t=%0t ]-------------------", $time);
            // Mostra o estado do Pipeline
            $display("IF : [%h] %s", pc_if, instr_if);
            $display("ID : [%h] %s", pc_id, instr_id);
            $display("EX : [%h] %s", pc_ex, instr_ex);
            $display("MEM: [%h] %s", pc_mem, instr_mem);
            $display("WB : [%h] %s", pc_wb, instr_wb);
            
            // Verifica e mostra APENAS os registradores que mudaram de valor
            // A checagem agora compara o valor anterior (que pode ser 'x') com o valor atual
            for (integer i = 1; i < 32; i = i + 1) begin
                // A comparação '!==" (case inequality) é a mais segura para incluir 'x' e 'z'
                if (reg_prev[i] !== uut.dp.regfile.registers[i]) begin
                    // O formato %d pode não mostrar 'x' de forma clara, mas a lógica da comparação funciona
                    $display(">> RESULTADO: Registrador x%0d mudou de %d para %d", i, reg_prev[i], uut.dp.regfile.registers[i]);
                    reg_prev[i] <= uut.dp.regfile.registers[i];
                end
            end
            
            // Condição de parada final
            // A checagem '=== 200' é mais segura, pois garante o valor CORRETO.
            if (uut.dp.regfile.registers[9] === 200) begin
                #10; // Espera um ciclo extra para o display mostrar o valor final de x9
                $display("===============================================================================");
                $display("|| SUCESSO! Programa de teste concluído e verificado.                        ||");
                $display("===============================================================================");
                $stop;
            end
        end
    end

endmodule