`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.10.2023 22:30:43
// Design Name: 
// Module Name: riscv_unit
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

module riscv_unit(
    input  logic        clk_i,
    input  logic        resetn_i,
   // input  logic [31:0] int_req_i,
//    input logic [31:0] int_req,
//    output logic [31:0] int_fin_o,
    //output logic  [31:0] PC,
    //output logic [31:0]mem_wd_o,
   // output logic [31:0] data_addr_o,
   // output logic [31:0] instr_addr_o,
   // output logic [31:0] MEM_RD_I,
    //output logic [31:0] int_fin,
    // Входы и выходы периферии
  input  logic            rx_i,
  output logic            tx_o   // Линия передачи по UART
//    input  logic [15:0] sw_i,       // Переключатели
//    output logic [15:0] led_o      // Светодиоды
    );
    
    logic [31:0] instr_i;
    logic [31:0] mem_rd_i;
    //memory protocol
    logic [31:0] data_rdata;
    logic data_req;
    logic data_we;        
    logic [3:0] data_be;   
    logic [31:0] data_addr;
    logic [31:0] data_wdata;
    logic [31:0] mcause;
    logic [31:0] mie;
    logic [31:0] instr_addr_o;
    logic [31:0] bl_instr_addr_o;
    
    logic          interrupt;
    logic          INT_RST1;
    logic          reg_dev;
    logic [255:0]  one_hot_o;
    logic [31:0 ]  in_1_o;
    logic [31:0 ]  rd_data;
    logic [31:0 ]  rd_sw;
    logic [31:0 ]  rd_led;
    logic [31:0 ]  rd_uart_rx;
    logic [31:0 ]  rd_uart_tx;
    logic [31:0 ]  read_data_o;
    logic [31:0 ]  read_data_o1;
    logic [31:0 ]  timer_prdata_ff;
    logic [31:0 ]  timer_prdata;
    
   //uart protocol 
    logic            uart_psel;
    logic            uart_penable;
    logic            uart_pwrite;
    logic [32-1:0]   uart_paddr;
    logic [32-1:0]   uart_pwdata;
    logic [32-1:0]   uart_prdata;
    logic            uart_pready;
    logic [32-1:0]   uart_prdata_ff; 
       // assign MEM_RD_I = mem_rd_i;
   //logic [31:0] int_req;
   
    logic stall;
    logic mem_we_o;
    logic mem_req_o;
    logic stall_i; 
    logic core_reset_o; 
    logic sysclk, rst;
    logic [31:0] fin_int;
    logic [31:0] bl_data_wdata_o;
    logic [31:0] rd;
    logic [31:0] wdata;
    logic [31:0] addr;
    logic [31:0] data_wdata_c;
    logic [2:0] mem_size;
    
    logic [255:0] periph_request;
    logic instr_write_enable_o;
    logic memory_request;
    logic mem_req;
    logic uart_tx_request;
    logic uart_rx_request;
    logic read_req;
    logic irq_ret;
     // one hot encoder
    assign periph_request = 255'd1 << data_addr[31:24]; 
    //
    assign mem_req         = memory_request & periph_request[0];
    assign uart_tx_request = memory_request & periph_request[6];
    assign uart_rx_request = memory_request & periph_request[5];
    assign read_req        = memory_request & periph_request[8];
  
  assign uart_psel       = ((data_addr[31] == 'b1) && (data_addr[12] != 'b1)) ? data_req : 'b0;
  assign uart_penable    = uart_psel;
  assign uart_pwrite     = data_we;
  assign uart_paddr      = data_addr;
  assign uart_pwdata     = data_wdata;

  always_ff @(posedge clk_i) begin
    if (uart_psel)
      uart_prdata_ff <= uart_prdata;
  end
 
  always_comb begin 
    case(data_addr[31:24])
        8'd0: in_1_o = rd_data;
    //    8'd1: in_1_o = rd_sw;
    //    8'd2: in_1_o = rd_led;
        8'd5: in_1_o = rd_uart_rx;
        8'd6: in_1_o = rd_uart_tx;
        8'd8: in_1_o = read_data_o1;
    default: in_1_o = rd_data;
    endcase
 end
   
    sys_clk_rst_gen divider(
                    .ex_clk_i(clk_i),
                    .ex_areset_n_i(resetn_i),
                    .div_i(4'd5),
                    .sys_clk_o(sysclk),
                    .sys_reset_o(rst)
    ); 

    riscv_core core(
                    .clk_i(sysclk),
                    .rst_i(rst),
                    .stall_i(stall),
                    .instr_i(instr_i),
                    .mem_rd_i(in_1_o),
                    .instr_addr_o(instr_addr_o),
                    .mem_addr_o(addr),
                    .mem_size_o(mem_size),
                    .mem_req_o(data_req),
                    .mem_we_o(data_we),
                    .mem_wd_o(data_wdata_c),
                    .irq_req_i(interrupt_request_o),
                    .irq_ret_o(irq_ret)
     );
     
     riscv_lsu lsu(
                    .clk_i(sysclk),
                    .rst_i(rst),
                    .core_req_i(data_req),
                    .core_we_i(data_we),
                    .core_size_i(mem_size),
                    .core_addr_i(addr),
                    .core_wd_i(data_wdata_c),
                    .core_rd_o(rd),
                    .core_stall_o(stall),
                    .mem_req_o(memory_request),
                    .mem_we_o(),
                    .mem_be_o(data_be),
                    .mem_addr_o(data_addr),
                    .mem_wd_o(data_wdata),
                    .mem_rd_i(in_1_o),
                    .mem_ready_i(1'b1)
      );

//      miriscv_ram rm(
//                  .clk_i(sysclk),
//                  .rst_n_i(!rst),
//                  .instr_rdata_o(instr_i),
//                  .instr_addr_i(instr_addr_o),
//                  .data_rdata_o(rd_data),
//                  .data_req_i(mem_req),
//                  .data_we_i(data_we),
//                  .data_be_i(data_be),
//                  .data_addr_i(data_addr),
//                  .data_wdata_i(data_wdata)
//      );

//    bluster n_blust(
//                .clk_i(sysclk),
//                .rst_i(!rst),
//                .rx_i(rx_i),
//                .tx_o(tx_o),
//                .instr_addr_o(bl_instr_addr_o),
//                .instr_wdata_o(wdata),
//                .instr_write_enable_o(instr_write_enable_o),
//                .data_addr_o(),
//                .data_wdata_o(bl_data_wdata_o),
//                .data_write_enable_o(),
//                .core_reset_o(core_reset_o)
//    );    
    
//    rw_instr_mem mmerm(
//                .clk_i(sysclk),
//                .read_addr_i(instr_addr_o),
//                .read_data_o(instr_i),
//                .write_addr_i(bl_instr_addr_o),
//                .write_data_i(wdata),
//                .write_enable_i(instr_write_enable_o)
//    );
    
//    ext_mem ext(
//                .clk_i(sysclk),
//                .mem_req_i(memory_request),
//                .write_enable_i(data_we),
//                .byte_enable_i(data_be),
//                .addr_i(data_addr),
//                .write_data_i(data_wdata),
//                .read_data_o(rd_data),
//                .ready_o()
//    );

////////////////////////////////////////////////////////////////////
    miriscv_ram rm(   
                .clk_i(sysclk),
                .rst_n_i(!rst),
                .instr_rdata_o(instr_i),
                .instr_addr_i(instr_addr_o),
                .data_req_i(memory_request),
                .data_we_i(data_we),
                .data_be_i(data_be),
                .data_addr_i(data_addr),
                .data_wdata_i(data_wdata),
                .data_rdata_o(rd_data)
    );   
////////////////////////////////////////////////////////////////////    
//    instr_mem mem(
//        .addr_i(instr_addr_o),
//        .read_data_o2(instr_i)
//    );
//////////////////////////////////////////////////////////////////    
//
//     data_mem mem2(
//        .clk_i(sysclk),
//        .mem_req_i(memory_request),
//        .write_enable_i(data_we),
//        .addr_i(data_addr),
//        .write_data_i(data_wdata),
//        .read_data_o(rd_data)
//    );
////////////////////////////////////////////////////////////////////    
//    sw_sb_ctrl sw(.clk_i(sysclk),
//                  .rst_i(rst),
//                  .req_i(data_req && one_hot_o[1]),
//                  .write_enable_i(data_we),
//                  .addr_i({8'd0,data_addr[23:0]}),
//                  .write_data_i(data_wdata),
//                  .read_data_o(rd_sw),
//                  .sw_i(sw_i)
//    );
//////////////////////////////////////////////////////////////////    
    timer_sb_ctrl timer(
                 .clk_i(sysclk),
                 .rst_i(rst),
                 .req_i(read_req),
                 .write_enable_i(data_we),
                 .addr_i({8'd0,data_addr[23:0]}),
                 .write_data_i(data_wdata),              
                 .read_data_o(read_data_o1),
                 .ready_o(),
                 .interrupt_request_o(int_req)
    );
    
    uart_rx_sb_ctrl rx(
                .clk_i(sysclk),
                .rst_i(rst),
                .addr_i({8'd0,data_addr[23:0]}),
                .req_i(uart_rx_request),
                .write_data_i(data_wdata),
                .write_enable_i(data_we),
                .read_data_o(rd_uart_rx),
                .interrupt_request_o(interrupt_request_o),
                .interrupt_return_i(irq_ret),
                .rx_i(rx_i)
    );
    
    uart_tx_sb_ctrl tx(
                .clk_i(sysclk),
                .rst_i(rst),
                .addr_i({8'd0,data_addr[23:0]}),
                .req_i(uart_tx_request),
                .write_data_i(data_wdata),
                .write_enable_i(data_we),
                .read_data_o(rd_uart_tx),
                .tx_o(tx_o)
    );
////////////////////////////////////////////////////////////////////    
//    led_sb_ctrl led(.clk_i(sysclk),
//                 .rst_i(rst),
//                 .req_i(data_req && one_hot_o[2]),
//                 .write_enable_i(data_we),
//                 .addr_i({8'd0,data_addr[23:0]}),
//                 .write_data_i(data_wdata),
//                 .read_data_o(rd_led),
//                 .led_o(led_o)
//    );
////////////////////////////////////////////////////////////////////
endmodule

