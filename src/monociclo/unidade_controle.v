`timescale 1ns / 1ps

module unidade_controle(
    input wire [6:0] opcode,
    input wire [2:0] funct3,
    input wire [6:0] funct7,
    output reg [1:0] ALUOp,
    output reg ALUSrc,
    output reg MemtoReg,
    output reg RegWrite,
    output reg MemRead,
    output reg MemWrite,
    output reg Branch,
    output reg Jump,
    output reg [3:0] ALUControl
);
    // Decodificação do opcode
    always @(*) begin
        case(opcode)
            // Instruções do tipo R
            7'b0110011: begin
                ALUSrc = 1'b0;
                MemtoReg = 1'b0;
                RegWrite = 1'b1;
                MemRead = 1'b0;
                MemWrite = 1'b0;
                Branch = 1'b0;
                Jump = 1'b0;
                ALUOp = 2'b10;
            end
            // LW
            7'b0000011: begin
                ALUSrc = 1'b1;
                MemtoReg = 1'b1;
                RegWrite = 1'b1;
                MemRead = 1'b1;
                MemWrite = 1'b0;
                Branch = 1'b0;
                Jump = 1'b0;
                ALUOp = 2'b00;
            end
            // SW
            7'b0100011: begin
                ALUSrc = 1'b1;
                MemtoReg = 1'bx;
                RegWrite = 1'b0;
                MemRead = 1'b0;
                MemWrite = 1'b1;
                Branch = 1'b0;
                Jump = 1'b0;
                ALUOp = 2'b00;
            end
            // BEQ
            7'b1100011: begin
                ALUSrc = 1'b0;
                MemtoReg = 1'bx;
                RegWrite = 1'b0;
                MemRead = 1'b0;
                MemWrite = 1'b0;
                Branch = 1'b1;
                Jump = 1'b0;
                ALUOp = 2'b01;
            end
            // JAL
            7'b1101111: begin
                ALUSrc = 1'bx;
                MemtoReg = 1'b0;
                RegWrite = 1'b1;
                MemRead = 1'b0;
                MemWrite = 1'b0;
                Branch = 1'b0;
                Jump = 1'b1;
                ALUOp = 2'bxx;
            end
            // Operações Imediatas
            7'b0010011: begin
                ALUSrc = 1'b1;
                MemtoReg = 1'b0;
                RegWrite = 1'b1;
                MemRead = 1'b0;
                MemWrite = 1'b0;
                Branch = 1'b0;
                Jump = 1'b0;
                ALUOp = 2'b10;
            end
            default: begin
                ALUSrc = 1'bx;
                MemtoReg = 1'bx;
                RegWrite = 1'b0;
                MemRead = 1'b0;
                MemWrite = 1'b0;
                Branch = 1'b0;
                Jump = 1'b0;
                ALUOp = 2'bxx;
            end
        endcase
    end
    
    // Decodificação da ALU
    always @(*) begin
        case(ALUOp)
            2'b00: ALUControl = 4'b0010; // ADD
            2'b01: ALUControl = 4'b0110; // SUB
            2'b10: begin
                case(funct3)
                    3'b000: 
                        if (opcode == 7'b0110011 && funct7[5] == 1'b1)
                            ALUControl = 4'b0110; // SUB
                        else
                            ALUControl = 4'b0010; // ADD
                    3'b110: ALUControl = 4'b0001; // OR
                    3'b111: ALUControl = 4'b0000; // AND
                    3'b001: ALUControl = 4'b0011; // SLL
                    3'b101: ALUControl = 4'b0101; // SRL
                    default: ALUControl = 4'bxxxx;
                endcase
            end
            default: ALUControl = 4'bxxxx;
        endcase
    end
endmodule