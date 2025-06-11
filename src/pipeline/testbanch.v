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

    // Clock: alterna a cada 5ns (100MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Reset e simulação
    initial begin
        $display("Iniciando simulação...");

        reset = 1;
        #20;
        reset = 0;

        #200; // Tempo de simulação mais curto


        $display("Finalizando simulação...");
        $stop;
    end

    // Monitoramento completo
    always @(posedge clk) begin
        $display("[Time=%0t] PC=%0h | x1=%0d | x2=%0d | x3=%0d | x4=%0d | Mem[0]=%0d | mem_read_data=%0d | RegWrite=%b | MemToReg=%b | ID_EX.rd=%0d | EX_MEM.rd=%0d | MEM_WB.rd=%0d",
                 $time,
                 pc_out,
                 uut.dp.regfile.registers[1],
                 uut.dp.regfile.registers[2],
                 uut.dp.regfile.registers[3],
                 uut.dp.regfile.registers[4],
                 uut.dp.dmem.memory[0],
                 uut.dp.mem_read_data,
                 uut.dp.mem_wb_RegWrite,
                 uut.dp.mem_wb_MemToReg,
                 uut.dp.id_ex_rd,
                 uut.dp.ex_mem_rd,
                 uut.dp.mem_wb_rd);

        // Parar simulação automaticamente quando x4 deixar de ser indefinido
        if (^uut.dp.regfile.registers[4] !== 1'bx) begin
            $display("x4 foi carregado com sucesso. Encerrando simulação.");
            $stop;
        end
    end

endmodule
