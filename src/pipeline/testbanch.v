`timescale 1ns / 1ps

module testbench;

    // --- Sinais de Conexão com o Processador ---
    reg  clk;
    reg  reset;
    wire [31:0] pc_out;
    wire stall_from_cpu; // Fio para capturar o sinal de stall
    wire flush_from_cpu; // Fio para capturar o sinal de flush

    // --- Instanciação do Módulo Top ---
    top uut (
        .clk(clk),
        .reset(reset),
        .pc_out(pc_out),
        .stall_out(stall_from_cpu), // Conecta a nova saída do top
        .flush_out(flush_from_cpu)  // Conecta a nova saída do top
    );

    // --- Geração de Clock e Reset ---
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $display("===============================================================================");
        $display("||          INICIANDO SIMULAÇÃO COM TESTBENCH DIDÁTICO DE PIPELINE           ||");
        $display("===============================================================================");
        
        reset = 1;
        #20;
        reset = 0;

        #500; 
        $display("Simulação atingiu o TIMEOUT! Verifique se há algum problema.");
        $stop;
    end
    
    // --- Geração de Waveform (VCD) ---
    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, uut); 
    end


    // ============================================================================== //
    //                      LÓGICA DO TESTBENCH DIDÁTICO                              //
    // ============================================================================== //

    // 1. "Memória de Instruções" em formato de texto para o display
        reg [8*40:1] instruction_text [0:255]; 

    initial begin
        for (integer i = 0; i < 256; i = i + 1) instruction_text[i] = "nop";

        // Preenche com o programa de teste ATUALIZADO
        instruction_text[0]  = "lui   x1, 0";
        instruction_text[1]  = "addi  x1, x1, 64";
        instruction_text[2]  = "auipc x2, 0";
        instruction_text[3]  = "slli  x3, x2, 4";
        instruction_text[4]  = "xori  x4, x3, 256";
        instruction_text[5]  = "sltiu x5, x4, 1";
        instruction_text[6]  = "bne   x4, x3, L1(PC=0x24)";
        instruction_text[7]  = "addi  x6, x0, 999 (FLUSHED)";
        instruction_text[8]  = "nop";
        instruction_text[9]  = "L1: jalr x7, 0(x1)";
        instruction_text[10] = "addi  x8, x0, 888 (FLUSHED)";
        instruction_text[11] = "nop";
        instruction_text[12] = "L3_RET: addi x11, x0, 777";
        instruction_text[13] = "nop";

        instruction_text[16] = "L2: addi x9, x0, 111";
        instruction_text[17] = "addi x10, x9, 111";
        instruction_text[18] = "jalr  x0, 0(x7) (return)";
    end

    // 2. Registradores "sombra" para PC e texto da instrução em cada estágio
    reg [31:0] pc_if, pc_id, pc_ex, pc_mem, pc_wb;
    reg [8*40:1] instr_if, instr_id, instr_ex, instr_mem, instr_wb;

    // 3. Lógica do pipeline "sombra" que imita o pipeline real
    always @(posedge clk) begin
        if (reset) begin
            // Reseta todos os estágios para NOP
            pc_if <= 0; instr_if <= "nop";
            pc_id <= 0; instr_id <= "nop";
            pc_ex <= 0; instr_ex <= "nop";
            pc_mem <= 0; instr_mem <= "nop";
            pc_wb <= 0; instr_wb <= "nop";
        end else begin
            // Estágio IF sempre busca a instrução apontada pelo PC
            pc_if <= pc_out;
            instr_if <= instruction_text[pc_out >> 2];

            // Estágio ID avança SE não houver stall
            if (!stall_from_cpu) begin
                pc_id <= pc_if;
                // Se o estágio anterior foi limpo, ID recebe um NOP
                instr_id <= flush_from_cpu ? "--- FLUSHED ---" : instr_if;
            end
            // Se houver stall, ID mantém seu valor anterior (não fazemos nada)

            // Estágio EX sempre avança, mas pode receber uma bolha
            pc_ex <= pc_id;
            // Se houver stall, EX recebe uma bolha (NOP). Senão, recebe de ID.
            instr_ex <= stall_from_cpu ? "--- STALL BUBBLE ---" : instr_id;

            // Estágios MEM e WB sempre avançam
            pc_mem <= pc_ex;
            instr_mem <= instr_ex;

            pc_wb <= pc_mem;
            instr_wb <= instr_mem;
        end
    end
    
    // 4. Lógica de display e checagem final ATUALIZADA
    reg [31:0] reg_prev [0:31];

    always @(posedge clk) begin
        if (reset) begin
            for (integer i = 0; i < 32; i = i + 1) reg_prev[i] <= 32'bx;
        end else begin
            $display("-------------------[ CICLO DE CLOCK @ t=%0t ]-------------------", $time);
            $display("IF : [%h] %s", pc_if, instr_if);
            $display("ID : [%h] %s", pc_id, instr_id);
            $display("EX : [%h] %s", pc_ex, instr_ex);
            $display("MEM: [%h] %s", pc_mem, instr_mem);
            $display("WB : [%h] %s", pc_wb, instr_wb);
            
            for (integer i = 1; i < 12; i = i + 1) begin // Monitora até x11
                if (reg_prev[i] !== uut.dp.regfile.registers[i]) begin
                    $display(">> RESULTADO: Registrador x%0d mudou de %d para %d", i, reg_prev[i], uut.dp.regfile.registers[i]);
                    reg_prev[i] <= uut.dp.regfile.registers[i];
                end
            end
            
            // Condição de parada final ATUALIZADA
            if (uut.dp.regfile.registers[11] === 777) begin
                #10;
                $display("===============================================================================");
                $display("||  SUCESSO! Teste completo do RV32I concluído. Processador funcional!      ||");
                $display("===============================================================================");
                $stop;
            end
        end
    end

endmodule