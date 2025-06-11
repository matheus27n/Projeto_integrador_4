`timescale 1ns / 1ps

module testbench;

    // --- Conexoes com o Processador ---
    reg clk;
    reg reset;
    wire [31:0] pc_if_out;
    wire [31:0] instr_id_out, instr_ex_out, instr_mem_out, instr_wb_out;
    wire        stall_out, flush_out;
    wire [1:0]  forwardA_out, forwardB_out; // Sinais para detectar forwarding
    
    // --- Atalhos para ler Registradores ---
    wire [31:0] x1_val = uut.regfile.registers[1]; wire [31:0] x2_val = uut.regfile.registers[2];
    wire [31:0] x9_val = uut.regfile.registers[9]; wire [31:0] x10_val = uut.regfile.registers[10];
    wire [31:0] x12_val = uut.regfile.registers[12]; wire [31:0] x14_val = uut.regfile.registers[14];
    wire [31:0] x15_val = uut.regfile.registers[15]; wire [31:0] x20_val = uut.regfile.registers[20];

    // --- Instanciacao do Processador ---
    // ATENCAO: Adapte o nome 'datapath' se o seu módulo topo for 'top'
    datapath uut (
        .clk(clk), .reset(reset), .o_pc_if(pc_if_out),
        .o_instr_id(instr_id_out), .o_instr_ex(instr_ex_out),
        .o_instr_mem(instr_mem_out), .o_instr_wb(instr_wb_out),
        .o_stall(stall_out), .o_flush(flush_out),
        .o_forwardA(forwardA_out), .o_forwardB(forwardB_out) // Conecta as novas saidas
    );

    // --- Logica de Clock, Reset e Waveform ---
    initial begin clk = 0; forever #5 clk = ~clk; end
    initial begin $dumpfile("waveform.vcd"); $dumpvars(0, uut); end
    initial begin
        $timeformat(-9, 1, " ns", 10);
        reset = 1; #15; reset = 0;
        #800;
        $display("\nSIMULACAO FINALIZADA (TIMEOUT).");
        $finish;
    end
    
    // --- Funcao de Decodificacao ---
    function automatic string decode_instruction (input [31:0] instr);
        reg [4:0] rd, rs1, rs2; reg [6:0] opcode; reg [2:0] funct3; reg [6:0] funct7; reg signed [31:0] imm;
        if (instr == 32'h00000013 || instr == 0) return "--- VAZIO / NOP ---";
        opcode=instr[6:0]; rd=instr[11:7]; rs1=instr[19:15]; rs2=instr[24:20]; funct3=instr[14:12]; funct7=instr[31:25];
        case(opcode)
            7'b0110011: begin case(funct3) 3'b000: if(funct7[5]) return $sformatf("sub x%0d,x%0d,x%0d", rd,rs1,rs2); else return $sformatf("add x%0d,x%0d,x%0d", rd,rs1,rs2); default: return "R-type ???"; endcase end
            7'b0010011: begin imm = $signed(instr[31:20]); return $sformatf("addi x%0d,x%0d,%d",rd,rs1,imm); end
            7'b0000011: begin imm = $signed(instr[31:20]); return $sformatf("lw x%0d,%d(x%0d)",rd,imm,rs1); end
            7'b0100011: begin imm = $signed({instr[31:25], instr[11:7]}); return $sformatf("sw x%0d,%d(x%0d)",rs2,imm,rs1); end
            7'b1100011: begin imm = $signed({{19{instr[31]}},instr[7],instr[30:25],instr[11:8],1'b0}); if (funct3 == 3'b001) return $sformatf("bne x%0d,x%0d,%d",rs1,rs2,imm); else return $sformatf("beq x%0d,x%0d,%d",rs1,rs2,imm); end
            default: return "--- INSTRUCAO DESCONHECIDA ---";
        endcase
    endfunction

    // --- LOGICA DE DISPLAY DE DIAGNOSTICO ---
    integer cycle_count = 0;
    reg [31:0] reg_prev[0:31];
    always @(posedge clk) begin
        integer i, changes;
        if (reset) begin
            cycle_count <= 0; for (i=0; i<32; i=i+1) reg_prev[i] <= 32'bx;
        end else begin
            #1ps; 
            changes = 0;
            $display("\n//--------------------[ CICLO %0d @ t=%0t ]--------------------//", cycle_count, $time);
            
            $display("EVENTOS DO CICLO:");
            if (stall_out) $display("   >> STALL! Hazard de Carga-Uso detectado. Pipeline congelado.");
            if (flush_out) $display("   >> FLUSH! Desvio ou Salto em andamento. Instrucoes anuladas.");
            if (forwardA_out != 0 || forwardB_out != 0) $display("   >> FORWARDING! Resultado adiantado para a ULA.");
            if (!stall_out && !flush_out && forwardA_out == 0 && forwardB_out == 0) $display("   (Nenhum evento especial neste ciclo)");

            $display("PIPELINE:");
            $display("   IF : [%h] %s", uut.pc, decode_instruction(uut.imem.memory[uut.pc >> 2]));
            $display("   ID : [%h] %s", uut.if_id_pc, decode_instruction(instr_id_out));
            $display("   EX : [%h] %s", uut.id_ex_pc, decode_instruction(instr_ex_out));
            $display("   MEM: [%h] %s", uut.ex_mem_pc, decode_instruction(instr_mem_out));
            $display("   WB : [%h] %s", uut.mem_wb_pc, decode_instruction(instr_wb_out));
            
            $display("RESULTADOS:");
            for (i=1; i<32; i=i+1) if (reg_prev[i] !== uut.regfile.registers[i]) begin
                $display("   >> Registrador x%0d mudou para: %d", i, uut.regfile.registers[i]);
                reg_prev[i] <= uut.regfile.registers[i]; changes = 1; end
            if (changes == 0) $display("   (Nenhuma mudanca nos registradores neste ciclo)");

            cycle_count <= cycle_count + 1;

            if (x20_val === 100) begin
                #10;
                $display("\n======================================================================");
                $display("||          SUCESSO! Teste de Loop e Hazards concluido.             ||");
                $display("======================================================================");
                $finish;
            end
        end
    end
endmodule