// Módulo: reg_file_tb.v
// Descrição: Testbench para o Banco de Registradores (reg_file.v).

`timescale 1ns/1ps

module reg_file_tb;

    // Parâmetro para o período do clock
    localparam CLK_PERIOD = 10;

    // Sinais para conectar ao DUT
    logic        clk_tb;
    logic        rst_tb;
    logic        we_tb;
    logic [4:0]  rs1_addr_tb;
    logic [4:0]  rs2_addr_tb;
    logic [4:0]  rd_addr_tb;
    logic [31:0] rd_data_tb;
    logic [31:0] rs1_data_tb;
    logic [31:0] rs2_data_tb;

    // Instanciação do Device Under Test (DUT)
    reg_file dut (
        .clk(clk_tb),
        .rst(rst_tb),
        .we(we_tb),
        .rs1_addr(rs1_addr_tb),
        .rs2_addr(rs2_addr_tb),
        .rd_addr(rd_addr_tb),
        .rd_data(rd_data_tb),
        .rs1_data(rs1_data_tb),
        .rs2_data(rs2_data_tb)
    );

    // Geração do Clock
    // O clock começa em 0 e inverte a cada 5ns (metade do período)
    initial begin
        clk_tb = 0;
        forever #(CLK_PERIOD / 2) clk_tb = ~clk_tb;
    end

    // Bloco de estímulos e verificação
    initial begin
        $display("Iniciando teste do Banco de Registradores...");

        // 1. Reset
        rst_tb = 1; // Ativa o reset
        we_tb = 0; // Desabilita escrita durante o reset
        # (CLK_PERIOD * 2); // Mantém o reset por 2 ciclos de clock
        rst_tb = 0; // Desativa o reset
        $display("Reset concluído. Registradores devem estar zerados.");
        #1;

        // 2. Teste de Escrita e Leitura Simples
        $display("Teste 1: Escrevendo 123 no registrador x5...");
        @(posedge clk_tb); // Sincroniza com a borda de subida do clock
        we_tb       = 1;
        rd_addr_tb  = 5;
        rd_data_tb  = 123;
        
        @(posedge clk_tb); // A escrita acontece nesta borda de clock
        we_tb       = 0; // Desabilita a escrita para o próximo ciclo de leitura
        $display("Leitura do x5 (esperado: 123) e x6 (esperado: 0)");
        rs1_addr_tb = 5;
        rs2_addr_tb = 6;
        #1; // Pequeno delay para visualização na onda
        // Os dados lidos (rs1_data_tb, rs2_data_tb) já estarão disponíveis aqui

        // 3. Teste de Leitura Dupla
        $display("Teste 2: Escrevendo 456 no registrador x10...");
        @(posedge clk_tb);
        we_tb       = 1;
        rd_addr_tb  = 10;
        rd_data_tb  = 456;

        @(posedge clk_tb); // A escrita acontece aqui
        we_tb       = 0;
        $display("Leitura simultânea de x5 (123) e x10 (456)");
        rs1_addr_tb = 5;
        rs2_addr_tb = 10;
        #1;

        // 4. Teste do Registrador Zero (x0)
        $display("Teste 3: Tentando escrever 999 no registrador x0 (deve falhar)...");
        @(posedge clk_tb);
        we_tb       = 1;
        rd_addr_tb  = 0;
        rd_data_tb  = 999;

        @(posedge clk_tb); // Tentativa de escrita acontece aqui
        we_tb       = 0;
        $display("Lendo x0 (esperado: 0) e x5 (esperado: 123)");
        rs1_addr_tb = 0;
        rs2_addr_tb = 5;
        #1;

        @(posedge clk_tb); // Apenas para dar um ciclo final
        $display("Todos os testes do Banco de Registradores concluídos.");
        $finish;
    end

    // Monitor para observar os sinais durante a simulação
    initial begin
        $monitor("Tempo=%0t | rst=%b, we=%b, rd_addr=%d, rd_data=%d | rs1_addr=%d -> rs1_data=%d | rs2_addr=%d -> rs2_data=%d",
                 $time, rst_tb, we_tb, rd_addr_tb, rd_data_tb, rs1_addr_tb, rs1_data_tb, rs2_addr_tb, rs2_data_tb);
    end

endmodule