`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.09.2023 23:33:25
// Design Name: 
// Module Name: cybercobra
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module CYBERcobra (
  input  logic         clk_i,
  input  logic         rst_i,
  input  logic [15:0]  sw_i,
  output logic [31:0]  out_o
);

logic [31:0] a_to_rd1;
logic [31:0] b_to_rd2;
logic [31:0] res_to_wd1;
logic [31:0] wdi;

logic [31:0] PC;
logic [31:0] read_data_o;

logic [31:0] B;
logic flag_o;

always_comb begin
    case(read_data_o[30] && flag_o || read_data_o[31])
        0: B <= 32'd4;
        1: B <= {{22{read_data_o[12]}}, read_data_o[12:5], 2'b0};
    endcase
end

 always_ff @(posedge clk_i) begin
    if (rst_i)
        PC <= 0;
    else 
        PC <= PC + B;
 end

always_comb begin
    case(read_data_o[29:28])
    0: wdi <= {{9{read_data_o[27]}}, read_data_o[27:5]};
    1: wdi <= res_to_wd1;
    2: wdi <= {{16{sw_i[15]}}, sw_i[15:0]};
    3: wdi <= 0;
    endcase
end

rf_riscv reg_f(.clk_i(clk_i), 
               .write_enable_i(!(read_data_o[30] || read_data_o[31])), 
               .write_addr_i(read_data_o[4:0]), 
               .read_addr1_i(read_data_o[22:18]), 
               .read_addr2_i(read_data_o[17:13]), 
               .write_data_i(wdi), 
               .read_data1_o(a_to_rd1), 
               .read_data2_o(b_to_rd2)
);

alu_rscv alu(.a(a_to_rd1), 
             .b(b_to_rd2), 
             .alu_op(read_data_o[27:23]), 
             .flag(flag_o), 
             .result(res_to_wd1)
);

instr_mem mem(.addr_i(PC), .read_data_o(read_data_o));

assign out_o = a_to_rd1;

endmodule
