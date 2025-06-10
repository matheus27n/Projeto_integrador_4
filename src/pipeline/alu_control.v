module alu_control (
    input  wire [1:0] ALUOp,
    input  wire [2:0] funct3,
    input  wire [6:0] funct7,
    output reg  [3:0] alu_control
);

always @(*) begin
    case (ALUOp)
        2'b00: alu_control = 4'b0010; // LW or SW
        2'b01: alu_control = 4'b0110; // BEQ
        2'b10: begin
            case ({funct7[5], funct3})
                4'b0000: alu_control = 4'b0010; // ADD
                4'b1000: alu_control = 4'b0110; // SUB
                4'b0111: alu_control = 4'b0000; // AND
                4'b0110: alu_control = 4'b0001; // OR
                default: alu_control = 4'b1111; // Unknown
            endcase
        end
        default: alu_control = 4'b1111;
    endcase
end

endmodule
