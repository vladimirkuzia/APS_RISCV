`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.09.2023 20:24:13
// Design Name: 
// Module Name: 
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


module instr_mem(
  input  logic [31:0] addr_i,
  output logic [31:0] read_data_o2
);

logic [31:0] memory [0:16384];

initial $readmemh("program.txt", memory);

always_comb begin
    if (addr_i < 16381) begin
        read_data_o2 = {memory[addr_i[9:0] + 3], memory[addr_i[9:0] + 2], memory[addr_i[9:0] + 1], memory[addr_i[9:0]] };
    end 
    else begin
        read_data_o2 = 0;
    end
end

endmodule
