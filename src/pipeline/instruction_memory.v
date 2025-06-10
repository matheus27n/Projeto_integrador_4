module instruction_memory (
    input  wire [31:0] addr,
    output wire [31:0] instruction
);

reg [31:0] memory [0:255]; // 1KB (256 x 32 bits)

assign instruction = memory[addr[9:2]]; // palavra alinhada (word aligned)

initial begin
    // Exemplo de instruções para teste
    memory[0] = 32'h00500093; // addi x1, x0, 5
    memory[1] = 32'h00a00113; // addi x2, x0, 10
    memory[2] = 32'h002081b3; // add x3, x1, x2
    memory[3] = 32'h00302023; // sw x3, 0(x0)
    memory[4] = 32'h00002283; // lw x4, 0(x0)
end

endmodule
