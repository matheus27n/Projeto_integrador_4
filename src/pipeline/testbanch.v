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

        // Tempo de simulação total
        #500;

        $display("Finalizando simulação...");
        $stop;
    end

    // Monitoramento dos registradores x1 a x4 e PC
    always @(posedge clk) begin
        $display("[Time=%0t] PC=%0h | x1=%0d | x2=%0d | x3=%0d | x4=%0d",
                 $time,
                 pc_out,
                 uut.dp.regfile.registers[1],
                 uut.dp.regfile.registers[2],
                 uut.dp.regfile.registers[3],
                 uut.dp.regfile.registers[4]);
    end

endmodule
