`timescale 1ns / 1ps

// ====================================================================
//                      TESTBENCH - RISC-V Pipeline com Cache
// ====================================================================
// Versao final com monitoramento aprimorado de registradores, memoria
// e do estado interno da cache para depuracao completa.
// ====================================================================

module testbench;

    // === Sinais do processador ===
    reg clk;
    reg reset;
    wire [31:0] pc_if_out;
    wire [31:0] instr_id_out, instr_ex_out, instr_mem_out, instr_wb_out;
    wire        stall_out, flush_out;
    wire        hazard_stall_out;
    wire        cache_stall_out;
    wire        cache_hit_out;
    wire [1:0]  forwardA_out, forwardB_out;
    wire        memwrite_out;
    wire [31:0] memaddr_out, memdata_out;

    // === Instanciacao do Datapath ===
    datapath uut (
        .clk(clk), .reset(reset),
        .o_pc_if(pc_if_out),
        .o_instr_id(instr_id_out), .o_instr_ex(instr_ex_out),
        .o_instr_mem(instr_mem_out), .o_instr_wb(instr_wb_out),
        .o_stall(stall_out),
        .o_hazard_stall(hazard_stall_out),
        .o_cache_stall(cache_stall_out),
        .o_cache_hit(cache_hit_out),
        .o_flush(flush_out),
        .o_forwardA(forwardA_out), .o_forwardB(forwardB_out),
        .o_wb_MemWrite(memwrite_out),
        .o_wb_mem_addr(memaddr_out),
        .o_wb_mem_wdata(memdata_out)
    );

    // === Geracao de Clock, Waveform e Reset ===
    initial begin clk = 0; forever #5 clk = ~clk; end
    initial begin $dumpfile("waveform.vcd"); $dumpvars(0, uut); end
    initial begin $timeformat(-9, 1, " ns", 10); reset = 1; #15; reset = 0; #800; $display("\nSIMULACAO FINALIZADA (TIMEOUT)."); $finish; end

    // ... (A funcao 'decode_instruction' permanece a mesma) ...
    function automatic string decode_instruction (input [31:0] instr); reg [4:0] rd, rs1, rs2; reg [6:0] opcode, funct7; reg [2:0] funct3; reg signed [31:0] imm; begin if (instr == 32'h00000013 || instr == 0) return "--- VAZIO / NOP ---"; opcode = instr[6:0]; rd = instr[11:7]; funct3 = instr[14:12]; rs1 = instr[19:15]; rs2 = instr[24:20]; funct7 = instr[31:25]; case (opcode) 7'b0110011: case (funct3) 3'b000: return funct7[5] ? $sformatf("sub x%0d,x%0d,x%0d", rd, rs1, rs2) : $sformatf("add x%0d,x%0d,x%0d", rd, rs1, rs2); 3'b001: return $sformatf("sll x%0d,x%0d,x%0d", rd, rs1, rs2); 3'b010: return $sformatf("slt x%0d,x%0d,x%0d", rd, rs1, rs2); 3'b011: return $sformatf("sltu x%0d,x%0d,x%0d", rd, rs1, rs2); 3'b100: return $sformatf("xor x%0d,x%0d,x%0d", rd, rs1, rs2); 3'b101: return funct7[5] ? $sformatf("sra x%0d,x%0d,x%0d", rd, rs1, rs2) : $sformatf("srl x%0d,x%0d,x%0d", rd, rs1, rs2); 3'b110: return $sformatf("or x%0d,x%0d,x%0d", rd, rs1, rs2); 3'b111: return $sformatf("and x%0d,x%0d,x%0d", rd, rs1, rs2); default: return "R-type ???"; endcase 7'b0010011: begin imm = $signed(instr[31:20]); case(funct3) 3'b000: return $sformatf("addi x%0d,x%0d,%0d", rd, rs1, imm); 3'b010: return $sformatf("slti x%0d,x%0d,%0d", rd, rs1, imm); 3'b011: return $sformatf("sltiu x%0d,x%0d,%0d", rd, rs1, imm); 3'b100: return $sformatf("xori x%0d,x%0d,%0d", rd, rs1, imm); 3'b110: return $sformatf("ori x%0d,x%0d,%0d", rd, rs1, imm); 3'b111: return $sformatf("andi x%0d,x%0d,%0d", rd, rs1, imm); 3'b001: return $sformatf("slli x%0d,x%0d,%0d", rd, rs1, instr[24:20]); 3'b101: return funct7[5] ? $sformatf("srai x%0d,x%0d,%0d", rd, rs1, instr[24:20]) : $sformatf("srli x%0d,x%0d,%0d", rd, rs1, instr[24:20]); default: return "I-type ???"; endcase end 7'b0000011: begin imm = $signed(instr[31:20]); return $sformatf("lw x%0d,%0d(x%0d)", rd, imm, rs1); end 7'b0100011: begin imm = $signed({instr[31:25], instr[11:7]}); return $sformatf("sw x%0d,%0d(x%0d)", rs2, imm, rs1); end 7'b1100011: begin imm = $signed({{19{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0}); case(funct3) 3'b000: return $sformatf("beq x%0d,x%0d,%0d", rs1, rs2, imm); 3'b001: return $sformatf("bne x%0d,x%0d,%0d", rs1, rs2, imm); 3'b100: return $sformatf("blt x%0d,x%0d,%0d", rs1, rs2, imm); 3'b101: return $sformatf("bge x%0d,x%0d,%0d", rs1, rs2, imm); 3'b110: return $sformatf("bltu x%0d,x%0d,%0d", rs1, rs2, imm); 3'b111: return $sformatf("bgeu x%0d,x%0d,%0d", rs1, rs2, imm); default: return "B-type ???"; endcase end 7'b0110111: begin imm = instr[31:12]; return $sformatf("lui x%0d,0x%h", rd, imm); end 7'b0010111: begin imm = instr[31:12]; return $sformatf("auipc x%0d,0x%h", rd, imm); end 7'b1101111: begin imm = $signed({{11{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0}); return $sformatf("jal x%0d, %0d", rd, imm); end 7'b1100111: begin imm = $signed(instr[31:20]); return $sformatf("jalr x%0d, %0d(x%0d)", rd, imm, rs1); end default: return "--- INSTRUCAO DESCONHECIDA ---"; endcase end endfunction

    // === Monitoramento do Pipeline ===
    integer cycle_count = 0;
    reg [31:0] reg_prev[0:31];
    reg [31:0] mem_prev[0:1023];

    always @(posedge clk) begin
        integer i, changes;
        integer cache_index;

        if (reset) begin
            cycle_count <= 0;
            for (i = 0; i < 32; i = i + 1) reg_prev[i] <= 32'bx;
            for (i = 0; i < 1024; i = i + 1) mem_prev[i] <= 32'bx;
        end else begin
            #1ps;
            
            $display("\n//----------------[ CICLO %0d @ t=%0t ]----------------//", cycle_count, $time);

            $display("EVENTOS DO CICLO:");
            if (hazard_stall_out) $display("  >> STALL! Hazard de Carga-Uso detectado.");
            if (flush_out) $display("  >> FLUSH! Desvio ou salto em andamento.");
            if (forwardA_out != 0 || forwardB_out != 0) $display("  >> FORWARDING! Resultado adiantado para ULA.");
            if (uut.ex_mem_MemRead || uut.ex_mem_MemWrite) begin
                if (cache_hit_out) $display("  >> CACHE HIT! Acesso rapido ao endereco %d.", uut.ex_mem_alu_result);
                else begin
                    $display("  >> CACHE MISS! Buscando da memoria o endereco %d.", uut.ex_mem_alu_result);
                    if(cache_stall_out) $display("  >> STALL! Pipeline parado devido ao Cache Miss.");
                end
            end
            if (!hazard_stall_out && !flush_out && (forwardA_out == 0 && forwardB_out == 0) && !(uut.ex_mem_MemRead || uut.ex_mem_MemWrite)) begin
                $display("  (Nenhum evento especial)");
            end
            
            $display("PIPELINE:");
            $display("  IF : [0x%h] %s", pc_if_out, decode_instruction(uut.imem.memory[pc_if_out >> 2]));
            $display("  ID : [0x%h] %s", uut.if_id_pc, decode_instruction(instr_id_out));
            $display("  EX : [0x%h] %s", uut.id_ex_pc, decode_instruction(instr_ex_out));
            $display("  MEM: [0x%h] %s", uut.ex_mem_pc, decode_instruction(instr_mem_out));
            $display("  WB : [0x%h] %s", uut.mem_wb_pc, decode_instruction(instr_wb_out));

            $display("RESULTADOS (REGISTRADORES):");
            changes = 0;
            for (i = 1; i < 32; i = i + 1) begin
                if (reg_prev[i] !== uut.regfile.registers[i]) begin
                    $display("  >> x%-2d mudou para: %0d (0x%08h)", i, uut.regfile.registers[i], uut.regfile.registers[i]);
                    reg_prev[i] <= uut.regfile.registers[i];
                    changes = 1;
                end
            end
            if (changes == 0) $display("  (Nenhuma mudanca nos registradores)");

            $display("RESULTADOS (MEMORIA):");
            changes = 0;
            if (mem_prev[8] !== uut.main_memory.memory[8]) begin
                $display("  >> Mem[32] mudou para: %d (0x%h)", uut.main_memory.memory[8], uut.main_memory.memory[8]);
                mem_prev[8] <= uut.main_memory.memory[8];
                changes = 1;
            end
            if (mem_prev[264] !== uut.main_memory.memory[264]) begin
                $display("  >> Mem[1056] mudou para: %d (0x%h)", uut.main_memory.memory[264], uut.main_memory.memory[264]);
                mem_prev[264] <= uut.main_memory.memory[264];
                changes = 1;
            end
            if (changes == 0) $display("  (Nenhuma mudanca na memoria)");
            
            // --- NOVO DISPLAY DA CACHE ---
            $display("ESTADO DA CACHE:");
            if (uut.ex_mem_MemRead || uut.ex_mem_MemWrite) begin
                cache_index = uut.ex_mem_alu_result[9:2]; // Pega o índice da cache que está sendo acessado
                $display("  Acesso ao Indice: %d", cache_index);
                $display("    -> Conteudo Atual: Valido: %b | Tag: 0x%h | Dado: %d (0x%h)",
                    uut.dcache.valid_bits[cache_index],
                    uut.dcache.tag_array[cache_index],
                    uut.dcache.data_array[cache_index],
                    uut.dcache.data_array[cache_index]
                );
            end else begin
                $display("  (Nenhum acesso a cache neste ciclo)");
            end
            // -----------------------------

            $display("REGISTRADORES (Dec / Hex):");
            for (i = 0; i < 32; i = i + 4) begin
                $display("  x%-2d: %11d (0x%08h) | x%-2d: %11d (0x%08h) | x%-2d: %11d (0x%08h) | x%-2d: %11d (0x%08h)",
                    i,   uut.regfile.registers[i],   uut.regfile.registers[i],
                    i+1, uut.regfile.registers[i+1], uut.regfile.registers[i+1],
                    i+2, uut.regfile.registers[i+2], uut.regfile.registers[i+2],
                    i+3, uut.regfile.registers[i+3], uut.regfile.registers[i+3]);
            end
            
            cycle_count <= cycle_count + 1;
            
            if (uut.regfile.registers[20] === 100) begin
                #10;
                $display("\n================== FIM DA EXECUCAO ==================");
                $display("||    SUCESSO! Condicao de termino atingida.     ||");
                $display("=====================================================");
                $finish;
            end
        end
    end

endmodule