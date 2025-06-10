module control_unit (
    input  wire [6:0] opcode,
    output reg        RegWrite,
    output reg        MemRead,
    output reg        MemWrite,
    output reg        MemToReg,
    output reg [1:0]  ALUOp,
    output reg        ALUSrc,
    output reg        Branch,
    output reg        Jump
);

always @(*) begin
    // Default values
    RegWrite = 0;
    MemRead  = 0;
    MemWrite = 0;
    MemToReg = 0;
    ALUOp    = 2'b00;
    ALUSrc   = 0;
    Branch   = 0;
    Jump     = 0;

    case (opcode)
        7'b0110011: begin // R-type
            RegWrite = 1;
            ALUOp    = 2'b10;
        end
        7'b0000011: begin // LW
            RegWrite = 1;
            MemRead  = 1;
            MemToReg = 1;
            ALUSrc   = 1;
        end
        7'b0100011: begin // SW
            MemWrite = 1;
            ALUSrc   = 1;
        end
        7'b1100011: begin // BEQ
            Branch   = 1;
            ALUOp    = 2'b01;
        end
        7'b1101111: begin // JAL
            Jump     = 1;
            RegWrite = 1;
        end
        7'b0010011: begin // I-type (e.g. ADDI)
            RegWrite = 1;
            ALUSrc   = 1;
            ALUOp    = 2'b10;
        end
    endcase
end

endmodule
