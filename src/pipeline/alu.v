// ========================================================
// Módulo: alu
// Descrição: Unidade Lógica e Aritmética para instruções
//            RISC-V. Executa operações aritméticas, lógicas,
//            shift, comparação com e sem sinal.
// ========================================================
module alu (
    input  wire [31:0] a,             // Operando A
    input  wire [31:0] b,             // Operando B
    input  wire [3:0]  alu_control,   // Código de controle vindo da unidade de controle
    output reg  [31:0] result,        // Resultado da operação
    output wire        zero           // Sinal zero: usado em instruções de branch
);

    // Sinal que indica se o resultado é zero (usado por beq/bne)
    assign zero = (result == 0);

    // Executa a operação baseada no código de controle
    always @(*) begin
        case (alu_control)
            4'b0000: result = a & b;                    // AND
            4'b0001: result = a | b;                    // OR
            4'b0010: result = a + b;                    // ADD
            4'b0110: result = a - b;                    // SUB
            4'b0111: result = ($signed(a) < $signed(b)) ? 1 : 0; // SLT (Signed Less Than)
            4'b1000: result = a ^ b;                    // XOR
            4'b1001: result = a << b[4:0];              // SLL (Logical Left Shift)
            4'b1010: result = (a < b) ? 1 : 0;          // SLTU (Unsigned Less Than)
            4'b1011: result = a >> b[4:0];              // SRL (Logical Right Shift)
            4'b1100: result = $signed(a) >>> b[4:0];    // SRA (Arithmetic Right Shift)
            default: result = 32'b0;                    // NOP/Inválido → zera o resultado
        endcase
    end

endmodule
