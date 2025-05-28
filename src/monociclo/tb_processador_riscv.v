`timescale 1ns / 1ps

module tb_processador_riscv;
    // Entradas
    reg clk;
    reg reset;
    
    // Instanciar o processador
    processador_riscv uut(
        .clk(clk),
        .reset(reset)
    );
    
    // Gerador de clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Procedimento de teste
    initial begin
        // Inicializar
        reset = 1;
        #20;
        reset = 0;
        
        // Aguardar a execução do programa
        #1000;
        
        // Verificar resultados na memória de dados
        $display("Verificando resultados do Quicksort...");
        verificar_ordenacao();
        
        $finish;
    end
    
    // Tarefa para verificar se o array está ordenado
    task verificar_ordenacao;
        integer i;
        reg [31:0] prev_val, curr_val;
        reg ordenado;
        begin
            ordenado = 1;
            prev_val = uut.dmem[0];
            
            for (i = 1; i < 10; i = i + 1) begin
                curr_val = uut.dmem[i];
                if (curr_val < prev_val) begin
                    $display("Erro na posição %d: %d > %d", i-1, prev_val, curr_val);
                    ordenado = 0;
                end
                prev_val = curr_val;
            end
            
            if (ordenado)
                $display("Teste passou: Array está ordenado corretamente!");
            else
                $display("Teste falhou: Array não está ordenado!");
        end
    endtask
    
    // Monitorar registradores e memória
    initial begin
        $monitor("PC=%h Instr=%h x10=%h x11=%h x12=%h", 
                 uut.pc, uut.instr, uut.reg_file[10], uut.reg_file[11], uut.reg_file[12]);
    end
endmodule