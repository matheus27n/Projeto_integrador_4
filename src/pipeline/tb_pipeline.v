`timescale 1ns / 1ps

module tb_pipeline();
    reg clk;
    reg reset;

    // Fios para ler os resultados do estágio WB para depuração
    wire [31:0] wb_pc;
    wire [31:0] wb_instruction;
    wire [31:0] wb_write_data;
    wire [4:0]  wb_rd_addr;
    wire        wb_RegWrite;

    // Instancia o processador
    pipeline_topo uut (
        .clk(clk), .reset(reset), .wb_pc(wb_pc), .wb_instruction(wb_instruction),
        .wb_write_data(wb_write_data), .wb_rd_addr(wb_rd_addr), .wb_RegWrite(wb_RegWrite)
    );

    // Geração de clock e reset
    initial begin
        clk = 0; forever #5 clk = ~clk;
    end

    initial begin
        $timeformat(-9, 2, " ns", 10);
        reset = 1; #15; reset = 0;
        
        // CORREÇÃO: Aumentamos o tempo para o programa completo poder rodar
        #400; 
        
        $display("\nSimulação Finalizada.");
        $finish;
    end
    
    // CORREÇÃO: Função de decodificação agora está COMPLETA
    function string decode_instruction;
        input [31:0] instr;
        reg [4:0] rd, rs1, rs2; reg [6:0] opcode; reg [2:0] funct3; reg [6:0] funct7; reg [31:0] imm;
        begin
            opcode = instr[6:0]; rd = instr[11:7]; rs1 = instr[19:15]; rs2 = instr[24:20];
            funct3 = instr[14:12]; funct7 = instr[31:25];
            case(opcode)
                7'b0110011: case(funct3)
                    3'b000: if(funct7[5]) decode_instruction = $sformatf("sub x%0d,x%0d,x%0d", rd,rs1,rs2); else decode_instruction = $sformatf("add x%0d,x%0d,x%0d", rd,rs1,rs2);
                    3'b001: decode_instruction = $sformatf("sll x%0d,x%0d,x%0d", rd,rs1,rs2); 3'b010: decode_instruction = $sformatf("slt x%0d,x%0d,x%0d", rd,rs1,rs2);
                    3'b011: decode_instruction = $sformatf("sltu x%0d,x%0d,x%0d", rd,rs1,rs2); 3'b100: decode_instruction = $sformatf("xor x%0d,x%0d,x%0d", rd,rs1,rs2);
                    3'b101: if(funct7[5]) decode_instruction = $sformatf("sra x%0d,x%0d,x%0d", rd,rs1,rs2); else decode_instruction = $sformatf("srl x%0d,x%0d,x%0d", rd,rs1,rs2);
                    3'b110: decode_instruction = $sformatf("or x%0d,x%0d,x%0d", rd,rs1,rs2); 3'b111: decode_instruction = $sformatf("and x%0d,x%0d,x%0d", rd,rs1,rs2);
                    default: decode_instruction = "R-type Desconhecido"; endcase
                7'b0010011: begin imm = {{20{instr[31]}}, instr[31:20]}; decode_instruction = $sformatf("addi x%0d,x%0d,%d",rd,rs1,$signed(imm)); end
                7'b0000011: begin imm = {{20{instr[31]}}, instr[31:20]}; decode_instruction = $sformatf("lw x%0d,%d(x%0d)",rd,$signed(imm),rs1); end
                7'b0100011: begin imm = {{20{instr[31]}}, instr[31:25], instr[11:7]}; decode_instruction = $sformatf("sw x%0d,%d(x%0d)",rs2,$signed(imm),rs1); end
                7'b1100011: begin imm = {{19{instr[31]}},instr[31],instr[7],instr[30:25],instr[11:8],1'b0}; case(funct3)
                    3'b000: decode_instruction = $sformatf("beq x%0d,x%0d,%d",rs1,rs2,$signed(imm)); 3'b001: decode_instruction = $sformatf("bne x%0d,x%0d,%d",rs1,rs2,$signed(imm));
                    3'b100: decode_instruction = $sformatf("blt x%0d,x%0d,%d",rs1,rs2,$signed(imm)); 3'b101: decode_instruction = $sformatf("bge x%0d,x%0d,%d",rs1,rs2,$signed(imm));
                    3'b110: decode_instruction = $sformatf("bltu x%0d,x%0d,%d",rs1,rs2,$signed(imm)); 3'b111: decode_instruction = $sformatf("bgeu x%0d,x%0d,%d",rs1,rs2,$signed(imm));
                    default: decode_instruction = "Branch Desconhecido"; endcase end
                7'b1101111: begin imm = {{11{instr[31]}},instr[31],instr[19:12],instr[20],instr[30:21],1'b0}; decode_instruction = $sformatf("jal x%0d,%d",rd,$signed(imm)); end
                default: decode_instruction = "--- NOP / UNKNOWN ---";
            endcase
        end
    endfunction

    // LOG DIDÁTICO
    integer cycle_count = 0;
    initial begin
      $display("=======================================================================================");
      $display("|| CICLO |   TEMPO   |    PC    | INSTRUÇÃO COMPLETADA        | RESULTADO               ||");
      $display("=======================================================================================");
    end

    always @(posedge clk) begin // Repórter focado no estágio WB
        if (!reset) begin
            #1ps; 
            if (uut.wb_RegWrite && uut.wb_rd_addr != 0)
                $display("|| %5d | %t | %h | %-28s | x%0d <= %d", cycle_count-4, $time, uut.wb_pc, decode_instruction(uut.wb_instruction), uut.wb_rd_addr, $signed(uut.wb_write_data));
            cycle_count = cycle_count + 1;
        end
    end
endmodule