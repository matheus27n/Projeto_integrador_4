// Módulo: alu_tb.v
// Descrição: Testbench para a Unidade Lógica e Aritmética (alu.v).

`timescale 1ns/1ps // Define a unidade de tempo para a simulação

module alu_tb;

    // Sinais para conectar ao DUT (Device Under Test)
    logic [31:0] a_tb, b_tb;      // Entradas da ULA
    logic [3:0]  alu_op_tb;   // Seletor de operação
    logic [31:0] result_tb;   // Saída da ULA
    logic        zero_tb;     // Saída 'zero' da ULA

    // Parâmetros para facilitar a leitura dos testes.
    // Devem ser os mesmos definidos no alu.v
    localparam ALU_ADD  = 4'b0000;
    localparam ALU_SUB  = 4'b0001;
    localparam ALU_SLT  = 4'b0010;
    localparam ALU_SLLI = 4'b0011;

    // Instanciação do Device Under Test (DUT)
    // Conectando os sinais do testbench às portas do módulo 'alu'
    alu dut (
        .a(a_tb),
        .b(b_tb),
        .alu_op(alu_op_tb),
        .result(result_tb),
        .zero(zero_tb)
    );

    // Bloco de estímulos e verificação
    initial begin
        $display("Iniciando teste da ULA...");
        $monitor("Tempo=%0t | a=%d, b=%d, op=%b | result=%d, zero=%b",
                 $time, a_tb, b_tb, alu_op_tb, result_tb, zero_tb);

        // Teste 1: ADD (10 + 5 = 15)
        a_tb = 10; b_tb = 5; alu_op_tb = ALU_ADD;
        #10; // Espera 10 unidades de tempo (ns) para os valores propagarem

        // Teste 2: SUB (10 - 5 = 5)
        a_tb = 10; b_tb = 5; alu_op_tb = ALU_SUB;
        #10;

        // Teste 3: SUB com resultado negativo (5 - 10 = -5)
        a_tb = 5; b_tb = 10; alu_op_tb = ALU_SUB;
        #10;

        // Teste 4: SUB com resultado zero (10 - 10 = 0, zero flag = 1)
        a_tb = 10; b_tb = 10; alu_op_tb = ALU_SUB;
        #10;

        // Teste 5: SLT (Set Less Than, signed) - Verdadeiro (-1 < 5)
        a_tb = -1; b_tb = 5; alu_op_tb = ALU_SLT;
        #10; // Esperado result = 1

        // Teste 6: SLT - Falso (10 < 5)
        a_tb = 10; b_tb = 5; alu_op_tb = ALU_SLT;
        #10; // Esperado result = 0

        // Teste 7: SLLI (Shift Left Logical) (5 << 2 = 20)
        a_tb = 5; b_tb = 2; alu_op_tb = ALU_SLLI;
        #10;

        $display("Teste da ULA concluído.");
        $finish; // Termina a simulação
    end

endmodule