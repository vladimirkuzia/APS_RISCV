`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.09.2023 13:33:11
// Design Name: 
// Module Name: fulladder
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


module fulladder(
    input logic a,
    input logic b,
    input logic cin,
    output logic sum,
    output logic cout
);
assign sum = (a ^ b) ^ cin;
assign cout = ((a & b)|(a & cin))|(b & cin);
endmodule
