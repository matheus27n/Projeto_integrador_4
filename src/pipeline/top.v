module top (
    input  wire        clk,
    input  wire        reset,
    output wire [31:0] pc_out,
    output wire        stall_out, // <-- SAÍDA NOVA
    output wire        flush_out  // <-- SAÍDA NOVA
);

    wire stall_internal;
    wire flush_internal;
    
    datapath dp (
        .clk(clk),
        .reset(reset),
        .pc_out(pc_out),
        .o_stall(stall_internal), // Conecta a nova saída do datapath
        .o_flush(flush_internal)  // Conecta a nova saída do datapath
    );

    assign stall_out = stall_internal;
    assign flush_out = flush_internal;

endmodule