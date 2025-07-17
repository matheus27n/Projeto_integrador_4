/**
 * @file datapath.v
 * @brief Módulo do datapath para um processador RISC-V de 5 estágios (IF, ID, EX, MEM, WB)
 * @details 
 *   - Implementa o caminho de dados completo com pipeline de 5 estágios
 *   - Trata hazards estruturais, de dados e de controle
 *   - Inclui unidade de forwarding e detecção de hazards
 *   - Interface com memória de instruções e cache de dados
 *   - Prioridade correta de reset sobre condições de stall
 */

`timescale 1ns / 1ps

module datapath (
    // --- Clock e Reset ---
    input  wire         clk,     // Clock principal
    input  wire         reset,   // Sinal de reset assíncrono

    // --- Saídas de Depuração ---
    output wire [31:0]  o_pc_if,         // Valor atual do PC no estágio IF
    output wire [31:0]  o_instr_id,      // Instrução no estágio ID
    output wire [31:0]  o_instr_ex,      // Instrução no estágio EX
    output wire [31:0]  o_instr_mem,     // Instrução no estágio MEM
    output wire [31:0]  o_instr_wb,      // Instrução no estágio WB
    output wire         o_stall,         // Sinal de stall ativo
    output wire         o_hazard_stall,  // Stall por hazard de dados
    output wire         o_cache_stall,   // Stall por cache miss
    output wire         o_cache_hit,     // Indica hit na cache
    output wire         o_flush,         // Sinal de flush do pipeline
    output wire [1:0]   o_forwardA,      // Sinal de forwarding para operando A
    output wire [1:0]   o_forwardB,      // Sinal de forwarding para operando B
    output wire         o_wb_MemWrite,   // Sinal de escrita na memória no WB
    output wire [31:0]  o_wb_mem_addr,   // Endereço de memória no WB
    output wire [31:0]  o_wb_mem_wdata   // Dado para escrita na memória no WB
);

    // =====================================================================
    // 1. DECLARAÇÃO DE SINAIS INTERNOS
    // =====================================================================

    // --- Sinais de Controle Gerais ---
    wire        stall;            // Stall global do pipeline
    wire        flush;            // Flush do pipeline (descartar instruções)
    reg  [31:0] pc;               // Contador de programa
    wire [31:0] pc_plus_4;        // PC + 4 (próxima instrução sequencial)
    wire [31:0] pc_next;          // Próximo valor do PC (pode ser desvio)

    // --- Sinais de Estágio IF ---
    wire [31:0] instr;            // Instrução lida da memória

    // --- Sinais de Estágio ID ---
    wire [31:0] reg_data1;        // Dado lido do registrador 1
    wire [31:0] reg_data2;        // Dado lido do registrador 2
    wire [31:0] imm;              // Valor imediato extendido
    wire [6:0]  opcode;           // Campo opcode da instrução
    wire [4:0]  rs1;              // Registrador fonte 1
    wire [4:0]  rs2;              // Registrador fonte 2
    wire [4:0]  rd;               // Registrador destino
    wire [2:0]  funct3;           // Campo funct3 da instrução
    wire [6:0]  funct7;           // Campo funct7 da instrução

    // --- Sinais de Controle ---
    wire        RegWrite;         // Habilita escrita no banco de registradores
    wire        MemRead;          // Habilita leitura da memória
    wire        MemWrite;         // Habilita escrita na memória
    wire        ALUSrc;           // Seleciona fonte do operando B da ALU
    wire        ALUASrc;          // Seleciona fonte do operando A da ALU
    wire        Branch;           // Indica instrução de branch
    wire [1:0]  ResultSrc;        // Seleciona fonte do dado para WB
    wire [1:0]  ALUOp;            // Operação da ALU
    wire [1:0]  Jump;             // Indica instrução de jump

    // --- Sinais de Estágio EX ---
    wire [3:0]  alu_control_out;  // Controle da ALU
    wire [1:0]  forwardA;         // Controle de forwarding para operando A
    wire [1:0]  forwardB;         // Controle de forwarding para operando B
    wire [31:0] operandA;         // Operando A para a ALU (com forwarding)
    wire [31:0] operandB;         // Operando B para a ALU (com forwarding)
    wire [31:0] alu_input_b;      // Operando B final (pode ser imediato)
    wire [31:0] alu_result;       // Resultado da ALU
    wire        alu_zero;         // Flag zero da ALU
    wire [1:0]  pc_sel;           // Seleção do próximo PC
    wire        branch_cond;      // Condição de branch satisfeita
    wire [31:0] branch_addr;      // Endereço de branch calculado
    wire [31:0] jump_addr;        // Endereço de jump calculado
    wire [31:0] jalr_addr;        // Endereço de JALR calculado
    wire [31:0] alu_a_mux_in;     // Entrada do mux do operando A

    // --- Sinais de Estágio MEM ---
    wire [31:0] mem_read_data;    // Dado lido da memória/cache

    // --- Sinais de Estágio WB ---
    wire [31:0] wb_data;          // Dado a ser escrito no registrador

    // --- Sinais de Hazard e Cache ---
    wire        hazard_bubble;    // Stall por hazard de dados (insere bolha)
    wire        cache_freeze;     // Stall por cache miss (congela pipeline)
    wire        cache_hit;        // Indica hit na cache de dados
    reg         reset_done;       // Flag de reset concluído

    // --- Sinais de Conexão Cache-Memória ---
    wire [31:0] cache_mem_addr;   // Endereço para memória principal
    wire [31:0] cache_mem_wdata;  // Dado para escrita na memória
    wire        cache_mem_read;   // Sinal de leitura para memória
    wire        cache_mem_write;  // Sinal de escrita para memória
    wire [31:0] mem_cache_rdata;  // Dado lido da memória principal
    wire        mem_busy;         // Memória ocupada (não usado neste design)

    // =====================================================================
    // 2. REGISTROS DE PIPELINE
    // =====================================================================

    // --- Registro IF/ID ---
    reg [31:0] if_id_pc;          // PC no estágio IF
    reg [31:0] if_id_instr;       // Instrução no estágio IF
    reg [31:0] if_id_pc_plus_4;   // PC+4 no estágio IF

    // --- Registro ID/EX ---
    reg        id_ex_RegWrite;    // Controle: escrita no registrador
    reg        id_ex_MemRead;     // Controle: leitura da memória
    reg        id_ex_MemWrite;    // Controle: escrita na memória
    reg        id_ex_ALUSrc;      // Controle: seleção operando B
    reg        id_ex_ALUASrc;     // Controle: seleção operando A
    reg        id_ex_Branch;      // Controle: instrução de branch
    reg [1:0]  id_ex_ResultSrc;   // Controle: fonte do dado WB
    reg [1:0]  id_ex_ALUOp;       // Controle: operação da ALU
    reg [1:0]  id_ex_Jump;        // Controle: instrução de jump
    reg [31:0] id_ex_pc;          // PC no estágio ID
    reg [31:0] id_ex_pc_plus_4;   // PC+4 no estágio ID
    reg [31:0] id_ex_reg_data1;   // Dado do registrador 1
    reg [31:0] id_ex_reg_data2;   // Dado do registrador 2
    reg [31:0] id_ex_imm;         // Valor imediato
    reg [31:0] id_ex_instr;       // Instrução
    reg [4:0]  id_ex_rs1;         // Registrador fonte 1
    reg [4:0]  id_ex_rs2;         // Registrador fonte 2
    reg [4:0]  id_ex_rd;          // Registrador destino
    reg [2:0]  id_ex_funct3;      // Campo funct3
    reg [6:0]  id_ex_funct7;      // Campo funct7

    // --- Registro EX/MEM ---
    reg        ex_mem_RegWrite;   // Controle: escrita no registrador
    reg        ex_mem_MemRead;    // Controle: leitura da memória
    reg        ex_mem_MemWrite;   // Controle: escrita na memória
    reg [1:0]  ex_mem_ResultSrc;  // Controle: fonte do dado WB
    reg [31:0] ex_mem_pc;         // PC no estágio EX
    reg [31:0] ex_mem_pc_plus_4;  // PC+4 no estágio EX
    reg [31:0] ex_mem_alu_result; // Resultado da ALU
    reg [31:0] ex_mem_write_data; // Dado para escrita na memória
    reg [31:0] ex_mem_imm;        // Valor imediato
    reg [31:0] ex_mem_instr;      // Instrução
    reg [4:0]  ex_mem_rd;         // Registrador destino

    // --- Registro MEM/WB ---
    reg        mem_wb_RegWrite;   // Controle: escrita no registrador
    reg [1:0]  mem_wb_ResultSrc;  // Controle: fonte do dado WB
    reg [31:0] mem_wb_pc;         // PC no estágio MEM
    reg [31:0] mem_wb_pc_plus_4;  // PC+4 no estágio MEM
    reg [31:0] mem_wb_mem_data;   // Dado lido da memória
    reg [31:0] mem_wb_alu_result; // Resultado da ALU
    reg [31:0] mem_wb_imm;        // Valor imediato
    reg [31:0] mem_wb_instr;      // Instrução
    reg [4:0]  mem_wb_rd;         // Registrador destino
    reg        mem_wb_MemWrite;   // Sinal de escrita na memória
    reg [31:0] mem_wb_mem_wdata;  // Dado para escrita na memória

    // =====================================================================
    // 3. LÓGICA PRINCIPAL DO DATAPATH
    // =====================================================================

    // --- Lógica de Stall ---
    assign stall = hazard_bubble | cache_freeze;  // Stall por hazard ou cache miss

    // =====================================================================
    // 3.1 ESTÁGIO IF - BUSCA DA INSTRUÇÃO
    // =====================================================================
    /**
     * - Calcula PC+4 (próxima instrução sequencial)
     * - Lê instrução da memória de instruções
     * - Atualiza o PC com o próximo endereço (sequencial, branch ou jump)
     * - Registra valores no pipeline IF/ID
     */

    // Cálculo do próximo PC
    assign pc_plus_4 = pc + 4;
    assign flush = (pc_sel != 2'b00);  // Flush quando há desvio

    // Memória de instruções
    instruction_memory imem (
        .addr(pc),
        .instruction(instr)
    );

    // Atualização do PC
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc <= 32'h0;
            reset_done <= 1'b0;
        end else if (!reset_done) begin
            reset_done <= 1'b1;
            pc <= 32'h0;
        end else if (~stall) begin
            pc <= pc_next;
        end
    end

    // Lógica de seleção do próximo PC
    assign pc_next = (pc_sel == 2'b01) ? branch_addr :  // Branch
                    (pc_sel == 2'b10) ? jump_addr :     // Jump
                    (pc_sel == 2'b11) ? jalr_addr :     // JALR
                    pc_plus_4;                          // Sequencial

    // Registro IF/ID
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            if_id_pc <= 32'h0;
            if_id_instr <= 32'h00000013;  // NOP (addi x0, x0, 0)
            if_id_pc_plus_4 <= 32'h0;
        end else if (~stall) begin
            if (flush) begin
                // Flush: insere NOP no pipeline
                if_id_pc <= 32'h0;
                if_id_instr <= 32'h00000013;
                if_id_pc_plus_4 <= 32'h0;
            end else begin
                // Avança instrução normalmente
                if_id_pc <= pc;
                if_id_instr <= reset_done ? instr : 32'h00000013;
                if_id_pc_plus_4 <= pc_plus_4;
            end
        end
    end

    // =====================================================================
    // 3.2 ESTÁGIO ID - DECODIFICAÇÃO
    // =====================================================================
    /**
     * - Lê registradores do banco de registradores
     * - Decodifica instrução e gera sinais de controle
     * - Gera valor imediato
     * - Detecta hazards de dados
     * - Registra valores no pipeline ID/EX
     */

    // Banco de registradores
    register_file regfile (
        .clk(clk),
        .RegWrite(mem_wb_RegWrite),
        .rs1(rs1),
        .rs2(rs2),
        .rd(mem_wb_rd),
        .write_data(wb_data),
        .read_data1(reg_data1),
        .read_data2(reg_data2)
    );

    // Unidade de controle
    control_unit ctrl (
        .opcode(opcode),
        .RegWrite(RegWrite),
        .ResultSrc(ResultSrc),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .ALUSrc(ALUSrc),
        .ALUASrc(ALUASrc),
        .ALUOp(ALUOp),
        .Branch(Branch),
        .Jump(Jump)
    );

    // Gerador de imediatos
    imm_gen immediate_generator (
        .instruction(if_id_instr),
        .opcode(opcode),
        .imm(imm)
    );

    // Unidade de detecção de hazards
    hazard_unit hazard (
        .id_ex_MemRead(id_ex_MemRead),
        .id_ex_rd(id_ex_rd),
        .if_id_rs1(rs1),
        .if_id_rs2(rs2),
        .stall(hazard_bubble)
    );

    // Extração de campos da instrução
    assign opcode = if_id_instr[6:0];
    assign rs1    = if_id_instr[19:15];
    assign rs2    = if_id_instr[24:20];
    assign rd     = if_id_instr[11:7];
    assign funct3 = if_id_instr[14:12];
    assign funct7 = if_id_instr[31:25];

    // Registro ID/EX
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset: zera todos os sinais
            id_ex_RegWrite <= 1'b0; id_ex_ResultSrc <= 2'b0; 
            id_ex_MemRead <= 1'b0; id_ex_MemWrite <= 1'b0; 
            id_ex_Branch <= 1'b0; id_ex_Jump <= 2'b0;
            id_ex_ALUSrc <= 1'b0; id_ex_ALUASrc <= 1'b0; 
            id_ex_ALUOp <= 2'b0; id_ex_pc <= 32'b0; 
            id_ex_pc_plus_4 <= 32'b0; id_ex_reg_data1 <= 32'b0;
            id_ex_reg_data2 <= 32'b0; id_ex_imm <= 32'b0; 
            id_ex_instr <= 32'h00000013; id_ex_rs1 <= 5'b0; 
            id_ex_rs2 <= 5'b0; id_ex_rd <= 5'b0;
            id_ex_funct3 <= 3'b0; id_ex_funct7 <= 7'b0;
        end else if (~cache_freeze) begin
            if (hazard_bubble || flush) begin
                // Hazard ou flush: insere bolha (NOP)
                id_ex_RegWrite <= 1'b0; id_ex_ResultSrc <= 2'b0; 
                id_ex_MemRead <= 1'b0; id_ex_MemWrite <= 1'b0; 
                id_ex_Branch <= 1'b0; id_ex_Jump <= 2'b0;
                id_ex_ALUSrc <= 1'b0; id_ex_ALUASrc <= 1'b0; 
                id_ex_ALUOp <= 2'b0; id_ex_pc <= 32'b0; 
                id_ex_pc_plus_4 <= 32'b0; id_ex_reg_data1 <= 32'b0;
                id_ex_reg_data2 <= 32'b0; id_ex_imm <= 32'b0; 
                id_ex_instr <= 32'h00000013; id_ex_rs1 <= 5'b0; 
                id_ex_rs2 <= 5'b0; id_ex_rd <= 5'b0;
                id_ex_funct3 <= 3'b0; id_ex_funct7 <= 7'b0;
            end else begin
                // Avança instrução normalmente
                id_ex_RegWrite <= RegWrite; id_ex_ResultSrc <= ResultSrc; 
                id_ex_MemRead <= MemRead; id_ex_MemWrite <= MemWrite; 
                id_ex_Branch <= Branch; id_ex_Jump <= Jump;
                id_ex_ALUSrc <= ALUSrc; id_ex_ALUASrc <= ALUASrc; 
                id_ex_ALUOp <= ALUOp; id_ex_pc <= if_id_pc; 
                id_ex_pc_plus_4 <= if_id_pc_plus_4;
                id_ex_reg_data1 <= reg_data1; id_ex_reg_data2 <= reg_data2;
                id_ex_imm <= imm; id_ex_instr <= if_id_instr;
                id_ex_rs1 <= rs1; id_ex_rs2 <= rs2; id_ex_rd <= rd;
                id_ex_funct3 <= funct3; id_ex_funct7 <= funct7;
            end
        end
    end

    // =====================================================================
    // 3.3 ESTÁGIO EX - EXECUÇÃO
    // =====================================================================
    /**
     * - Controle da ALU
     * - Forwarding de dados
     * - Cálculo de desvios
     * - Execução na ALU
     */

    // Controle da ALU
    alu_control alu_ctrl_unit (
        .ALUOp(id_ex_ALUOp),
        .funct3(id_ex_funct3),
        .funct7(id_ex_funct7),
        .alu_control(alu_control_out)
    );

    // Unidade de forwarding
    forwarding_unit fwd (
        .id_ex_rs1(id_ex_rs1),
        .id_ex_rs2(id_ex_rs2),
        .ex_mem_rd(ex_mem_rd),
        .mem_wb_rd(mem_wb_rd),
        .ex_mem_RegWrite(ex_mem_RegWrite),
        .mem_wb_RegWrite(mem_wb_RegWrite),
        .forwardA(forwardA),
        .forwardB(forwardB)
    );

    // Lógica de forwarding para o dado de WB
    wire [31:0] wb_forward_data;
    assign wb_forward_data = (mem_wb_ResultSrc == 2'b01) ? mem_wb_mem_data :  // Dado da memória
                            (mem_wb_ResultSrc == 2'b10) ? mem_wb_imm :        // Imediato
                            (mem_wb_ResultSrc == 2'b11) ? mem_wb_pc_plus_4 :  // PC+4 (para JAL)
                            mem_wb_alu_result;                                // Resultado da ALU

    // Seleção de operandos com forwarding
    assign alu_a_mux_in = (id_ex_ALUASrc) ? id_ex_pc : id_ex_reg_data1;
    assign operandA = (forwardA == 2'b10) ? ex_mem_alu_result :  // Forward de EX/MEM
                     (forwardA == 2'b01) ? wb_forward_data :     // Forward de MEM/WB
                     alu_a_mux_in;                               // Valor original
    assign operandB = (forwardB == 2'b10) ? ex_mem_alu_result :  // Forward de EX/MEM
                     (forwardB == 2'b01) ? wb_forward_data :     // Forward de MEM/WB
                     id_ex_reg_data2;                             // Valor original

    // Seleção do operando B (registrador ou imediato)
    assign alu_input_b = (id_ex_ALUSrc) ? id_ex_imm : operandB;

    // ALU principal (para operações aritméticas/lógicas)
    alu alu_main (
        .a(operandA),
        .b(alu_input_b),
        .alu_control(alu_control_out),
        .result(alu_result),
        .zero(alu_zero)
    );

    // ALU para branches (compara operandos)
    wire [31:0] branch_alu_result;
    wire        branch_alu_zero;
    alu branch_alu (
        .a(operandA),
        .b(operandB),
        .alu_control(alu_control_out),
        .result(branch_alu_result),
        .zero(branch_alu_zero)
    );

    // Lógica de desvio condicional
    assign branch_cond = (id_ex_Branch) & 
                        ((id_ex_funct3 == 3'b000 && branch_alu_zero) ||  // BEQ
                         (id_ex_funct3 == 3'b001 && ~branch_alu_zero) || // BNE
                         (id_ex_funct3 == 3'b100 && branch_alu_result == 1) || // BLT
                         (id_ex_funct3 == 3'b101 && branch_alu_result == 0) || // BGE
                         (id_ex_funct3 == 3'b110 && branch_alu_result == 1) ||  // BLTU
                         (id_ex_funct3 == 3'b111 && branch_alu_result == 0));   // BGEU

    // Cálculo de endereços de desvio
    assign branch_addr = id_ex_pc + id_ex_imm;  // PC-relative para branches
    assign jump_addr = id_ex_pc + id_ex_imm;    // PC-relative para JAL
    assign jalr_addr = operandA + id_ex_imm;    // Registrador + imediato para JALR

    // Seleção do próximo PC
    assign pc_sel = (id_ex_Jump == 2'b01) ? 2'b10 :    // JAL
                   (id_ex_Jump == 2'b10) ? 2'b11 :     // JALR
                   (branch_cond) ? 2'b01 :             // Branch
                   2'b00;                             // Sequencial

    // =====================================================================
    // 3.4 ESTÁGIO MEM - ACESSO À MEMÓRIA
    // =====================================================================
    /**
     * - Acesso à memória via cache
     * - Tratamento de cache miss
     * - Registra valores no pipeline EX/MEM e MEM/WB
     */

    // Registro EX/MEM
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            ex_mem_RegWrite <= 0; ex_mem_ResultSrc <= 0; 
            ex_mem_MemRead <= 0; ex_mem_MemWrite <= 0; 
            ex_mem_pc <= 0; ex_mem_pc_plus_4 <= 0;
            ex_mem_alu_result <= 0; ex_mem_write_data <= 0; 
            ex_mem_imm <= 0; ex_mem_instr <= 32'h00000013; 
            ex_mem_rd <= 0;
        end else if (~cache_freeze) begin
            ex_mem_RegWrite <= id_ex_RegWrite; 
            ex_mem_ResultSrc <= id_ex_ResultSrc;
            ex_mem_MemRead <= id_ex_MemRead; 
            ex_mem_MemWrite <= id_ex_MemWrite;
            ex_mem_pc <= id_ex_pc; 
            ex_mem_pc_plus_4 <= id_ex_pc_plus_4;
            ex_mem_alu_result <= alu_result; 
            ex_mem_write_data <= operandB;
            ex_mem_imm <= id_ex_imm; 
            ex_mem_instr <= id_ex_instr; 
            ex_mem_rd <= id_ex_rd;
        end
    end

    // Cache de dados
    direct_mapped_cache dcache (
        .clk(clk),
        .reset(reset),
        .cpu_addr(ex_mem_alu_result),
        .cpu_write_data(ex_mem_write_data),
        .cpu_read(ex_mem_MemRead),
        .cpu_write(ex_mem_MemWrite),
        .cpu_read_data(mem_read_data),
        .cpu_stall(cache_freeze),
        .hit(cache_hit),
        .mem_read_data(mem_cache_rdata),
        .mem_busy(mem_busy),
        .mem_addr(cache_mem_addr),
        .mem_write_data(cache_mem_wdata),
        .mem_read(cache_mem_read),
        .mem_write(cache_mem_write)
    );

    // Memória principal de dados
    data_memory main_memory (
        .clk(clk),
        .MemRead(cache_mem_read),
        .MemWrite(cache_mem_write),
        .addr(cache_mem_addr),
        .write_data(cache_mem_wdata),
        .read_data(mem_cache_rdata)
    );

    // Registro MEM/WB
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            mem_wb_RegWrite <= 0; mem_wb_ResultSrc <= 0; 
            mem_wb_pc <= 0; mem_wb_pc_plus_4 <= 0; 
            mem_wb_mem_data <= 0; mem_wb_alu_result <= 0;
            mem_wb_imm <= 0; mem_wb_instr <= 32'h00000013; 
            mem_wb_rd <= 0; mem_wb_MemWrite <= 0; 
            mem_wb_mem_wdata <= 0;
        end else if (~cache_freeze) begin
            mem_wb_RegWrite <= ex_mem_RegWrite; 
            mem_wb_ResultSrc <= ex_mem_ResultSrc;
            mem_wb_pc <= ex_mem_pc; 
            mem_wb_pc_plus_4 <= ex_mem_pc_plus_4;
            mem_wb_mem_data <= mem_read_data; 
            mem_wb_alu_result <= ex_mem_alu_result;
            mem_wb_imm <= ex_mem_imm; 
            mem_wb_instr <= ex_mem_instr;
            mem_wb_rd <= ex_mem_rd; 
            mem_wb_MemWrite <= ex_mem_MemWrite;
            mem_wb_mem_wdata <= ex_mem_write_data;
        end
    end

    // =====================================================================
    // 3.5 ESTÁGIO WB - ESCRITA NO BANCO DE REGISTRADORES
    // =====================================================================
    /**
     * - Seleção do dado a ser escrito no banco de registradores
     * - Pode ser: resultado da ALU, dado da memória, imediato ou PC+4
     */

    assign wb_data = (mem_wb_ResultSrc == 2'b01) ? mem_wb_mem_data :  // Dado da memória
                    (mem_wb_ResultSrc == 2'b10) ? mem_wb_imm :        // Imediato
                    (mem_wb_ResultSrc == 2'b11) ? mem_wb_pc_plus_4 :  // PC+4 (para JAL)
                    mem_wb_alu_result;                                // Resultado da ALU

    // =====================================================================
    // 4. ATRIBUIÇÃO DAS SAÍDAS
    // =====================================================================

    assign o_pc_if        = pc;
    assign o_instr_id     = if_id_instr;
    assign o_instr_ex     = id_ex_instr;
    assign o_instr_mem    = ex_mem_instr;
    assign o_instr_wb     = mem_wb_instr;
    assign o_stall        = stall;
    assign o_hazard_stall = hazard_bubble;
    assign o_cache_stall  = cache_freeze;
    assign o_cache_hit    = cache_hit;
    assign o_flush        = flush;
    assign o_forwardA     = forwardA;
    assign o_forwardB     = forwardB;
    assign o_wb_MemWrite  = mem_wb_MemWrite;
    assign o_wb_mem_addr  = mem_wb_alu_result;
    assign o_wb_mem_wdata = mem_wb_mem_wdata;

endmodule