`timescale 1ns / 1ps

module tb_miriscv_top();
      
  parameter     RST_WAIT = 20;         // 10 ns reset
  parameter     RAM_SIZE = 512;       // in 32-bit words

  // clock, reset
  reg clk;
  reg rst_n;
  reg [31:0] int_req;

  riscv_unit #(
    .RAM_SIZE       ( RAM_SIZE           ),
    .RAM_INIT_FILE  ( "program.txt" )
  ) dut (
    .clk_i    ( clk   ),
    .rst_i  ( rst_n ),
    .int_req_i (int_req)
  );

  initial begin
    int_req = 0;
    clk   = 1'b0;
    rst_n = 1'b1;
    #RST_WAIT;
    rst_n = 1'b0; 
    #1000
    int_req = 32'hffffffff;
    #2000;
end
  always #10  begin
    clk = ~clk;
  end

endmodule