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
        4'b0000: result = a & b;       // AND
        4'b0001: result = a | b;       // OR
        4'b0010: result = a + b;       // ADD
        4'b0110: result = a - b;       // SUB
        4'b0111: result = (a < b) ? 1 : 0; // SLT
        4'b1100: result = ~(a | b);    // NOR
        default: result = 0;
    endcase
end

endmodule
