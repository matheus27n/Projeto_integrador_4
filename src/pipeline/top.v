module top (
    input  wire clk,
    input  wire reset,
    output wire [31:0] pc_out
);

    // ==== Conexão com Datapath ====
    datapath dp (
        .clk(clk),
        .reset(reset),
        .pc_out(pc_out)
    );

endmodule
