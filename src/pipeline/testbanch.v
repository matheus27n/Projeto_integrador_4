`timescale 1ns / 1ps

module testbench;

    reg clk;
    reg reset;
    wire [31:0] pc_out;

    // Instancia o módulo top
    top uut (
        .clk(clk),
        .reset(reset),
        .pc_out(pc_out)
    );
    
    // --- Geração de Waveform (ESSENCIAL PARA DEPURAÇÃO) ---
    // Isto cria um arquivo .vcd que pode ser aberto no ModelSim para ver as ondas
    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, uut); // O '0' significa dumpar todas as variáveis abaixo de 'uut'
    end

    // Clock: alterna a cada 5ns (100MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Reset e simulação
    initial begin
        $display("Iniciando simulação com teste de hazards e desvios...");

        reset = 1;
        #20;
        reset = 0;

        // Timeout de segurança. A simulação deve parar antes disso.
        #500; 

        $display("Simulação atingiu o TIMEOUT! Verifique se há algum problema.");
        $stop;
    end

    // Monitoramento completo e condição de parada ATUALIZADA
    always @(posedge clk) begin
        // Não imprime nada nos primeiros ciclos de reset
        if ($time > 20) begin
            $display("[Time=%0t] PC=%h | x1=%d, x2=%d, x3=%d, x4=%d | x5(flush)=%d, x6(beq)=%d | x7(jal_link)=%h | x8(flush)=%d, x9(jal)=%d",
                      $time,
                      pc_out,
                      uut.dp.regfile.registers[1],
                      uut.dp.regfile.registers[2],
                      uut.dp.regfile.registers[3],
                      uut.dp.regfile.registers[4],
                      uut.dp.regfile.registers[5],
                      uut.dp.regfile.registers[6],
                      uut.dp.regfile.registers[7],
                      uut.dp.regfile.registers[8],
                      uut.dp.regfile.registers[9]);
        end

        // Parar simulação automaticamente quando x9 (última instrução) for escrito
        if (^uut.dp.regfile.registers[9] !== 1'bx) begin
            #10; // Espera um ciclo extra para o display mostrar o valor final
            $display("======================================================");
            $display("|| SUCESSO! Programa de teste concluído.            ||");
            $display("|| Registrador final x9 carregado com o valor %0d.  ||", uut.dp.regfile.registers[9]);
            $display("======================================================");
            $stop;
        end
    end

endmodule