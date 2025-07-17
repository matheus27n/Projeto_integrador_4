// Módulo: top_tb_ordenacao.v (TESTBENCH FINAL)
// Descrição: Carrega e executa o algoritmo de ordenação completo no processador.
`timescale 1ns/1ps

module top_tb_ordenacao;

    localparam CLK_PERIOD = 10;
    logic clk, rst;

    // Instanciação do DUT (Device Under Test)
    processor_top dut (.*);

    // Geração de Clock
    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    // Estímulos e Verificação
    initial begin
        $display("--- Iniciando Teste Final: Execução do Algoritmo de Ordenação ---");
        
        // --- Carregando o programa de ordenação na memória de instruções ---
        dut.imem_inst.mem_array[0]  = 32'h02000313; // li x6, 32
        dut.imem_inst.mem_array[1]  = 32'h10000393; // li x7, 256
        dut.imem_inst.mem_array[2]  = 32'h00100413; // li x8, 1
        dut.imem_inst.mem_array[3]  = 32'h00642533; // slt x10, x8, x6
        dut.imem_inst.mem_array[4]  = 32'h14050463; // beq x10, x0, 0x158
        dut.imem_inst.mem_array[5]  = 32'h00000493; // li x9, 0
        dut.imem_inst.mem_array[6]  = 32'hfff30513; // addi x10, x6, -1
        dut.imem_inst.mem_array[7]  = 32'h00a4a5b3; // slt x11, x9, x10
        dut.imem_inst.mem_array[8]  = 32'h12058863; // beq x11, x0, 0x150
        dut.imem_inst.mem_array[9]  = 32'h00848633; // add x12, x9, x8
        dut.imem_inst.mem_array[10] = 32'hfff60613; // addi x12, x12, -1
        dut.imem_inst.mem_array[11] = 32'h00c525b3; // slt x11, x10, x12
        dut.imem_inst.mem_array[12] = 32'h00058463; // beq x11, x0, 0x38
        dut.imem_inst.mem_array[13] = 32'h00050613; // addi x12, x10, 0
        dut.imem_inst.mem_array[14] = 32'h00141693; // slli x13, x8, 1
        dut.imem_inst.mem_array[15] = 32'h00d486b3; // add x13, x9, x13
        dut.imem_inst.mem_array[16] = 32'hfff68693; // addi x13, x13, -1
        dut.imem_inst.mem_array[17] = 32'h00d525b3; // slt x11, x10, x13
        dut.imem_inst.mem_array[18] = 32'h00058463; // beq x11, x0, 0x50
        dut.imem_inst.mem_array[19] = 32'h00050693; // addi x13, x10, 0
        dut.imem_inst.mem_array[20] = 32'h00048713; // addi x14, x9, 0
        dut.imem_inst.mem_array[21] = 32'h00000813; // li x16, 0
        dut.imem_inst.mem_array[22] = 32'h00e6a5b3; // slt x11, x13, x14
        dut.imem_inst.mem_array[23] = 32'h02059263; // bne x11, x0, 0x80
        dut.imem_inst.mem_array[24] = 32'h00271893; // slli x17, x14, 2
        dut.imem_inst.mem_array[25] = 32'h0008a903; // lw x18, 0(x17)
        dut.imem_inst.mem_array[26] = 32'h00281893; // slli x17, x16, 2
        dut.imem_inst.mem_array[27] = 32'h011388b3; // add x17, x7, x17
        dut.imem_inst.mem_array[28] = 32'h0128a023; // sw x18, 0(x17)
        dut.imem_inst.mem_array[29] = 32'h00170713; // addi x14, x14, 1
        dut.imem_inst.mem_array[30] = 32'h00180813; // addi x16, x16, 1
        dut.imem_inst.mem_array[31] = 32'hfddff06f; // jal x0, 0x58
        dut.imem_inst.mem_array[32] = 32'h00048713; // addi x14, x9, 0
        dut.imem_inst.mem_array[33] = 32'h00160793; // addi x15, x12, 1
        dut.imem_inst.mem_array[34] = 32'h00048813; // addi x16, x9, 0
        dut.imem_inst.mem_array[35] = 32'h00e625b3; // slt x11, x12, x14
        dut.imem_inst.mem_array[36] = 32'h04059e63; // bne x11, x0, 0xec
        dut.imem_inst.mem_array[37] = 32'h00f6a5b3; // slt x11, x13, x15
        dut.imem_inst.mem_array[38] = 32'h08059063; // bne x11, x0, 0x118
        dut.imem_inst.mem_array[39] = 32'h409708b3; // sub x17, x14, x9
        dut.imem_inst.mem_array[40] = 32'h00289893; // slli x17, x17, 2
        dut.imem_inst.mem_array[41] = 32'h011388b3; // add x17, x7, x17
        dut.imem_inst.mem_array[42] = 32'h0008a903; // lw x18, 0(x17)
        dut.imem_inst.mem_array[43] = 32'h409788b3; // sub x17, x15, x9
        dut.imem_inst.mem_array[44] = 32'h00289893; // slli x17, x17, 2
        dut.imem_inst.mem_array[45] = 32'h011388b3; // add x17, x7, x17
        dut.imem_inst.mem_array[46] = 32'h0008a983; // lw x19, 0(x17)
        dut.imem_inst.mem_array[47] = 32'h0129a5b3; // slt x11, x19, x18
        dut.imem_inst.mem_array[48] = 32'h00059c63; // bne x11, x0, 0xd8
        dut.imem_inst.mem_array[49] = 32'h00281893; // slli x17, x16, 2
        dut.imem_inst.mem_array[50] = 32'h0128a023; // sw x18, 0(x17)
        dut.imem_inst.mem_array[51] = 32'h00170713; // addi x14, x14, 1
        dut.imem_inst.mem_array[52] = 32'h00180813; // addi x16, x16, 1
        dut.imem_inst.mem_array[53] = 32'hfb9ff06f; // jal x0, 0x8c
        dut.imem_inst.mem_array[54] = 32'h00281893; // slli x17, x16, 2
        dut.imem_inst.mem_array[55] = 32'h0138a023; // sw x19, 0(x17)
        dut.imem_inst.mem_array[56] = 32'h00178793; // addi x15, x15, 1
        dut.imem_inst.mem_array[57] = 32'h00180813; // addi x16, x16, 1
        dut.imem_inst.mem_array[58] = 32'hfa5ff06f; // jal x0, 0x8c
        dut.imem_inst.mem_array[59] = 32'h00f6a5b3; // slt x11, x13, x15
        dut.imem_inst.mem_array[60] = 32'h04059a63; // bne x11, x0, 0x144
        dut.imem_inst.mem_array[61] = 32'h409788b3; // sub x17, x15, x9
        dut.imem_inst.mem_array[62] = 32'h00289893; // slli x17, x17, 2
        dut.imem_inst.mem_array[63] = 32'h011388b3; // add x17, x7, x17
        dut.imem_inst.mem_array[64] = 32'h0008a983; // lw x19, 0(x17)
        dut.imem_inst.mem_array[65] = 32'h00281893; // slli x17, x16, 2
        dut.imem_inst.mem_array[66] = 32'h0138a023; // sw x19, 0(x17)
        dut.imem_inst.mem_array[67] = 32'h00178793; // addi x15, x15, 1
        dut.imem_inst.mem_array[68] = 32'h00180813; // addi x16, x16, 1
        dut.imem_inst.mem_array[69] = 32'hfd9ff06f; // jal x0, 0xec
        dut.imem_inst.mem_array[70] = 32'h00e625b3; // slt x11, x12, x14
        dut.imem_inst.mem_array[71] = 32'h02059463; // bne x11, x0, 0x144
        dut.imem_inst.mem_array[72] = 32'h409708b3; // sub x17, x14, x9
        dut.imem_inst.mem_array[73] = 32'h00289893; // slli x17, x17, 2
        dut.imem_inst.mem_array[74] = 32'h011388b3; // add x17, x7, x17
        dut.imem_inst.mem_array[75] = 32'h0008a903; // lw x18, 0(x17)
        dut.imem_inst.mem_array[76] = 32'h00281893; // slli x17, x16, 2
        dut.imem_inst.mem_array[77] = 32'h0128a023; // sw x18, 0(x17)
        dut.imem_inst.mem_array[78] = 32'h00170713; // addi x14, x14, 1
        dut.imem_inst.mem_array[79] = 32'h00180813; // addi x16, x16, 1
        dut.imem_inst.mem_array[80] = 32'hfd9ff06f; // jal x0, 0x118
        dut.imem_inst.mem_array[81] = 32'h00141513; // slli x10, x8, 1
        dut.imem_inst.mem_array[82] = 32'h00a484b3; // add x9, x9, x10
        dut.imem_inst.mem_array[83] = 32'hecdff06f; // jal x0, 0x18
        dut.imem_inst.mem_array[84] = 32'h00141413; // slli x8, x8, 1
        dut.imem_inst.mem_array[85] = 32'heb9ff06f; // jal x0, 0xc
        dut.imem_inst.mem_array[86] = 32'h0000006f; // jal x0, 0
        
        // --- Preparando a memória de dados com um vetor desordenado ---
        // O endereço base é 256 (0x100), conforme 'li x7, 256'
        // Vamos ordenar 10 números.
        dut.dmem_inst.mem_array[256/4 + 0] = 32'd5;
        dut.dmem_inst.mem_array[256/4 + 1] = 32'd2;
        dut.dmem_inst.mem_array[256/4 + 2] = 32'd8;
        dut.dmem_inst.mem_array[256/4 + 3] = 32'd1;
        dut.dmem_inst.mem_array[256/4 + 4] = 32'd9;
        dut.dmem_inst.mem_array[256/4 + 5] = 32'd4;
        dut.dmem_inst.mem_array[256/4 + 6] = 32'd7;
        dut.dmem_inst.mem_array[256/4 + 7] = 32'd3;
        dut.dmem_inst.mem_array[256/4 + 8] = 32'd6;
        dut.dmem_inst.mem_array[256/4 + 9] = 32'd0;

        // Reset
        rst = 1;
        #(CLK_PERIOD * 2);
        rst = 0;
        $display("Reset liberado. Executando o algoritmo...");
        
        // Rodar por tempo suficiente para o algoritmo terminar.
        // Este valor pode precisar de ajuste dependendo da complexidade.
        #(CLK_PERIOD * 5000);
        
        // --- Verificação Final ---
        $display("\n--- Estado Final da Memória de Dados (Endereço 256 em diante) ---");
        for (int i = 0; i < 10; i = i + 1) begin
            $display("Mem[256 + %d*4] = %d", i, dut.dmem_inst.mem_array[256/4 + i]);
        end

        $display("\n--- Teste do algoritmo de ordenação concluído ---");
        $finish;
    end
endmodule