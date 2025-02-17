`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07.11.2023 18:31:52
// Design Name: 
// Module Name: miriscv_lsu
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


module riscv_lsu(
  input logic clk_i,
  input logic rst_i,

  // Интерфейс с ядром
  input  logic        core_req_i,
  input  logic        core_we_i,
  input  logic [ 2:0] core_size_i,
  input  logic [31:0] core_addr_i,
  input  logic [31:0] core_wd_i,
  output logic [31:0] core_rd_o,
  output logic        core_stall_o,

  // Интерфейс с памятью
  output logic        mem_req_o,
  output logic        mem_we_o,
  output logic [3:0 ] mem_be_o,
  output logic [31:0] mem_addr_o,
  output logic [31:0] mem_wd_o,
  input  logic [31:0] mem_rd_i,
  input  logic        mem_ready_i
);
  import riscv_pkg::*;
  
  logic [1:0 ]  byte_offset;
  logic         half_offset;
  logic [3:0 ]  mux_ldst_h_in;
  logic [31:0]  de_mux_ldst_b;
  logic [31:0]  de_mux_ldst_bu;
  logic [31:0]  de_mux_ldst_h;
  logic [31:0]  de_mux_ldst_hu;
  
  logic         stall;
  logic         stall_i;
  
  assign byte_offset    = core_addr_i[1:0];
  assign half_offset    = core_addr_i[1];
  assign mux_ldst_h_in  = half_offset? 4'b1100 : 4'b0011;
  
always_comb begin 
    case(core_size_i) 
        LDST_B:  mem_be_o = 4'b0001 << byte_offset;
        LDST_H:  mem_be_o = mux_ldst_h_in;
        LDST_W:  mem_be_o = 4'b1111;
        default: mem_be_o = 4'b1111; 
    endcase
end

always_comb begin 
    case(byte_offset) 
        2'b00:   de_mux_ldst_b = {{24{mem_rd_i[7]}},  mem_rd_i[7:0]};
        2'b01:   de_mux_ldst_b = {{24{mem_rd_i[15]}}, mem_rd_i[15:8]};
        2'b10:   de_mux_ldst_b = {{24{mem_rd_i[23]}}, mem_rd_i[23:16]};
        2'b11:   de_mux_ldst_b = {{24{mem_rd_i[31]}}, mem_rd_i[31:24]};
        default: de_mux_ldst_b = 32'd0; 
    endcase
end

always_comb begin 
    case(byte_offset) 
        2'b00:   de_mux_ldst_bu = {24'b0, mem_rd_i[7:0]};
        2'b01:   de_mux_ldst_bu = {24'b0, mem_rd_i[15:8]};
        2'b10:   de_mux_ldst_bu = {24'b0, mem_rd_i[23:16]};
        2'b11:   de_mux_ldst_bu = {24'b0, mem_rd_i[31:24]};
        default: de_mux_ldst_bu = 32'd0; 
    endcase
end

assign de_mux_ldst_h  = half_offset ? {{16{mem_rd_i[31]}}, mem_rd_i[31:16]} : {{16{mem_rd_i[15]}}, mem_rd_i[15:0]};
assign de_mux_ldst_hu = half_offset ? {16'b0, mem_rd_i[31:16]}              : {16'b0, mem_rd_i[15:0]};

always_comb begin 
    case(core_size_i)
        LDST_B :  core_rd_o = de_mux_ldst_b;
        LDST_H :  core_rd_o = de_mux_ldst_h;
        LDST_W :  core_rd_o = mem_rd_i;
        LDST_BU:  core_rd_o = de_mux_ldst_bu;
        LDST_HU:  core_rd_o = de_mux_ldst_hu;
        default:  core_rd_o = mem_rd_i;
    endcase
end 

always_comb begin 
    case(core_size_i)
        LDST_B:  mem_wd_o = {{4{core_wd_i[7:0]}}};
        LDST_H:  mem_wd_o = {{2{core_wd_i[15:0]}}};
        LDST_W:  mem_wd_o = core_wd_i;
        default: mem_wd_o = core_wd_i;
    endcase
end 

always_ff @(posedge clk_i) begin 
    if (rst_i) stall <= 0; 
    else stall <= stall_i;
end

assign stall_i      = ((~(stall & mem_ready_i)) & core_req_i);
assign core_stall_o = stall_i; 
assign mem_addr_o   = core_addr_i; 
assign mem_req_o    = core_req_i; 
assign mem_we_o     = core_we_i;

endmodule