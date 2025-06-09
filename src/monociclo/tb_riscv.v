`timescale 1ns / 1ps  // Unidade de tempo: 1ns, precisão: 1ps

module tb_riscv();
    reg clk;
    reg reset;
    
    // Instanciação do processador
    riscv_monociclo_topo uut(
        .clk(clk),
        .reset(reset)
    );
    
    // Geração do clock com período de 10ns (50MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // Alterna a cada 5ns (período total = 10ns)
    end
    
    // Sequência de teste em nanosegundos
    initial begin
        // Inicialização
        reset = 1;
        #1;  // 100ns com reset ativo
        
        // Desativa reset
        reset = 0;
        $display("Reset desativado em %t ns", $time);
        
        // Executa por 500ns (50 ciclos de clock)
        #500;
        
        // Finaliza simulação
        $display("Simulação finalizada em %t ns", $time);
        $finish;
    end
    
    initial begin
        $monitor("Tempo: %0t ns | Clock: %b | Reset: %b | PC: %h", 
                 $time, clk, reset, uut.u_parte_operativa.PC);
    end
    
    // Geração do arquivo de onda
    initial begin
        $dumpfile("riscv_wave.vcd");
        $dumpvars(0, tb_riscv);
    end
endmodule