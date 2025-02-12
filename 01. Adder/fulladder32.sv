module fulladder32(
    input logic [31:0] a_i,
    input logic [31:0] b_i,
    input logic carry_i,
      
    output logic [31:0] sum_o,
    output logic carry_o
);
    logic [8:0] carry_ik;
    assign carry_ik[0] = carry_i;

    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : newgen
            fulladder4 name(
                .a_i(a_i[4*i + 3:4*i]),
                .b_i(b_i[4*i + 3:4*i]),
                .carry_i(carry_ik[i]),
                .sum_o(sum_o[4*i + 3:4*i]),
                .carry_o(carry_ik[i + 1])
            );
        end
        assign carry_o = carry_ik[8];
    endgenerate
endmodule