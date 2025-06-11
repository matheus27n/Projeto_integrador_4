// control_unit.v - Versão sem localparam
module control_unit (
    input  wire [6:0]  opcode,
    output reg         RegWrite,
    output reg [1:0]   ResultSrc, // 00=ALU, 01=Mem, 10=Imm(LUI), 11=PC+4(JAL/JALR)
    output reg         MemRead,
    output reg         MemWrite,
    output reg [1:0]   ALUOp,
    output reg         ALUSrc,
    output reg         ALUASrc,   // <-- SAÍDA NOVA
    output reg         Branch,
    output reg [1:0]   Jump      // 00=NoJump, 01=JAL, 10=JALR
);

always @(*) begin
    // Valores Padrão
    RegWrite = 1'b0; ResultSrc = 2'b00; MemRead = 1'b0; MemWrite = 1'b0;
    ALUOp = 2'b00; ALUSrc = 1'b0; ALUASrc = 1'b0; // ALUASrc default é 0 (vem do registrador)
    Branch = 1'b0; Jump = 2'b00;

    case (opcode)
        7'b0110011: begin RegWrite=1; ALUOp=2'b10; end                                    // R-Type
        7'b0010011: begin RegWrite=1; ALUSrc=1; ALUOp=2'b10; end                           // I-Type Aritmético/Lógico
        7'b0000011: begin RegWrite=1; ResultSrc=2'b01; MemRead=1; ALUSrc=1; end           // I-Type Load
        7'b0100011: begin MemWrite=1; ALUSrc=1; end                                       // S-Type
        7'b1100011: begin Branch=1; ALUOp=2'b01; end                                      // B-Type
        7'b1101111: begin RegWrite=1; ResultSrc=2'b11; Jump=2'b01; end                    // JAL
        7'b1100111: begin RegWrite=1; ResultSrc=2'b11; ALUSrc=1; Jump=2'b10; end          // JALR
        7'b0110111: begin RegWrite=1; ResultSrc=2'b10; ALUSrc=1; end                      // LUI
        7'b0010111: begin RegWrite=1; ALUSrc=1; ALUASrc=1; ALUOp=2'b00; end               // AUIPC <-- MUDANÇA AQUI
    endcase
end

endmodule