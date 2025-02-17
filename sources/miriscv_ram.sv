module miriscv_ram
#(
  parameter RAM_SIZE       = 65536, // bytes
  parameter RAM_INIT_FILE  = "program.txt",
  parameter DRAM_INIT_FILE = "program1.txt"
)
(
  // clock, reset
  input clk_i,
  input rst_n_i,

  // instruction memory interface
  output logic  [31:0]  instr_rdata_o,
  input         [31:0]  instr_addr_i,

  // data memory interface
  output logic  [31:0]  data_rdata_o,
  input                 data_req_i,
  input                 data_we_i,
  input         [3:0]   data_be_i,
  input         [31:0]  data_addr_i,
  input         [31:0]  data_wdata_i
);

  reg [31:0]    mem  [0:RAM_SIZE/4-1];
  reg [31:0]    dmem [0:RAM_SIZE/4-1];
  
  //Init RAM
  integer ram_index;
  integer dram_index;

  initial begin
    if(RAM_INIT_FILE != "")
      $readmemh(RAM_INIT_FILE, mem);
    else for (ram_index = 0; ram_index < RAM_SIZE/4-1; ram_index = ram_index + 1)
        mem[ram_index] = {32{1'b0}};

    //else

  end
  
  initial begin
    if(DRAM_INIT_FILE != "")
      $readmemh(DRAM_INIT_FILE, dmem);
    else for (dram_index = 0; dram_index < RAM_SIZE/4-1; dram_index = dram_index + 1)
      dmem[dram_index] = {32{1'b0}};

  end


  //Instruction port
  assign instr_rdata_o = mem[instr_addr_i[15:2]];

  always@(posedge clk_i) begin
    if(!rst_n_i) begin
      data_rdata_o  <= 32'b0;
    end
    else if(data_req_i) begin
        if( data_we_i && data_be_i[0])
          dmem [data_addr_i[15:2]] [7:0]   <= data_wdata_i[7:0];
        if( data_we_i && data_be_i[1])
          dmem [data_addr_i[15:2]] [15:8]  <= data_wdata_i[15:8];
        if( data_we_i && data_be_i[2])
          dmem [data_addr_i[15:2]] [23:16] <= data_wdata_i[23:16];
        if( data_we_i && data_be_i[3])
          dmem [data_addr_i[15:2]] [31:24] <= data_wdata_i[31:24];
    end
    data_rdata_o = dmem[(data_addr_i[15:2])];
end

endmodule