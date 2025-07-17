// Módulo: top_tb_forwarding.v (NOVO)
`timescale 1ns/1ps

module top_tb_forwarding;

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
        logic [31:0] final_x5_val, final_x6_val, final_x7_val;

        $display("--- Iniciando Teste da Unidade de Forwarding ---");
        
        // Programa de teste com múltiplos hazards RAW (Read-After-Write)
        // addi x5, x0, 10      ; x5 = 10
        // add  x6, x5, x5      ; x6 = 10 + 10 = 20 (hazard em x5)
        // sub  x7, x6, x5      ; x7 = 20 - 10 = 10 (hazard em x6 e x5)
        dut.imem_inst.mem_array[0] = 32'h00A00293; // addi x5, x0, 10
        dut.imem_inst.mem_array[1] = 32'h00528333; // add  x6, x5, x5
        dut.imem_inst.mem_array[2] = 32'h405303B3; // sub  x7, x6, x5

        // Reset
        rst = 1;
        #(CLK_PERIOD * 2);
        rst = 0;
        $display("Reset liberado. Executando programa...");
        
        // Rodar por 10 ciclos para garantir que tudo complete
        #(CLK_PERIOD * 10);
        
        // Acessa os valores finais diretamente do banco de registradores para verificação
        final_x5_val = dut.id_stage_inst.reg_file_inst.registers[5];
        final_x6_val = dut.id_stage_inst.reg_file_inst.registers[6];
        final_x7_val = dut.id_stage_inst.reg_file_inst.registers[7];

        $display("--- Verificação Final dos Registradores ---");
        $display("Valor final em x5: %d (Esperado: 10)", final_x5_val);
        $display("Valor final em x6: %d (Esperado: 20)", final_x6_val);
        $display("Valor final em x7: %d (Esperado: 10)", final_x7_val);

        if (final_x5_val == 10 && final_x6_val == 20 && final_x7_val == 10) begin
            $display("-> SUCESSO! Hazard de dados resolvido por forwarding!");
        end else begin
            $display("-> FALHA! Os valores não estão corretos. O forwarding não funcionou como esperado.");
        end
        
        $display("--- Teste de forwarding concluído ---");
        $finish;
    end
endmodule