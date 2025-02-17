module rw_instr_mem
#(
  parameter RAM_INIT_FILE  = "program.txt",
  parameter DRAM_INIT_FILE = "program1.txt"
)(
    input  logic        clk_i,
    input  logic [31:0] read_addr_i,
    output logic [31:0] read_data_o,
    
    input  logic [31:0] write_addr_i,
    input  logic [31:0] write_data_i,
    input  logic        write_enable_i
);


logic [31:0] reg_instr [0:16383];

initial begin
    $readmemh(RAM_INIT_FILE, reg_instr);
end

always_ff @(posedge clk_i) begin
    if (write_enable_i) reg_instr[write_addr_i[15:2]] <= write_data_i;
end

assign read_data_o = reg_instr[read_addr_i[15:2]];

endmodule