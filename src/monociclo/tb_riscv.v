`timescale 1ns / 1ps

module tb_riscv();
    reg clk;
    reg reset;
    
    riscv_monociclo_topo uut(
        .clk(clk),
        .reset(reset)
    );
    
    // Geração do clock (100MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Sequência de teste
    initial begin
        $timeformat(-9, 2, " ns", 10);
        
        reset = 1;
        #15;
        reset = 0;
        #200;
        
        $display("\n=============================================");
        $display("           SIMULAÇÃO FINALIZADA");
        $display("=============================================");
        $finish;
    end
    
    // Função para decodificar a instrução (mantida como antes)
    function string decode_instruction;
        input [31:0] instr;
        reg [4:0] rd, rs1, rs2;
        reg [6:0] opcode;
        reg [2:0] funct3;
        reg [6:0] funct7;
        reg [31:0] imm;
        
        begin
            opcode = instr[6:0]; rd = instr[11:7]; rs1 = instr[19:15]; rs2 = instr[24:20];
            funct3 = instr[14:12]; funct7 = instr[31:25];
            case(opcode)
                7'b0110011: case(funct3) 3'b000: if(funct7==7'b0100000) decode_instruction = $sformatf("sub  x%0d, x%0d, x%0d", rd, rs1, rs2); else decode_instruction = $sformatf("add  x%0d, x%0d, x%0d", rd, rs1, rs2); default: decode_instruction = "R-type unknown"; endcase
                7'b0010011: begin imm = {{20{instr[31]}}, instr[31:20]}; case(funct3) 3'b000: decode_instruction = $sformatf("addi x%0d, x%0d, %d", rd, rs1, $signed(imm)); default: decode_instruction = "I-type unknown"; endcase end
                7'b0000011: begin imm = {{20{instr[31]}}, instr[31:20]}; decode_instruction = $sformatf("lw   x%0d, %d(x%0d)", rd, $signed(imm), rs1); end
                7'b0100011: begin imm = {{20{instr[31]}}, instr[31:25], instr[11:7]}; decode_instruction = $sformatf("sw   x%0d, %d(x%0d)", rs2, $signed(imm), rs1); end
                7'b1100011: begin imm = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0}; decode_instruction = $sformatf("beq  x%0d, x%0d, %d", rs1, rs2, $signed(imm)); end
                7'b1101111: begin imm = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0}; decode_instruction = $sformatf("jal  x%0d, %d", rd, $signed(imm)); end
                default: decode_instruction = "--- NOP / UNKNOWN ---";
            endcase
        end
    endfunction

    //--------------------------------------------------------------------
    // CORREÇÃO FINAL: LOG DIDÁTICO 100% SINCRONIZADO
    //--------------------------------------------------------------------
    integer cycle_count = 0;
    initial begin
      $display("====================================================================================================");
      $display("|| CICLO |   TEMPO   |    PC    | INSTRUÇÃO EXECUTADA         | RESULTADO DO CICLO                   ||");
      $display("====================================================================================================");
    end
    
    // Registradores para guardar um "snapshot" completo do ciclo anterior
    reg [31:0] prev_pc, prev_instr, prev_result, prev_alu_result, prev_rd2;
    reg        prev_reg_write, prev_mem_write, prev_branch, prev_zero, prev_jump;
    reg [31:0] prev_pc_next;

    always @(posedge clk) begin
        if (reset) begin
            cycle_count <= 0;
        end else begin
            // Na borda de subida, o ciclo anterior (em prev_pc) acabou. Vamos reportar sobre ele.
            #1ps; // Espera mínima para garantir que os valores foram atualizados.
            
            $write("|| %5d | %t | %h | %-28s | ", cycle_count, $time, prev_pc, decode_instruction(prev_instr));
            
            // Agora, a lógica de display usa APENAS os valores salvos do ciclo anterior
            if (prev_reg_write && prev_instr[11:7] != 0) begin
                if (prev_jump)
                    $display("x%0d <= %h (endereço de retorno)", prev_instr[11:7], prev_result);
                else
                    $display("x%0d <= %d", prev_instr[11:7], prev_result);
            end else if (prev_mem_write)
                $display("MEM[%h] <= %d", prev_alu_result, prev_rd2);
            else if (prev_branch & prev_zero)
                $display("Branch (BEQ) TOMADO para PC = %h", prev_pc_next);
            else
                $display("Nenhuma escrita ou desvio.");

            cycle_count <= cycle_count + 1;
        end

        // No final de cada ciclo, tiramos um "snapshot" de todos os sinais importantes.
        // Estes valores serão usados na PRÓXIMA iteração para o relatório.
        prev_pc         <= uut.u_parte_operativa.PC;
        prev_instr      <= uut.u_parte_operativa.Instr;
        prev_result     <= uut.u_parte_operativa.Result;
        prev_alu_result <= uut.u_parte_operativa.ALUResult;
        prev_rd2        <= uut.u_parte_operativa.RD2;
        prev_reg_write  <= uut.u_unidade_controle.RegWrite;
        prev_mem_write  <= uut.u_unidade_controle.MemWrite;
        prev_branch     <= uut.u_unidade_controle.Branch;
        prev_zero       <= uut.u_parte_operativa.Zero;
        prev_jump       <= uut.u_unidade_controle.Jump;
        prev_pc_next    <= uut.u_parte_operativa.PCNext;
    end

endmodule