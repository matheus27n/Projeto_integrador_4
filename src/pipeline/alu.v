// alu.v - Versão sem localparam
module alu (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [3:0]  alu_control,
    output reg  [31:0] result,
    output wire        zero
);

assign zero = (result == 0);

always @(*) begin
    case (alu_control)
        4'b0000: result = a & b;                    // AND
        4'b0001: result = a | b;                    // OR
        4'b0010: result = a + b;                    // ADD
        4'b0110: result = a - b;                    // SUB
        4'b0111: result = ($signed(a) < $signed(b)) ? 1 : 0; // SLT (com sinal)
        4'b1000: result = a ^ b;                    // XOR
        4'b1001: result = a << b[4:0];              // SLL (Shift Left Logical)
        4'b1010: result = (a < b) ? 1 : 0;          // SLTU (sem sinal)
        4'b1011: result = a >> b[4:0];              // SRL (Shift Right Logical)
        4'b1100: result = $signed(a) >>> b[4:0];    // SRA (Shift Right Arithmetic)
        default: result = 32'hdeadbeef;           // Valor de erro
    endcase
end

endmodule