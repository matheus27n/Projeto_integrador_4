// Módulo: hazard_detection_unit_tb.v (NOVO)
// Descrição: Testbench para validar a unidade de detecção de hazard em isolamento.

`timescale 1ns/1ps

module hazard_detection_unit_tb;

    // Sinais para conectar ao DUT
    logic       MemRead_ex_tb;
    logic [4:0] rd_addr_ex_tb;
    logic [4:0] rs1_addr_id_tb;
    logic [4:0] rs2_addr_id_tb;
    logic       stall_pipeline_tb;
    logic       flush_id_ex_tb;

    // Instanciação do Device Under Test (DUT)
    hazard_detection_unit dut (
        .MemRead_ex(MemRead_ex_tb),
        .rd_addr_ex(rd_addr_ex_tb),
        .rs1_addr_id(rs1_addr_id_tb),
        .rs2_addr_id(rs2_addr_id_tb),
        .stall_pipeline(stall_pipeline_tb),
        .flush_id_ex(flush_id_ex_tb)
    );

    // Bloco de estímulos e verificação
    initial begin
        $display("--- Iniciando Teste da Unidade de Detecção de Hazard ---");
        $monitor("Tempo=%0t | MemRead_ex=%b, rd_ex=%d, rs1_id=%d, rs2_id=%d | stall=%b, flush=%b",
                 $time, MemRead_ex_tb, rd_addr_ex_tb, rs1_addr_id_tb, rs2_addr_id_tb, stall_pipeline_tb, flush_id_ex_tb);

        // Teste 1: Sem hazard (instrução em EX não é lw)
        $display("\nTeste 1: Instrução em EX é um 'add'. Esperado: stall=0, flush=0");
        MemRead_ex_tb  = 1'b0;
        rd_addr_ex_tb  = 5'd5;
        rs1_addr_id_tb = 5'd5;
        rs2_addr_id_tb = 5'd6;
        #10;

        // Teste 2: Hazard de Load-Use detectado (dependência em rs1)
        // Simula: lw x10, 0(x1)  (em EX)
        //         add x2, x10, x3 (em ID)
        $display("\nTeste 2: Hazard lw -> add (rs1). Esperado: stall=1, flush=1");
        MemRead_ex_tb  = 1'b1;
        rd_addr_ex_tb  = 5'd10;
        rs1_addr_id_tb = 5'd10;
        rs2_addr_id_tb = 5'd3;
        #10;

        // Teste 3: Hazard de Load-Use detectado (dependência em rs2)
        // Simula: lw x5, 0(x1)   (em EX)
        //         add x2, x3, x5  (em ID)
        $display("\nTeste 3: Hazard lw -> add (rs2). Esperado: stall=1, flush=1");
        MemRead_ex_tb  = 1'b1;
        rd_addr_ex_tb  = 5'd5;
        rs1_addr_id_tb = 5'd3;
        rs2_addr_id_tb = 5'd5;
        #10;

        // Teste 4: Sem hazard (lw para registrador diferente)
        // Simula: lw x7, 0(x1)   (em EX)
        //         add x2, x3, x4  (em ID)
        $display("\nTeste 4: lw para registrador não usado. Esperado: stall=0, flush=0");
        MemRead_ex_tb  = 1'b1;
        rd_addr_ex_tb  = 5'd7;
        rs1_addr_id_tb = 5'd3;
        rs2_addr_id_tb = 5'd4;
        #10;
        
        // Teste 5: Sem hazard (lw escrevendo em x0, que não causa dependência)
        $display("\nTeste 5: lw escrevendo em x0. Esperado: stall=0, flush=0");
        MemRead_ex_tb  = 1'b1;
        rd_addr_ex_tb  = 5'd0;
        rs1_addr_id_tb = 5'd0;
        rs2_addr_id_tb = 5'd1;
        #10;

        $display("\n--- Teste concluído ---");
        $finish;
    end

endmodule