`timescale 1ns / 1ps

module tb_pipeline();
    // 1. Sinais para conectar ao processador
    reg clk;
    reg reset;

    // 2. Instanciação do Processador Pipeline
    pipeline_topo uut (
        .clk(clk),
        .reset(reset)
    );

    // 3. Bloco ÚNICO de Teste e Geração de Clock
    initial begin
        // --- FASE DE INICIALIZAÇÃO ---
        $display("Iniciando simulação...");
        clk = 0;
        reset = 1;
        
        // --- FASE DE RESET ---
        #15; // Mantém o reset ativo por 15ns
        reset = 0;
        $display("Reset desativado em %t.", $time);
        
        // --- FASE DE EXECUÇÃO ---
        // Gera 20 pulsos de clock (10 ciclos completos)
        // Adicionamos um display para cada mudança no clock para diagnóstico
        repeat (20) begin
            #5; // Espera 5ns
            clk = ~clk;
            $display("Clock mudou para %b em %t", clk, $time);
        end
        
        // --- FASE DE FINALIZAÇÃO ---
        $display("\nSimulação concluída.");
        $finish;
    end
    
    // 4. Geração do arquivo de ondas
    initial begin
        $dumpfile("pipeline_wave.vcd");
        $dumpvars(0, uut);
    end

endmodule