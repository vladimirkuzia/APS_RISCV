`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 29.04.2024 14:12:37
// Design Name: 
// Module Name: bluster
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


module bluster
(
  input   logic clk_i,
  input   logic rst_i,

  input   logic rx_i,
  output  logic tx_o,

  output logic [ 31:0] instr_addr_o,
  output logic [ 31:0] instr_wdata_o,
  output logic         instr_write_enable_o,

  output logic [ 31:0] data_addr_o,
  output logic [ 31:0] data_wdata_o,
  output logic         data_write_enable_o,

  output logic core_reset_o
);

enum logic [3:0] {
  RCV_NEXT_COMMAND,
  INIT_MSG,
  RCV_SIZE,
  SIZE_ACK,
  FLASH,
  FLASH_ACK,
  WAIT_TX_DONE,
  FINISH}
state, next_state;

logic rx_busy, rx_valid, tx_busy, tx_valid;
logic [7:0] rx_data, tx_data;

uart_rx rx(
  .clk_i      (clk_i      ),
  .rst_i      (rst_i      ),
  .rx_i       (rx_i       ),
  .busy_o     (rx_busy    ),
  .baudrate_i (17'd115200 ),
  .parity_en_i(1'b1       ),
  .stopbit_i  (1'b1       ),
  .rx_data_o  (rx_data    ),
  .rx_valid_o (rx_valid   )
);

uart_tx tx(
  .clk_i      (clk_i      ),
  .rst_i      (rst_i      ),
  .tx_o       (tx_o       ),
  .busy_o     (tx_busy    ),
  .baudrate_i (17'd115200 ),
  .parity_en_i(1'b1       ),
  .stopbit_i  (1'b1       ),
  .tx_data_i  (tx_data    ),
  .tx_valid_i (tx_valid   )
);

logic [5:0] msg_counter;
logic [31:0] size_counter, flash_counter;
logic [3:0] [7:0] flash_size, flash_addr;

logic send_fin, size_fin, flash_fin, next_round;

assign send_fin   = (msg_counter    == 0)  && !tx_busy;
assign size_fin   = (size_counter   == 0)  && !rx_busy;
assign flash_fin  = (flash_counter  == 0)  && !rx_busy;
assign next_round = (flash_addr     != '1) && !rx_busy;

localparam INIT_MSG_SIZE  = 40;
localparam FLASH_MSG_SIZE = 57;
localparam ACK_MSG_SIZE   = 4;

logic [7:0] [7:0] flash_size_ascii, flash_addr_ascii;
// Блок generate позволяет создавать структуры модуля цикличным или условным
// образом. В данном случае, при описании непрерывных присваиваний была
// обнаружена закономерность, позволяющая описать четверки присваиваний в более
// общем виде, который был описан в виде цикла.
// Важно понимать, данный цикл лишь автоматизирует описание присваиваний и во
// время синтеза схемы развернется в четыре четверки непрерывных присваиваний.
genvar i;
generate
  for(i=0; i < 4; i=i+1) begin
    // Разделяем каждый байт flash_size и flash_addr на два ниббла.
    // Ниббл - это 4 бита. Каждый ниббл можно описать 16-ричной цифрой.
    // Если ниббл меньше 10 (4'ha), он описывается цифрами 0-9. Чтобы представить
    // его ascii-кодом, необходимо прибавить к нему число 8'h30
    // (ascii-код символа '0').
    // Если ниббл больше либо равен 10, он описывается буквами a-f. Для его
    // представления в виде ascii-кода, необходимо прибавить число 8'h57
    // (ascii-код символа 'a' - 8'h61).
    assign flash_size_ascii[i*2]    = flash_size[i][3:0] < 4'ha ? flash_size[i][3:0] + 8'h30 :
                                                                  flash_size[i][3:0] + 8'h57;
    assign flash_size_ascii[i*2+1]  = flash_size[i][7:4] < 4'ha ? flash_size[i][7:4] + 8'h30 :
                                                                  flash_size[i][7:4] + 8'h57;

    assign flash_addr_ascii[i*2]    = flash_addr[i][3:0] < 4'ha ? flash_addr[i][3:0] + 8'h30 :
                                                                  flash_addr[i][3:0] + 8'h57;
    assign flash_addr_ascii[i*2+1]  = flash_addr[i][7:4] < 4'ha ? flash_addr[i][7:4] + 8'h30 :
                                                                  flash_addr[i][7:4] + 8'h57;
  end
endgenerate

logic [INIT_MSG_SIZE-1:0][7:0] init_msg;
// ascii-код строки "ready for flash staring from 0xflash_addr\n"
assign init_msg = { 8'h72, 8'h65, 8'h61, 8'h64, 8'h79, 8'h20, 8'h66, 8'h6F,
                    8'h72, 8'h20, 8'h66, 8'h6C, 8'h61, 8'h73, 8'h68, 8'h20,
                    8'h73, 8'h74, 8'h61, 8'h72, 8'h69, 8'h6E, 8'h67, 8'h20,
                    8'h66, 8'h72, 8'h6F, 8'h6D, 8'h20, 8'h30, 8'h78,
                    flash_addr_ascii, 8'h0a};

logic [FLASH_MSG_SIZE-1:0][7:0] flash_msg;
//ascii-код строки: "finished write 0xflash_size bytes starting from 0xflash_addr\n"
assign flash_msg = {8'h66, 8'h69, 8'h6E, 8'h69, 8'h73, 8'h68, 8'h65, 8'h64,
                    8'h20, 8'h77, 8'h72, 8'h69, 8'h74, 8'h65, 8'h20, 8'h30,
                    8'h78,      flash_size_ascii,      8'h20, 8'h62, 8'h79,
                    8'h74, 8'h65, 8'h73, 8'h20, 8'h73, 8'h74, 8'h61, 8'h72,
                    8'h74, 8'h69, 8'h6E, 8'h67, 8'h20, 8'h66, 8'h72, 8'h6F,
                    8'h6D, 8'h20, 8'h30, 8'h78,     flash_addr_ascii,
                    8'h0a};
// логика сброса и переключения state машины                    
always_ff @(posedge clk_i)
    if(rst_i) begin 
        next_state <= RCV_NEXT_COMMAND;
        tx_valid <= 0;
        tx_data <= 0;
        flash_size <= 0;
        flash_addr <= 0;
        size_counter  <= 4;
        flash_counter <= flash_size;
        msg_counter <= INIT_MSG_SIZE-1;
        //дописать 
    end else begin 
        state <= next_state; 
    end

always_comb begin 
    instr_wdata_o = instr_wdata_o;
    instr_addr_o = instr_addr_o;
    instr_write_enable_o = 0;
    data_wdata_o = data_wdata_o;
    data_addr_o = data_addr_o;
    data_write_enable_o = 0;
    core_reset_o = 1;
    case(state)
      RCV_NEXT_COMMAND: begin 
        msg_counter = INIT_MSG_SIZE-1;
        flash_counter = flash_size;
        if(rx_valid) begin
            if(size_counter != 0) begin
                flash_addr = {flash_size[2:0],rx_data}; 
            end
            size_counter = size_counter - 1;
        end
        if(size_fin && next_round) begin 
            next_state = INIT_MSG; 
        end else if(size_fin && !next_round) begin
            next_state = WAIT_TX_DONE;
        end else next_state = state;   
      end 
      INIT_MSG: begin 
        size_counter = 4;
        flash_counter = flash_size;
        if(tx_busy == 0) tx_valid = 1;
        if(tx_valid) begin 
            if(msg_counter != 0) begin 
                tx_data = init_msg[msg_counter];
                msg_counter = msg_counter - 1;
            end   
        end 
        if(send_fin) begin 
            next_state = RCV_SIZE; 
        end else next_state = state;
      end 
      RCV_SIZE: begin 
        msg_counter = ACK_MSG_SIZE-1;
        if(rx_valid) begin
           if(size_counter != 0) begin
               flash_size = {flash_size[2:0],rx_data};
               size_counter = size_counter - 1;
           end
        end
        flash_counter = flash_size;
        if(size_fin) begin 
            next_state = SIZE_ACK; 
        end else next_state = state; 
      end
      SIZE_ACK: begin 
        size_counter = 4;
        flash_counter = flash_size;
        if(tx_busy == 0) tx_valid = 1;
        if(tx_valid) begin 
            if(msg_counter != 0) begin 
                tx_data = flash_size[msg_counter];
                msg_counter = msg_counter - 1;
            end
    
        end 
        if(send_fin) begin 
            next_state = FLASH; 
        end else next_state = state; 
      end 
      FLASH: begin 
        size_counter = 4;
        msg_counter = FLASH_MSG_SIZE-1;
        flash_counter = flash_counter - 1;
        if(rx_valid && (flash_addr < 1023)) begin
            if(flash_counter != 0) begin
              instr_wdata_o = {instr_wdata_o[23:0], rx_data};
              instr_write_enable_o = (flash_counter[1:0] == 2'b01);
              instr_addr_o = flash_addr + flash_counter - 1;
              
            end 
          
        end else if(rx_valid && (flash_addr >= 1023)) begin
                if(flash_counter != 0) begin
                  data_wdata_o = {data_wdata_o[23:0], rx_data};
                  data_write_enable_o = (flash_counter[1:0] == 2'b01);
                  data_addr_o  = flash_addr + flash_counter - 1;
                  
                end
            
        end
        if(flash_fin) begin 
            next_state = FLASH_ACK; 
        end else next_state = state; 
      end
      FLASH_ACK: begin 
        size_counter = 4;
        flash_counter = flash_size;
        if(tx_busy == 0) tx_valid = 1;
        if(tx_valid) begin 
            if(msg_counter != 0) begin 
                tx_data = flash_msg[msg_counter];
                msg_counter = msg_counter - 1;  
            end
  
        end 
        if(send_fin) begin 
            next_state = RCV_NEXT_COMMAND; 
        end else next_state = state; 
      end
      WAIT_TX_DONE: begin 
        size_counter = 4;
        flash_counter = flash_size;
        msg_counter = msg_counter;
        if(!tx_busy) begin 
            next_state = FINISH; 
        end else next_state = state; 
      end
      FINISH: begin 
        size_counter = 4;
        flash_counter = flash_size;
        msg_counter = msg_counter;
        core_reset_o = 0;
        next_state = RCV_NEXT_COMMAND; 
      end
    endcase
end



endmodule