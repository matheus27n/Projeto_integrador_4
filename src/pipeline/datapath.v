/**
 * @file datapath.v
 * @brief Módulo do datapath para um processador RISC-V de 5 estágios (pipeline).
 * @details Este módulo implementa a estrutura principal do processador, incluindo os estágios de
 * Busca (IF), Decodificação (ID), Execução (EX), Acesso à Memória (MEM) e Escrita (WB).
 * Inclui também a lógica de forwarding e detecção de hazards.
 */
`timescale 1ns / 1ps

module datapath (
    // --- Entradas ---
    input  wire        clk,            // Sinal de clock principal do sistema.
    input  wire        reset,          // Sinal de reset (ativo alto) para inicializar o processador.

    // --- Saídas de Depuração ---
    output wire [31:0] o_pc_if,        // Valor do PC (Program Counter) no estágio de Busca (IF).
    output wire [31:0] o_instr_id,     // Instrução no estágio de Decodificação (ID).
    output wire [31:0] o_instr_ex,     // Instrução no estágio de Execução (EX).
    output wire [31:0] o_instr_mem,    // Instrução no estágio de Memória (MEM).
    output wire [31:0] o_instr_wb,     // Instrução no estágio de Escrita (WB).
    output wire        o_stall,        // Sinaliza a parada (stall) do pipeline (1 = stall).
    output wire        o_flush,        // Sinaliza a limpeza (flush) do pipeline (1 = flush).
    output wire [1:0]  o_forwardA,     // Sinal de controle do forwarding para o operando A da ULA.
    output wire [1:0]  o_forwardB,     // Sinal de controle do forwarding para o operando B da ULA.
    output wire        o_wb_MemWrite,  // Sinal de escrita na memória (propagado até o estágio WB).
    output wire [31:0] o_wb_mem_addr,  // Endereço de acesso à memória (do estágio WB).
    output wire [31:0] o_wb_mem_wdata  // Dado a ser escrito na memória (propagado até o estágio WB).
);

    // =================================================================================
    // 🧠 Declaração Centralizada de Sinais Internos
    // =================================================================================

    // --- Sinais Gerais e de Controle ---
    wire        stall;                 // Ativado pela Unidade de Hazard para parar o pipeline.
    wire        flush;                 // Ativado quando um desvio é tomado para limpar estágios anteriores.
    wire        RegWrite, MemRead, MemWrite, ALUSrc, ALUASrc, Branch; // Sinais da Unidade de Controle.
    wire [1:0]  ResultSrc, ALUOp, Jump; // Sinais de múltiplos bits da Unidade de Controle.
    reg  [31:0] pc;                    // Contador de Programa (Program Counter).
    wire [31:0] pc_plus_4;             // Endereço da próxima instrução sequencial.
    wire [31:0] pc_next;               // Endereço do próximo PC (pode ser PC+4, branch, ou jump).
    wire [31:0] instr;                 // Instrução lida da memória de instruções.
    wire [31:0] reg_data1, reg_data2;  // Dados lidos do banco de registradores (rs1, rs2).
    wire [31:0] imm;                   // Valor do imediato de 32 bits, estendido pelo ImmGen.
    wire [3:0]  alu_control_out;       // Código da operação para a ULA (gerado pela ALU Control).
    wire [1:0]  forwardA, forwardB;    // Sinais da Unidade de Forwarding.
    wire [31:0] operandA, operandB;    // Operandos de entrada para a ULA (após mux de forwarding).
    wire [31:0] alu_input_b;           // Segunda entrada da ULA (pode ser registrador ou imediato).
    wire [31:0] alu_result;            // Resultado da ULA principal.
    wire        alu_zero;              // Flag 'zero' da ULA principal (usada em desvios).
    wire [1:0]  pc_sel;                // Sinal para selecionar a fonte do próximo PC.
    wire        branch_cond;           // Resultado da condição de desvio (1 = tomar desvio).
    wire [31:0] branch_addr;           // Endereço de destino para desvios condicionais.
    wire [31:0] jump_addr;             // Endereço de destino para JAL.
    wire [31:0] jalr_addr;             // Endereço de destino para JALR.
    wire [31:0] mem_read_data;         // Dado lido da memória de dados.
    wire [31:0] wb_data;               // Dado final a ser escrito no banco de registradores.
    reg         reset_done;            // Flag para controlar o estado inicial após o reset.
    wire [31:0] branch_alu_result;     // Resultado da ULA de desvio.
    wire        branch_alu_zero;       // Flag 'zero' da ULA de desvio.
    wire [31:0] alu_a_mux_in;          // Entrada para o MUX do operando A, antes do forwarding.

    // --- Sinais do Pipeline IF/ID ---
    reg  [31:0] if_id_pc;              // PC do estágio IF, armazenado para o estágio ID.
    reg  [31:0] if_id_instr;           // Instrução do estágio IF, armazenada para o estágio ID.
    reg  [31:0] if_id_pc_plus_4;       // PC+4 do estágio IF, armazenado para o estágio ID.
    wire [6:0]  opcode = if_id_instr[6:0];   // Decodificação dos campos da instrução em ID.
    wire [4:0]  rs1    = if_id_instr[19:15];
    wire [4:0]  rs2    = if_id_instr[24:20];
    wire [4:0]  rd     = if_id_instr[11:7];
    wire [2:0]  funct3 = if_id_instr[14:12];
    wire [6:0]  funct7 = if_id_instr[31:25];

    // --- Sinais do Pipeline ID/EX ---
    reg         id_ex_RegWrite, id_ex_MemRead, id_ex_MemWrite, id_ex_ALUSrc, id_ex_ALUASrc, id_ex_Branch;
    reg  [1:0]  id_ex_ResultSrc, id_ex_ALUOp, id_ex_Jump;
    reg  [31:0] id_ex_pc, id_ex_pc_plus_4, id_ex_reg_data1, id_ex_reg_data2, id_ex_imm, id_ex_instr;
    reg  [4:0]  id_ex_rs1, id_ex_rs2, id_ex_rd;
    reg  [2:0]  id_ex_funct3;
    reg  [6:0]  id_ex_funct7;

    // --- Sinais do Pipeline EX/MEM ---
    reg         ex_mem_RegWrite, ex_mem_MemRead, ex_mem_MemWrite;
    reg  [1:0]  ex_mem_ResultSrc;
    reg  [31:0] ex_mem_pc, ex_mem_pc_plus_4, ex_mem_alu_result, ex_mem_write_data, ex_mem_imm, ex_mem_instr;
    reg  [4:0]  ex_mem_rd;

    // --- Sinais do Pipeline MEM/WB ---
    reg         mem_wb_RegWrite;
    reg  [1:0]  mem_wb_ResultSrc;
    reg  [31:0] mem_wb_pc, mem_wb_pc_plus_4, mem_wb_mem_data, mem_wb_alu_result, mem_wb_imm, mem_wb_instr;
    reg  [4:0]  mem_wb_rd;
    reg         mem_wb_MemWrite;       // Sinal de controle de escrita na memória, propagado para WB.
    reg  [31:0] mem_wb_mem_wdata;      // Dado de escrita na memória, propagado para WB.


    // =================================================================================
    // ➡️ Estágio 1: IF (Busca da Instrução)
    // =================================================================================

    // Lógica para calcular o endereço da próxima instrução (PC + 4).
    assign pc_plus_4 = pc + 4;
    // O sinal 'flush' é ativado se a fonte do próximo PC não for PC+4 (ou seja, um desvio ou salto ocorreu).
    assign flush = (pc_sel != 2'b00);

    // Instancia a memória de instruções, que busca a instrução no endereço 'pc'.
    instruction_memory imem (
        .addr(pc), 
        .instruction(instr)
    );

    // Bloco always para controlar a atualização do Program Counter (PC).
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc         <= 32'h0;
            reset_done <= 1'b0;
        end else if (!reset_done) begin // Garante que o PC permaneça em 0 no primeiro ciclo pós-reset.
            reset_done <= 1'b1;
            pc         <= 32'h0;
        end else if (~stall) begin // O PC só avança se o pipeline não estiver em stall.
            pc <= pc_next;
        end
    end

    // MUX para selecionar o próximo valor do PC.
    assign pc_next = (pc_sel == 2'b01) ? branch_addr : // Desvio condicional (branch)
                     (pc_sel == 2'b10) ? jump_addr   : // Salto incondicional (JAL)
                     (pc_sel == 2'b11) ? jalr_addr   : // Salto com registrador (JALR)
                                         pc_plus_4;    // Padrão: próxima instrução sequencial.

    // Registrador de Pipeline IF/ID: armazena os dados do estágio IF para o ID.
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            if_id_pc        <= 32'h0;
            if_id_instr     <= 32'h00000013; // NOP (addi x0, x0, 0) para limpar o pipeline.
            if_id_pc_plus_4 <= 32'h0;
        end else if (~stall) begin // Se houver stall, os valores deste registrador são congelados.
            if (flush) begin // Se um flush ocorrer, insere um NOP no pipeline.
                if_id_pc        <= 32'h0;
                if_id_instr     <= 32'h00000013; // NOP
                if_id_pc_plus_4 <= 32'h0;
            end else begin // Em operação normal, passa os valores do estágio IF para o ID.
                if_id_pc        <= pc;
                if_id_instr     <= reset_done ? instr : 32'h00000013; // Garante NOP no primeiro ciclo.
                if_id_pc_plus_4 <= pc_plus_4;
            end
        end
    end

    // =================================================================================
    // ➡️ Estágio 2: ID (Decodificação e Leitura de Registradores)
    // =================================================================================

    // Instancia o Banco de Registradores.
    register_file regfile (
        .clk(clk), 
        .RegWrite(mem_wb_RegWrite),   // Sinal de escrita vem do estágio WB.
        .rs1(rs1), 
        .rs2(rs2), 
        .rd(mem_wb_rd),             // Endereço de escrita vem do estágio WB.
        .write_data(wb_data),         // Dado de escrita vem do estágio WB.
        .read_data1(reg_data1), 
        .read_data2(reg_data2)
    );

    // Instancia a Unidade de Controle principal, que gera os sinais de controle a partir do opcode.
    control_unit ctrl (
        .opcode(opcode),
        .RegWrite(RegWrite), .ResultSrc(ResultSrc),
        .MemRead(MemRead),   .MemWrite(MemWrite),
        .ALUSrc(ALUSrc),     .ALUASrc(ALUASrc),
        .ALUOp(ALUOp),       .Branch(Branch),   
        .Jump(Jump)
    );

    // Instancia o Gerador de Imediatos, que estende o campo imediato da instrução para 32 bits.
    imm_gen immediate_generator (
        .instruction(if_id_instr), 
        .opcode(opcode), 
        .imm(imm)
    );

    // Instancia a Unidade de Detecção de Hazards, que gera o sinal 'stall' em caso de dependência de dados do tipo load-use.
    hazard_unit hazard (
        .id_ex_MemRead(id_ex_MemRead), // Se a instrução em EX é um load.
        .id_ex_rd(id_ex_rd),           // Registrador de destino da instrução em EX.
        .if_id_rs1(rs1),               // Registrador fonte da instrução em ID.
        .if_id_rs2(rs2),               // Registrador fonte da instrução em ID.
        .stall(stall)                  // Saída que sinaliza a necessidade de stall.
    );

    // Registrador de Pipeline ID/EX: armazena os dados e sinais de controle do estágio ID para o EX.
    always @(posedge clk or posedge reset) begin
        if (reset || stall || flush) begin // Limpa o registrador ou insere NOP em caso de reset, stall ou flush.
            id_ex_RegWrite <= 1'b0; id_ex_ResultSrc <= 2'b0; id_ex_MemRead <= 1'b0;
            id_ex_MemWrite <= 1'b0; id_ex_Branch    <= 1'b0; id_ex_Jump    <= 2'b0;
            id_ex_ALUSrc   <= 1'b0; id_ex_ALUASrc   <= 1'b0; id_ex_ALUOp   <= 2'b0;
            id_ex_instr    <= 32'h00000013; // Injeta NOP explícito.
            id_ex_pc <= 0; id_ex_pc_plus_4 <= 0; id_ex_reg_data1 <= 0; id_ex_reg_data2 <= 0;
            id_ex_imm <= 0; id_ex_rs1 <= 0; id_ex_rs2 <= 0; id_ex_rd <= 0;
            id_ex_funct3 <= 0; id_ex_funct7 <= 0;
        end else begin // Em operação normal, passa os sinais e dados do estágio ID para o EX.
            id_ex_RegWrite <= RegWrite; id_ex_ResultSrc <= ResultSrc; id_ex_MemRead <= MemRead;
            id_ex_MemWrite <= MemWrite; id_ex_Branch    <= Branch;    id_ex_Jump    <= Jump;
            id_ex_ALUSrc   <= ALUSrc;   id_ex_ALUASrc   <= ALUASrc;   id_ex_ALUOp   <= ALUOp;
            id_ex_pc <= if_id_pc; id_ex_pc_plus_4 <= if_id_pc_plus_4;
            id_ex_reg_data1 <= reg_data1; id_ex_reg_data2 <= reg_data2;
            id_ex_imm <= imm; id_ex_instr <= if_id_instr;
            id_ex_rs1 <= rs1; id_ex_rs2 <= rs2; id_ex_rd <= rd;
            id_ex_funct3 <= funct3; id_ex_funct7 <= funct7;
        end
    end

    // =================================================================================
    // ➡️ Estágio 3: EX (Execução)
    // =================================================================================
    
    // Instancia a Unidade de Controle da ULA, que define a operação da ULA a partir do ALUOp, funct3 e funct7.
    alu_control alu_ctrl_unit (
        .ALUOp(id_ex_ALUOp), 
        .funct3(id_ex_funct3), 
        .funct7(id_ex_funct7), 
        .alu_control(alu_control_out)
    );

    // Instancia a Unidade de Forwarding para resolver hazards de dados, evitando stalls desnecessários.
    forwarding_unit fwd (
        .id_ex_rs1(id_ex_rs1), .id_ex_rs2(id_ex_rs2), 
        .ex_mem_rd(ex_mem_rd), .mem_wb_rd(mem_wb_rd),
        .ex_mem_RegWrite(ex_mem_RegWrite), 
        .mem_wb_RegWrite(mem_wb_RegWrite), 
        .forwardA(forwardA), .forwardB(forwardB)
    );

    // MUX para o primeiro operando da ULA (OperandA), considerando forwarding.
    assign alu_a_mux_in = (id_ex_ALUASrc) ? id_ex_pc : id_ex_reg_data1;
    assign operandA = (forwardA == 2'b10) ? ex_mem_alu_result : // Forward do estágio MEM (EX -> EX)
                      (forwardA == 2'b01) ? wb_data           : // Forward do estágio WB (MEM -> EX)
                                            alu_a_mux_in;

    // MUX para o segundo operando da ULA (OperandB), considerando forwarding.
    assign operandB = (forwardB == 2'b10) ? ex_mem_alu_result : // Forward do estágio MEM (EX -> EX)
                      (forwardB == 2'b01) ? wb_data           : // Forward do estágio WB (MEM -> EX)
                                            id_ex_reg_data2;

    // MUX final para a segunda entrada da ULA, que escolhe entre o operando B e o imediato.
    assign alu_input_b = (id_ex_ALUSrc) ? id_ex_imm : operandB;
    
    // ULA principal: executa a operação aritmética/lógica.
    alu alu_main (
        .a(operandA), .b(alu_input_b), 
        .alu_control(alu_control_out), 
        .result(alu_result), .zero(alu_zero)
    );

    // --- Lógica de Desvio e Salto ---
    // ULA dedicada para desvios, para garantir a comparação correta entre registradores.
    alu branch_alu (
        .a(operandA), .b(operandB), 
        .alu_control(alu_control_out),
        .result(branch_alu_result), .zero(branch_alu_zero)
    );

    // Lógica para determinar se a condição de desvio é atendida.
    assign branch_cond = (id_ex_Branch) &
                         ( (id_ex_funct3 == 3'b000 && branch_alu_zero)      || // beq
                           (id_ex_funct3 == 3'b001 && ~branch_alu_zero)     || // bne
                           (id_ex_funct3 == 3'b100 && branch_alu_result == 1) || // blt
                           (id_ex_funct3 == 3'b101 && branch_alu_result == 0) || // bge
                           (id_ex_funct3 == 3'b110 && branch_alu_result == 1) || // bltu
                           (id_ex_funct3 == 3'b111 && branch_alu_result == 0) ); // bgeu

    // Cálculo dos endereços de destino.
    assign branch_addr = id_ex_pc + id_ex_imm;
    assign jump_addr   = id_ex_pc + id_ex_imm;
    assign jalr_addr   = operandA + id_ex_imm;

    // Seleciona a fonte do próximo PC com base nos sinais de salto e desvio.
    assign pc_sel = (id_ex_Jump == 2'b01) ? 2'b10 : // JAL
                    (id_ex_Jump == 2'b10) ? 2'b11 : // JALR
                    (branch_cond)         ? 2'b01 : // Branch
                                            2'b00 ; // PC+4


    // =================================================================================
    // ➡️ Estágio 4: MEM (Acesso à Memória)
    // =================================================================================

    // Registrador de Pipeline EX/MEM: armazena os dados do estágio EX para o MEM.
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            {ex_mem_RegWrite, ex_mem_ResultSrc, ex_mem_MemRead, ex_mem_MemWrite} <= 0;
            {ex_mem_pc, ex_mem_pc_plus_4, ex_mem_alu_result, ex_mem_write_data, ex_mem_imm, ex_mem_instr, ex_mem_rd} <= 0;
        end else begin
            {ex_mem_RegWrite, ex_mem_ResultSrc, ex_mem_MemRead, ex_mem_MemWrite} <=
                {id_ex_RegWrite, id_ex_ResultSrc, id_ex_MemRead, id_ex_MemWrite};
            {ex_mem_pc, ex_mem_pc_plus_4, ex_mem_alu_result, ex_mem_write_data, ex_mem_imm, ex_mem_instr, ex_mem_rd} <=
                {id_ex_pc, id_ex_pc_plus_4, alu_result, operandB, id_ex_imm, id_ex_instr, id_ex_rd};
        end
    end

    // Instancia a Memória de Dados.
    data_memory dmem (
        .clk(clk), 
        .MemRead(ex_mem_MemRead),       // Sinal de controle para leitura.
        .MemWrite(ex_mem_MemWrite),     // Sinal de controle para escrita.
        .addr(ex_mem_alu_result),       // Endereço de acesso (calculado pela ULA).
        .write_data(ex_mem_write_data), // Dado a ser escrito (vem do registrador rs2).
        .read_data(mem_read_data)       // Dado lido da memória.
    );

    // Registrador de Pipeline MEM/WB: armazena os dados do estágio MEM para o WB.
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            {mem_wb_RegWrite, mem_wb_ResultSrc} <= 0;
            {mem_wb_pc, mem_wb_pc_plus_4, mem_wb_mem_data, mem_wb_alu_result, mem_wb_imm, mem_wb_instr, mem_wb_rd} <= 0;
            // Zera também os sinais auxiliares.
            mem_wb_MemWrite  <= 1'b0;
            mem_wb_mem_wdata <= 32'b0;
        end else begin
            {mem_wb_RegWrite, mem_wb_ResultSrc} <= {ex_mem_RegWrite, ex_mem_ResultSrc};
            {mem_wb_pc, mem_wb_pc_plus_4, mem_wb_mem_data, mem_wb_alu_result, mem_wb_imm, mem_wb_instr, mem_wb_rd} <=
                {ex_mem_pc, ex_mem_pc_plus_4, mem_read_data, ex_mem_alu_result, ex_mem_imm, ex_mem_instr, ex_mem_rd};
            //ARRUMAR BUG// Propaga os sinais de escrita da memória, que antes não eram conectados (correção de bug).
            mem_wb_MemWrite  <= ex_mem_MemWrite;
            mem_wb_mem_wdata <= ex_mem_write_data;
        end
    end

    // =================================================================================
    // ➡️ Estágio 5: WB (Escrita de Volta)
    // =================================================================================

    // MUX para selecionar o dado final que será escrito de volta no banco de registradores.
    assign wb_data = (mem_wb_ResultSrc == 2'b01) ? mem_wb_mem_data  : // Origem: Memória de Dados (LW).
                     (mem_wb_ResultSrc == 2'b10) ? mem_wb_imm       : // Origem: Imediato (LUI).
                     (mem_wb_ResultSrc == 2'b11) ? mem_wb_pc_plus_4 : // Origem: PC+4 (JAL, JALR).
                                                   mem_wb_alu_result; // Origem Padrão: Resultado da ULA.


    // =================================================================================
    // 🛰️ Atribuição das Saídas do Módulo
    // =================================================================================
    // Conecta os sinais internos às portas de saída para depuração e monitoramento externo.
    assign o_pc_if        = pc;
    assign o_instr_id     = if_id_instr;
    assign o_instr_ex     = id_ex_instr;
    assign o_instr_mem    = ex_mem_instr;
    assign o_instr_wb     = mem_wb_instr;
    assign o_stall        = stall;
    assign o_flush        = flush;
    assign o_forwardA     = forwardA;
    assign o_forwardB     = forwardB;
    assign o_wb_MemWrite  = mem_wb_MemWrite;
    assign o_wb_mem_addr  = mem_wb_alu_result;
    assign o_wb_mem_wdata = mem_wb_mem_wdata;

endmodule