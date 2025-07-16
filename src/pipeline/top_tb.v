// Módulo: top_tb.v (CORRIGIDO ERRO DE SINTAXE)
`timescale 1ns/1ps

module top_tb;

    localparam CLK_PERIOD = 10;
    logic clk, rst;

    // Instanciação do DUT
    processor_top dut (.*);

    // Geração de Clock
    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    // Estímulos
    initial begin
        // --- DECLARAÇÕES DEVEM VIR PRIMEIRO ---
        logic [31:0] final_x5_val, final_x6_val;

        $display("--- Iniciando Teste Final do Pipeline Completo ---");
        
        // Carrega o programa na memória de instruções
        dut.imem_inst.mem_array[0] = 32'h00A00293; // addi x5, x0, 10
        dut.imem_inst.mem_array[1] = 32'h01428313; // addi x6, x5, 20

        // Reset
        rst = 1;
        #(CLK_PERIOD * 2);
        rst = 0;
        $display("Reset liberado. Executando programa...");
        
        // Rodar por 8 ciclos para garantir que ambas as instruções completem o WB
        #(CLK_PERIOD * 8);
        
        // --- A VERIFICAÇÃO FINAL ---
        // Agora, usamos as variáveis que já foram declaradas
        final_x5_val = dut.id_stage_inst.reg_file_inst.registers[5];
        final_x6_val = dut.id_stage_inst.reg_file_inst.registers[6];

        $display("--- Verificação Final dos Registradores ---");
        $display("Valor final em x5: %d (Esperado: 10)", final_x5_val);
        $display("Valor final em x6: %d", final_x6_val);

        // Análise do resultado de x6
        if (final_x6_val == 30) begin
            $display("-> Resultado de x6 é 30. UAU! (Isso indica que o reg_file lê o valor novo a tempo)");
        end else if (final_x6_val == 20) begin
            $display("-> Resultado de x6 é 20. SUCESSO! (Pipeline funcionou como esperado, mas sofreu o hazard)");
        end else begin
            $display("-> Resultado de x6 é %d. ALGO DEU ERRADO.", final_x6_val);
        end
        
        $display("--- Teste de integração concluído ---");
        $finish;
    end
endmodule