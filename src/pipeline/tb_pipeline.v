`timescale 1ns / 1ps

module tb_pipeline();
    // 1. Sinais para conectar ao processador
    reg clk;
    reg reset;

    // Fios para ler os resultados do estágio WB para depuração
    wire [31:0] wb_pc;
    wire [31:0] wb_instruction;
    wire [31:0] wb_write_data;
    wire [4:0]  wb_rd_addr;
    wire        wb_RegWrite;

    // 2. Instancia o processador e conecta as saídas de depuração
    pipeline_topo uut (
        .clk(clk),
        .reset(reset),
        .wb_pc(wb_pc),
        .wb_instruction(wb_instruction),
        .wb_write_data(wb_write_data),
        .wb_rd_addr(wb_rd_addr),
        .wb_RegWrite(wb_RegWrite)
    );

    // 3. Geração de clock e reset
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $timeformat(-9, 2, " ns", 10);
        reset = 1;
        #15;
        reset = 0;
        #100; // Tempo suficiente para as primeiras instruções completarem
        $display("\nSimulação Finalizada.");
        $finish;
    end
    
    // 4. Função para decodificar a instrução (COMPLETA E CORRIGIDA)
    function string decode_instruction;
        input [31:0] instr;
        // Variáveis locais da função
        reg [4:0] rd, rs1, rs2;
        reg [6:0] opcode;
        reg [2:0] funct3;
        reg [6:0] funct7;
        reg [31:0] imm;
        
        begin
            opcode = instr[6:0]; rd = instr[11:7]; rs1 = instr[19:15]; rs2 = instr[24:20];
            funct3 = instr[14:12]; funct7 = instr[31:25];

            case(opcode)
                7'b0010011: begin // I-type
                    imm = {{20{instr[31]}}, instr[31:20]};
                    decode_instruction = $sformatf("addi x%0d, x%0d, %d", rd, rs1, $signed(imm));
                end
                default: decode_instruction = "--- INSTRUÇÃO DESCONHECIDA ---";
            endcase
        end
    endfunction

    // 5. LOG DIDÁTICO focado no estágio WB
    integer cycle_count = 0;
    initial begin
      $display("=======================================================================================");
      $display("|| CICLO |   TEMPO   |    PC    | INSTRUÇÃO COMPLETADA        | RESULTADO               ||");
      $display("=======================================================================================");
    end

    always @(posedge clk) begin
        if (!reset) begin
            // A cada ciclo, verificamos se uma instrução está sendo escrita no estágio WB
            // O #1ps garante que estamos lendo os valores após a atualização do ciclo
            #1ps; 
            if (wb_RegWrite) begin
                $display("|| %5d | %t | %h | %-28s | x%0d <= %d", 
                         cycle_count - 4, // Ajusta o ciclo para quando a instrução ENTROU no pipeline
                         $time, 
                         wb_pc, 
                         decode_instruction(wb_instruction), 
                         wb_rd_addr, 
                         $signed(wb_write_data));
            end
            cycle_count = cycle_count + 1;
        end
    end

endmodule