// parte_operativa.v
`timescale 1ns/1ps

module parte_operativa (
    input         clk,
    input         reset,
    // Sinais de controle vindos da Unidade de Controle
    input         PCWrite,
    input         MemWrite,
    input         ALUSrc,
    input         RegWrite,
    input  [1:0]  ResultSrc,
    input  [3:0]  ALUControl,
    // Saídas para a Unidade de Controle
    output [6:0]  opcode,
    output [2:0]  funct3,
    output [6:0]  funct7,
    // Saída para display ou teste
    output [31:0] reg_a0_out // Expondo o registrador a0 (x10) para testes
);

    // Sinais internos
    // Fios para conexões contínuas
    wire [31:0] instruction;
    wire [31:0] pc_next, pc_plus_4;
    wire [31:0] alu_input_b;
    wire [31:0] read_data_1, read_data_2;
    wire [31:0] read_data_mem;
    wire        zero_flag;

    // Registradores para valores atribuídos em blocos 'always'
    reg [31:0] pc_current;
    reg [31:0] imm_ext;
    reg [31:0] alu_result;
    reg [31:0] write_data_reg;
    //================================================================
    // 1. Program Counter (PC)
    //================================================================
    // O PC é um registrador que armazena o endereço da próxima instrução a ser buscada.
    // Ele é atualizado no final do ciclo de clock se PCWrite for verdadeiro.
    always @(posedge clk or posedge reset) begin
        if (reset)
            pc_current <= 32'h00000000;
        else if (PCWrite)
            pc_current <= pc_next;
    end

    assign pc_plus_4 = pc_current + 4; // Incrementa o PC para a próxima instrução (instruções são de 32 bits/4 bytes)

    // A lógica para pc_next (saltos e desvios) será implementada com multiplexadores.
    // Por enquanto, consideramos apenas o fluxo sequencial.
    // O mux para Jumps e Branches será adicionado aqui depois.
    // Provisoriamente:
    assign pc_next = pc_plus_4;


    //================================================================
    // 2. Memória de Instruções (Instruction Memory)
    //================================================================
    // Memória ROM de 1024 palavras de 32 bits.
    // O endereço é o PC, e a saída é a instrução.
    reg [31:0] instruction_memory [0:1023];

    // Inicialização da memória com instruções de teste
    initial begin
        // addi x1, x0, 5   (0x00500093) -> x1 = 5
        instruction_memory[0] = 32'h00500093;
        // addi x2, x0, 10  (0x00A00113) -> x2 = 10
        instruction_memory[1] = 32'h00A00113;
        // add x3, x1, x2   (0x002081B3) -> x3 = x1 + x2 = 15
        instruction_memory[2] = 32'h002081B3;
        // sw x3, 12(x0)    (0x00302623) -> Salva x3 no endereço de memória 12
        instruction_memory[3] = 32'h00302623;
        // lw x4, 12(x0)    (0x00C02203) -> Carrega o valor do endereço 12 em x4
        instruction_memory[4] = 32'h00C02203;
    end

    // A leitura da memória de instruções é combinacional.
    // O endereço do PC é deslocado 2 bits para a direita pois a memória é indexada por palavras (word-addressable).
    assign instruction = instruction_memory[pc_current[11:2]];

    // Decodifica a instrução para enviar os campos para a unidade de controle e outros componentes
    assign opcode = instruction[6:0];
    assign funct3 = instruction[14:12];
    assign funct7 = instruction[31:25];

    //================================================================
    // 3. Banco de Registradores (Register File)
    //================================================================
    // Contém 32 registradores de 32 bits.
    // Lê de dois registradores (rs1, rs2) e escreve em um (rd).
    // A escrita ocorre na borda de subida do clock se RegWrite estiver ativo.
    reg [31:0] register_file [0:31];

    // Lógica de escrita
    always @(posedge clk) begin
        if (RegWrite) begin
            // Garante que não se escreva no registrador x0, que é sempre zero.
            if (instruction[11:7] != 5'b0) begin
                register_file[instruction[11:7]] <= write_data_reg;
            end
        end
    end

    // Lógica de leitura (combinacional)
    assign read_data_1 = (instruction[19:15] == 5'b0) ? 32'b0 : register_file[instruction[19:15]];
    assign read_data_2 = (instruction[24:20] == 5'b0) ? 32'b0 : register_file[instruction[24:20]];
    
    // Saída para teste (registrador a0 = x10)
    assign reg_a0_out = register_file[10];

    //================================================================
    // 4. Extensor de Sinal (Immediate Generator)
    //================================================================
    // Gera o valor imediato de 32 bits a partir dos formatos de instrução.
    // Esta implementação inicial foca no tipo I.
    // TODO: Adicionar os outros tipos (S, B, U, J).
    always @(*) begin
        // Por enquanto, apenas o imediato do tipo I (para ADDI, LW)
        case (opcode)
            7'b0010011, 7'b0000011: // I-type (addi, lw)
                imm_ext = {{20{instruction[31]}}, instruction[31:20]};
            7'b0100011: // S-type (sw)
                imm_ext = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
            default:
                imm_ext = 32'b0;
        endcase
    end

    //================================================================
    // 5. ULA (Unidade Lógica e Aritmética)
    //================================================================
    // Mux para selecionar a segunda entrada da ULA: pode ser um registrador ou o imediato estendido.
    assign alu_input_b = (ALUSrc) ? imm_ext : read_data_2;

    // Lógica da ULA
    always @(*) begin
        case (ALUControl)
            4'b0000: alu_result = read_data_1 + alu_input_b; // ADD
            4'b0001: alu_result = read_data_1 - alu_input_b; // SUB
            // Adicionar outras operações da ULA aqui (AND, OR, SLT, etc.)
            default: alu_result = 32'b0;
        endcase
    end

    assign zero_flag = (alu_result == 32'b0); // Flag para desvios condicionais (beq, bne)

    //================================================================
    // 6. Memória de Dados (Data Memory)
    //================================================================
    // Memória RAM de 1024 palavras de 32 bits.
    // O endereço vem do resultado da ULA.
    reg [31:0] data_memory [0:1023];

    // Escrita na memória (síncrona, como um registrador)
    always @(posedge clk) begin
        if (MemWrite) begin
            // O endereço é alinhado à palavra (ignora os 2 bits menos significativos)
            data_memory[alu_result[11:2]] <= read_data_2;
        end
    end

    // Leitura da memória (combinacional)
    assign read_data_mem = data_memory[alu_result[11:2]];

    //================================================================
    // 7. Mux para escrita no Banco de Registradores
    //================================================================
    // Seleciona qual valor será escrito de volta no banco de registradores.
    // Pode ser o resultado da ULA, o dado lido da memória, etc.
    always @(*) begin
        case (ResultSrc)
            2'b00: write_data_reg = alu_result;  // Resultado da ULA (Tipo-R, ADDI)
            2'b01: write_data_reg = read_data_mem; // Dado da memória (LW)
            // 2'b10: write_data_reg = pc_plus_4; // Para instruções de salto e link (JAL)
            default: write_data_reg = alu_result;
        endcase
    end

endmodule