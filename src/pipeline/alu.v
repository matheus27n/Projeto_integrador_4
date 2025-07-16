module alu (
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [3:0]  alu_op,
    output logic [31:0] result,
    output logic        zero
);
    import alu_pkg::*; // <-- ADICIONE ESTA LINHA
    
    always_comb begin
        case (alu_op)
            ALU_ADD:  result = a + b;
            ALU_SUB:  result = a - b;
            ALU_SLT:  result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            ALU_SLLI: result = a << b[4:0];
            default:  result = 32'hxxxxxxxx;
        endcase
    end
    
    assign zero = (result == 32'b0);
endmodule