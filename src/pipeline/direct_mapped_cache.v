/**
 * @file direct_mapped_cache.v
 * @brief Cache de mapeamento direto com política write-through
 * @details
 *   - Implementa uma cache de dados de mapeamento direto
 *   - Blocos de 1 palavra (32 bits)
 *   - Política write-through (escrita imediata na memória)
 *   - Tratamento de miss com stall do pipeline
 * 
 * Divisão do endereço (32 bits):
 *   - Tag:    [31:10] (22 bits) - Identificação do bloco na memória
 *   - Index:  [9:2]   (8 bits)  - Linha da cache (256 linhas)
 *   - Offset: [1:0]   (2 bits)  - Não usado (acesso word-aligned)
 */

module direct_mapped_cache #(
    parameter CACHE_LINES = 256,  // Número de linhas na cache (2^8 = 256)
    parameter DATA_WIDTH  = 32    // Largura de dados (32 bits)
)(
    // --- Interface com a CPU ---
    input  wire                  clk,            // Clock
    input  wire                  reset,          // Reset assíncrono
    input  wire [DATA_WIDTH-1:0] cpu_addr,       // Endereço da CPU
    input  wire [DATA_WIDTH-1:0] cpu_write_data, // Dado para escrita
    input  wire                  cpu_read,       // Sinal de leitura
    input  wire                  cpu_write,      // Sinal de escrita
    output reg  [DATA_WIDTH-1:0] cpu_read_data,  // Dado lido para CPU
    output wire                  cpu_stall,      // Sinal de stall
    output wire                  hit,            // Indica cache hit
    
    // --- Interface com a Memória Principal ---
    input  wire [DATA_WIDTH-1:0] mem_read_data,  // Dado lido da memória
    input  wire                  mem_busy,       // Memória ocupada
    output reg  [DATA_WIDTH-1:0] mem_addr,       // Endereço para memória
    output reg  [DATA_WIDTH-1:0] mem_write_data, // Dado para escrita
    output reg                   mem_read,       // Sinal de leitura
    output reg                   mem_write       // Sinal de escrita
);

    // =====================================================================
    // 1. PARÂMETROS E DECLARAÇÕES
    // =====================================================================
    
    // Tamanhos dos campos de endereço
    localparam INDEX_WIDTH = $clog2(CACHE_LINES);  // 8 bits para 256 linhas
    localparam TAG_WIDTH   = DATA_WIDTH - INDEX_WIDTH - 2;  // 22 bits (32-8-2)
    
    // Estruturas da Cache
    reg [TAG_WIDTH-1:0]   tag_array[CACHE_LINES-1:0];   // Armazena tags
    reg [DATA_WIDTH-1:0]  data_array[CACHE_LINES-1:0];  // Armazena dados
    reg                   valid_bits[CACHE_LINES-1:0];   // Bits de validade
    
    // Estados da Máquina de Estados Finitos (FSM)
    localparam FSM_IDLE       = 2'b00;  // Ocioso
    localparam FSM_MEM_READ   = 2'b01;  // Lendo da memória
    localparam FSM_MEM_WRITE  = 2'b10;  // Escrevendo na memória
    
    // Sinais internos
    reg [1:0] state, next_state;        // Estado atual e próximo
    wire [TAG_WIDTH-1:0]   tag;         // Tag do endereço atual
    wire [INDEX_WIDTH-1:0] index;       // Índice do endereço atual

    // =====================================================================
    // 2. LÓGICA COMBINACIONAL
    // =====================================================================
    
    // Extração de tag e índice do endereço
    assign tag   = cpu_addr[DATA_WIDTH-1 : INDEX_WIDTH+2];
    assign index = cpu_addr[INDEX_WIDTH+1 : 2];
    
    // Detecção de hit (acerto na cache)
    // Hit ocorre quando:
    // 1. O bloco é válido (valid_bit = 1)
    // 2. A tag armazenada coincide com a tag do endereço
    // 3. Há uma operação de leitura ou escrita
    assign hit = valid_bits[index] && (tag_array[index] == tag) && 
                (cpu_read || cpu_write);
    
    // Lógica de stall:
    // Stall é ativado quando:
    // 1. A FSM não está no estado IDLE (ocupada com operação de memória)
    // OU
    // 2. Há uma requisição da CPU que resulta em miss
    assign cpu_stall = (state != FSM_IDLE) || 
                      ((state == FSM_IDLE) && (cpu_read || cpu_write) && !hit);

    // =====================================================================
    // 3. MÁQUINA DE ESTADOS (FSM)
    // =====================================================================
    
    // Lógica de transição de estados
    always @(*) begin
        next_state = state;  // Mantém estado por padrão
        
        case (state)
            FSM_IDLE: begin
                // Se hit e escrita, vai para estado de escrita na memória
                if (hit && cpu_write) begin
                    next_state = FSM_MEM_WRITE;
                end 
                // Se miss e operação da CPU, vai para estado de leitura
                else if ((cpu_read || cpu_write) && !hit) begin
                    next_state = FSM_MEM_READ;
                end
            end
            
            FSM_MEM_READ: begin
                // Quando memória termina leitura
                if (!mem_busy) begin
                    // Se era uma escrita, vai para estado de escrita
                    if (cpu_write) begin
                        next_state = FSM_MEM_WRITE;
                    end 
                    // Senão, volta para idle
                    else begin
                        next_state = FSM_IDLE;
                    end
                end
            end
            
            FSM_MEM_WRITE: begin
                // Quando memória termina escrita, volta para idle
                if (!mem_busy) begin
                    next_state = FSM_IDLE;
                end
            end
        endcase
    end
    
    // Registro de estado
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= FSM_IDLE;
        end else begin
            state <= next_state;
        end
    end

    // =====================================================================
    // 4. LÓGICA DE SAÍDAS E ATUALIZAÇÃO DA CACHE
    // =====================================================================
    
    // Lógica combinacional para saídas
    always @(*) begin
        // Valores padrão
        cpu_read_data  = data_array[index];  // Dado lido da cache
        mem_addr       = cpu_addr;           // Endereço para memória
        mem_write_data = cpu_write_data;     // Dado para escrita
        mem_read       = 1'b0;               // Sem leitura
        mem_write      = 1'b0;               // Sem escrita
        
        case (state)
            FSM_IDLE: begin
                // No hit de escrita, escreve na memória (write-through)
                if (hit && cpu_write) begin
                    mem_write = 1'b1;
                end
            end
            
            FSM_MEM_READ: begin
                // Durante miss, lê da memória
                mem_read = 1'b1;
            end
            
            FSM_MEM_WRITE: begin
                // Durante escrita, envia para memória
                mem_write = 1'b1;
            end
        endcase
    end
    
    // Atualização dos dados da cache
    always @(posedge clk) begin
        if (reset) begin
            // Reset: invalida todas as linhas
            for (integer i = 0; i < CACHE_LINES; i = i + 1) begin
                valid_bits[i] <= 1'b0;
            end
        end else begin
            // Atualização na escrita (hit)
            if (hit && cpu_write) begin
                data_array[index] <= cpu_write_data;
            end
            
            // Atualização no carregamento (após miss)
            if (state == FSM_MEM_READ && !mem_busy) begin
                valid_bits[index] <= 1'b1;          // Marca como válido
                tag_array[index]  <= tag;           // Armazena tag
                data_array[index] <= mem_read_data; // Armazena dado
            end
        end
    end

endmodule