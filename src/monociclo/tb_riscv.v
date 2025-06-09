// tb_riscv.v
`timescale 1ns/1ps

module tb_riscv;

    // Sinais para conectar ao módulo topo
    reg clk;
    reg reset;
    wire [31:0] reg_a0_out;

    // Instanciação do processador (DUT - Device Under Test)
    riscv_monociclo_topo dut (
        .clk(clk),
        .reset(reset),
        .reg_a0_out(reg_a0_out)
    );

    // Geração do Clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // Período de 10ns (100 MHz)
    end

    // Procedimento de Teste
    initial begin
        // 1. Aplica o Reset
        reset = 1;
        #15; // Mantém o reset por 15ns
        reset = 0;
        
        // O processador começará a executar as instruções da memória de instruções
        // a cada borda de subida do clock.

        // Vamos rodar por alguns ciclos para executar o programa de teste
        #100; // Roda por 10 ciclos (100ns)

        // Verificações (opcional, mas recomendado)
        // Após 5 ciclos (50ns), a instrução LW deve ter completado.
        // O valor carregado da memória (15) deve estar em x4.
        // A instrução SW escreveu 15 no endereço 12.
        // O registrador x3 deve conter 15.
        
        $display("Simulação finalizada.");
        $stop; // Para o simulador
    end

    // Opcional: Monitorar sinais importantes
    initial begin
        // Configura o dump de sinais para visualização no ModelSim (formato .vcd)
        $dumpfile("waveform.vcd");
        // Especifica quais sinais monitorar (nível 0 significa todos os sinais dentro do DUT)
        $dumpvars(0, dut);
    end

endmodule