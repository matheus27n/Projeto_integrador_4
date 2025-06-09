`timescale 1ns / 1ps

module tb_riscv();
    reg clk;
    reg reset;
    
    riscv_monociclo_topo uut(
        .clk(clk),
        .reset(reset)
    );
    
    // Geração do clock com período de 10ns (100MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Sequência de teste
    initial begin
        reset = 1;
        #15; // MELHORIA: Reset por 1.5 ciclos é suficiente e seguro.
        
        reset = 0;
        $display("Reset desativado em %t ns", $time);
        
        // Executa por tempo suficiente para o programa de teste
        #200;
        
        $display("Simulação finalizada em %t ns", $time);
        $finish;
    end
    
    // Monitoramento no console
    initial begin
        // MELHORIA: Adicionado o valor dos registradores x1, x2, x3, x4, x5 para depuração
        $monitor("Tempo: %3d ns | PC: %h | x1=%d, x2=%d, x3=%d, x4=%d, x5=%d", 
                 $time/1000, uut.u_parte_operativa.PC,
                 uut.u_parte_operativa.reg_file[1], uut.u_parte_operativa.reg_file[2],
                 uut.u_parte_operativa.reg_file[3], uut.u_parte_operativa.reg_file[4],
                 uut.u_parte_operativa.reg_file[5]);
    end
    
    // Geração do arquivo de onda
    initial begin
        $dumpfile("riscv_wave.vcd");
        $dumpvars(0, uut); // MELHORIA: $dumpvars(0, uut) é mais focado no design
    end
endmodule