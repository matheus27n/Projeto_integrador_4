module hazard_unit (
    input  wire       id_ex_MemRead,
    input  wire [4:0] id_ex_rd,
    input  wire [4:0] if_id_rs1,
    input  wire [4:0] if_id_rs2,
    output reg        stall
);

always @(*) begin
    if (id_ex_MemRead && ((id_ex_rd == if_id_rs1) || (id_ex_rd == if_id_rs2)))
        stall = 1;
    else
        stall = 0;
end

endmodule
