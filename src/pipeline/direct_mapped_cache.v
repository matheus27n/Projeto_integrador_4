// =================================================================================
// Módulo: direct_mapped_cache
// Descrição: Implementa uma cache de dados de mapeamento direto com política
//            de escrita write-through e blocos de uma palavra.
//
// Funcionamento:
// - CPU-facing: Interage com o estágio MEM do processador.
// - Memory-facing: Interage com a memória principal (data_memory).
// - Stall: Sinaliza ao processador para parar durante um cache miss.
//
// Divisão do Endereço (32 bits):
//   - Tag:   [31:10] (22 bits) -> Identifica qual bloco da memória está na cache.
//   - Index: [9:2]   (8 bits)  -> Determina a linha da cache onde o bloco pode estar.
//   - Offset:[1:0]   (2 bits)  -> Ignorado (bloco de 1 palavra, sempre alinhado).
// =================================================================================
// =================================================================================
// Módulo: direct_mapped_cache
// Descrição: Versão atualizada com uma saída 'hit' para depuração.
// =================================================================================
// =================================================================================
// Módulo: direct_mapped_cache
// Descrição: Versão final com lógica de stall combinacional e imediata.
// =================================================================================
module direct_mapped_cache #(
    parameter CACHE_LINES = 256,
    parameter DATA_WIDTH  = 32
)(
    // --- Interfaces (permanecem as mesmas) ---
    input wire clk,
    input wire reset,
    input wire [DATA_WIDTH-1:0] cpu_addr,
    input wire [DATA_WIDTH-1:0] cpu_write_data,
    input wire                  cpu_read,
    input wire                  cpu_write,
    output reg [DATA_WIDTH-1:0] cpu_read_data,
    output wire                 cpu_stall,
    output wire                 hit,
    input wire [DATA_WIDTH-1:0] mem_read_data,
    input wire                  mem_busy,
    output reg [DATA_WIDTH-1:0] mem_addr,
    output reg [DATA_WIDTH-1:0] mem_write_data,
    output reg                  mem_read,
    output reg                  mem_write
);

    localparam INDEX_WIDTH = $clog2(CACHE_LINES);
    localparam TAG_WIDTH   = DATA_WIDTH - INDEX_WIDTH - 2;

    reg [TAG_WIDTH-1:0]   tag_array[CACHE_LINES-1:0];
    reg [DATA_WIDTH-1:0]  data_array[CACHE_LINES-1:0];
    reg                   valid_bits[CACHE_LINES-1:0];

    wire [TAG_WIDTH-1:0]   tag   = cpu_addr[DATA_WIDTH-1 : INDEX_WIDTH+2];
    wire [INDEX_WIDTH-1:0] index = cpu_addr[INDEX_WIDTH+1 : 2];

    assign hit = valid_bits[index] && (tag_array[index] == tag) && (cpu_read || cpu_write);

    localparam FSM_IDLE = 2'b00, FSM_MEM_READ = 2'b01, FSM_MEM_WRITE = 2'b10;
    reg [1:0] state, next_state;

    // --- LÓGICA DE STALL CORRIGIDA E IMEDIATA ---
    // O pipeline para se a FSM estiver ocupada, OU se ela estiver ociosa
    // mas uma requisição de memória chegar e for um MISS.
    assign cpu_stall = (state != FSM_IDLE) || ((state == FSM_IDLE) && (cpu_read || cpu_write) && !hit);

    // ... (O restante da lógica da FSM e de atualização dos dados permanece o mesmo) ...
    always @(*) begin
        next_state = state;
        case (state)
            FSM_IDLE: if (hit) begin if (cpu_write) next_state = FSM_MEM_WRITE; else next_state = FSM_IDLE; end else if (cpu_read || cpu_write) next_state = FSM_MEM_READ;
            FSM_MEM_READ: if (!mem_busy) begin if (cpu_write) next_state = FSM_MEM_WRITE; else next_state = FSM_IDLE; end
            FSM_MEM_WRITE: if (!mem_busy) next_state = FSM_IDLE;
        endcase
    end

    always @(posedge clk or posedge reset) begin
        if (reset) state <= FSM_IDLE;
        else state <= next_state;
    end

    always @(*) begin
        cpu_read_data  = data_array[index];
        mem_addr       = cpu_addr;
        mem_write_data = cpu_write_data;
        mem_read       = 1'b0;
        mem_write      = 1'b0;
        case (state)
            FSM_IDLE: if (hit && cpu_write) mem_write = 1'b1;
            FSM_MEM_READ: mem_read = 1'b1;
            FSM_MEM_WRITE: mem_write = 1'b1;
        endcase
    end

    always @(posedge clk) begin
        if (reset) begin
            for (integer i = 0; i < CACHE_LINES; i = i + 1) valid_bits[i] <= 1'b0;
        end else begin
            if (hit && cpu_write) data_array[index] <= cpu_write_data;
            if (state == FSM_MEM_READ && !mem_busy) begin
                valid_bits[index] <= 1'b1;
                tag_array[index]  <= tag;
                data_array[index] <= mem_read_data;
            end
        end
    end

endmodule