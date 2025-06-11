// alu_control.v - Versão sem localparam
module alu_control (
    input  wire [1:0] ALUOp,
    input  wire [2:0] funct3,
    input  wire [6:0] funct7,
    output reg  [3:0] alu_control
);

always @(*) begin
    case (ALUOp)
        2'b00: alu_control = 4'b0010; // ADD_OP (LW/SW, AUIPC)
        2'b01: begin // Branch
            case(funct3)
                3'b000, 3'b001: alu_control = 4'b0110; // BEQ, BNE -> SUB
                3'b100, 3'b101: alu_control = 4'b0111; // BLT, BGE -> SLT
                3'b110, 3'b111: alu_control = 4'b1010; // BLTU, BGEU -> SLTU
                default: alu_control = 4'bxxxx;
            endcase
        end
        2'b10: begin // Para instruções R-Type e I-Type
            case (funct3)
                3'b000: alu_control = (ALUOp == 2'b10 && funct7[5]) ? 4'b0110 : 4'b0010; // SUB ou ADD/ADDI
                3'b001: alu_control = 4'b1001; // SLL_OP
                3'b010: alu_control = 4'b0111; // SLT_OP
                3'b011: alu_control = 4'b1010; // SLTU_OP
                3'b100: alu_control = 4'b1000; // XOR_OP
                3'b101: alu_control = (funct7[5]) ? 4'b1100 : 4'b1011; // SRA_OP ou SRL_OP
                3'b110: alu_control = 4'b0001; // OR_OP
                3'b111: alu_control = 4'b0000; // AND_OP
                default: alu_control = 4'bxxxx;
            endcase
        end
        default: alu_control = 4'bxxxx;
    endcase
end

endmodule