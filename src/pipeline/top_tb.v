// Módulo: top_tb.v
// Descrição: Testbench de integração para os estágios IF, ID, EX, e MEM.

`timescale 1ns/1ps

module top_tb;

    localparam CLK_PERIOD = 10;

    // Sinais para o DUT
    logic clk;
    logic rst;
    
    // Fios para observar as saídas de debug
    logic [31:0] dbg_pc_if;
    logic [31:0] dbg_instr_id;
    logic [31:0] dbg_alu_result_ex;
    logic [31:0] dbg_mem_read_data;

    // Instanciação do DUT
    processor_top dut (.*);

    // Geração de Clock
    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    // Estímulos
    initial begin
        $display("Iniciando teste de integração (IF/ID/EX/MEM)...");
        
        // PRÉ-CARGA DOS REGISTRADORES (Isso é necessário para o nosso teste)
        $display("Pré-carregando registradores: x5=200, x6=123");
        dut.id_stage_inst.reg_file_inst.registers[5] = 32'd200;
        dut.id_stage_inst.reg_file_inst.registers[6] = 32'd123;

        // Reset
        rst = 1;
        #(CLK_PERIOD * 2);
        rst = 0;
        $display("Reset liberado. Observando o pipeline...");
        
        // Rodar por 7 ciclos para ver o resultado do LW
        #(CLK_PERIOD * 7);
        
        $display("Teste de integração concluído.");
        $finish;
    end

    // Monitor
    initial begin
        $monitor("Tempo=%0t | PC=%h | INSTR_ID=%h | ALU_Res_EX=%d | MemDataOut=%d",
                 $time, dbg_pc_if, dbg_instr_id, $signed(dbg_alu_result_ex), $signed(dbg_mem_read_data));
    end

endmodule