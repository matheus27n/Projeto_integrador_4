// Módulo: top_tb_final.v (NOVO)
// Descrição: Testbench final que valida o forwarding e o stall de load-use juntos.
`timescale 1ns/1ps

module top_tb_final;

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
        logic [31:0] final_x5, final_x6, final_x7, final_x8;

        $display("--- Iniciando Teste Final do Pipeline (Stall + Forwarding) ---");
        
        // Programa de teste:
        // 1. addi x5, x0, 100    ; x5 = 100
        // 2. sw   x5, 0(x0)      ; Mem[0] = 100
        // 3. lw   x6, 0(x0)      ; x6 = 100
        // 4. add  x7, x6, x1     ; << HAZARD DE LOAD-USE AQUI >> O pipeline deve parar por 1 ciclo. x7 = 100 + 0 = 100
        // 5. sub  x8, x7, x5     ; << FORWARDING AQUI >> x8 = (fwd de x7) - (fwd de x5) = 100 - 100 = 0
        
        dut.imem_inst.mem_array[0] = 32'h06400293; // addi x5, x0, 100
        dut.imem_inst.mem_array[1] = 32'h00500023; // sw   x5, 0(x0)
        dut.imem_inst.mem_array[2] = 32'h00000303; // lw   x6, 0(x0)
        dut.imem_inst.mem_array[3] = 32'h001303B3; // add  x7, x6, x1
        dut.imem_inst.mem_array[4] = 32'h40538433; // sub  x8, x7, x5

        // Reset
        rst = 1;
        #(CLK_PERIOD * 2);
        rst = 0;
        $display("Reset liberado. Executando programa...");
        
        // Rodar por ciclos suficientes para completar
        #(CLK_PERIOD * 15);
        
        // Verificação final
        final_x5 = dut.id_stage_inst.reg_file_inst.registers[5];
        final_x6 = dut.id_stage_inst.reg_file_inst.registers[6];
        final_x7 = dut.id_stage_inst.reg_file_inst.registers[7];
        final_x8 = dut.id_stage_inst.reg_file_inst.registers[8];

        $display("--- Verificação Final dos Registradores ---");
        $display("Valor final em x5: %d (Esperado: 100)", final_x5);
        $display("Valor final em x6: %d (Esperado: 100)", final_x6);
        $display("Valor final em x7: %d (Esperado: 100)", final_x7);
        $display("Valor final em x8: %d (Esperado: 0)",   final_x8);

        if (final_x5 == 100 && final_x6 == 100 && final_x7 == 100 && final_x8 == 0) begin
            $display("-> SUCESSO TOTAL! Pipeline lidou com stall e forwarding corretamente!");
        end else begin
            $display("-> FALHA! Verifique a lógica de integração.");
        end
        
        $display("--- Teste de integração concluído ---");
        $finish;
    end
endmodule
