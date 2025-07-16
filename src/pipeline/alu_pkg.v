// Precisamos criar um pacote para os parâmetros da ULA para que possam ser compartilhados
package alu_pkg;
    parameter ALU_ADD  = 4'b0000;
    parameter ALU_SUB  = 4'b0001;
    parameter ALU_SLT  = 4'b0010;
    parameter ALU_SLLI = 4'b0011;
endpackage