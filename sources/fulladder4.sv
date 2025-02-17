module fulladder4(
    input logic [3:0] a_i,
    input logic [3:0] b_i,
    input logic carry_i,
      
    output logic [3:0] sum_o,
    output logic carry_o
);
    logic [4:0] carry_ik;
    assign carry_ik[0] = carry_i;

    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : newgen
            half_adder name(
                .a_i(a_i[i]),
                .b_i(b_i[i]),
                .carry_i(carry_ik[i]),
                .sum_o(sum_o[i]),
                .carry_o(carry_ik[i + 1])
            );
        end
        assign carry_o = carry_ik[4];
    endgenerate
endmodule