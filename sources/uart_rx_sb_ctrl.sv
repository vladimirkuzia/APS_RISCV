`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.04.2024 10:56:12
// Design Name: 
// Module Name: uart_rx_sb_ctrl
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


module uart_rx_sb_ctrl(
/*
    Часть интерфейса модуля, отвечающая за подключение к системной шине
*/
  input  logic          clk_i,
  input  logic          rst_i,
  input  logic [31:0]   addr_i,
  input  logic          req_i,
  input  logic [31:0]   write_data_i,
  input  logic          write_enable_i,
  output logic [31:0]   read_data_o,

/*
    Часть интерфейса модуля, отвечающая за отправку запросов на прерывание
    процессорного ядра
*/

  output logic        interrupt_request_o,
  input  logic        interrupt_return_i,

/*
    Часть интерфейса модуля, отвечающая за подключение передающему,
    входные данные по UART
*/
  input  logic          rx_i
);

  logic busy;
  logic [16:0] baudrate;
  logic parity_en;
  logic stopbit;
  logic [7:0]  data;
  logic valid;
  logic validq;
  logic rst_reg;
  
  uart_rx uart_ctrl(
    .clk_i(clk_i),
    .rst_i(rst_reg),
    .rx_i(rx_i),
    .busy_o(busy),
    .baudrate_i(baudrate),
    .parity_en_i(parity_en),
    .stopbit_i(stopbit),
    .rx_data_o(rx_data_o),
    .rx_valid_o(validq)
  );
  
  always_ff @(posedge clk_i) begin 
      if (rst_i || rst_reg) begin 
        valid <= 0;
        data <= 0;
      end else if (validq) begin 
        data  <= rx_data_o;
        valid <= 1; 
       end
       if(req_i && !write_enable_i)begin
            if(addr_i == 32'h0) begin 
                read_data_o <= data;
                valid <= 0;
            end else if(addr_i == 32'h04) begin
                read_data_o <= valid;
            end else if(addr_i == 32'h08) begin 
                read_data_o <= busy;
            end else if(addr_i == 32'h0c) begin 
                read_data_o <= baudrate;
            end else if(addr_i == 32'h10) begin 
                read_data_o <= parity_en;
            end else if(addr_i == 32'h14) begin
                read_data_o <= stopbit;
            end
       end
  end 
  
  always_ff @(posedge clk_i) begin
    if (rst_i || rst_reg) begin
                busy        <= 0;     
                read_data_o <= 0; 
                baudrate    <= 9600;
                parity_en   <= 1;
                stopbit     <= 1;
    end else begin  
        if  (write_enable_i && !busy) begin
            if (addr_i == 32'h0c)  begin 
                baudrate <= write_data_i;
                rst_reg <= 0;
            end 
            else if (addr_i == 32'h10) begin
                parity_en <= write_data_i; 
                rst_reg <= 0;
            end
            else if (addr_i == 32'h14) begin 
                stopbit <= write_data_i;
                rst_reg <= 0;
            end
            else if (addr_i == 32'h24) begin 
                rst_reg <= 1;
            end
        end
    end
end

assign interrupt_request_o = valid;

endmodule
