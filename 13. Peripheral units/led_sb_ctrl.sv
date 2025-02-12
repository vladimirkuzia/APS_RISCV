`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.12.2023 19:02:41
// Design Name: 
// Module Name: led_sb_ctrl
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

module led_sb_ctrl(
/*
    Часть интерфейса модуля, отвечающая за подключение к системной шине
*/
  input  logic        clk_i,
  input  logic        rst_i,
  input  logic        req_i,
  input  logic        write_enable_i,
  input  logic [31:0] addr_i,
  input  logic [31:0] write_data_i,
  output logic [31:0] read_data_o,

/*
    Часть интерфейса модуля, отвечающая за подключение к периферии
*/
  output logic [15:0]  led_o
);

logic [15:0]  led_val;
logic         led_mode;
logic [31:0]  count; 
logic         led_rst;

assign led_o = led_val;

always_ff @(posedge clk_i) begin 
       if( led_mode ) begin 
        count <= count + 1;
        led_val <= 0;
          if( count == 100000 ) begin
                led_val <= write_data_i;
                count <= 0;
           end
       end
       if( req_i == 1 && write_enable_i == 1 && addr_i == 0 && write_data_i <= 65635 ) begin
            led_val <= write_data_i;
       end
       
       if( req_i == 1 && write_enable_i == 1 && addr_i == 32'h4 && write_data_i <= 1 ) begin 
       led_mode <= 1;
       end 
       
       if( req_i == 1 && write_enable_i == 1 && addr_i == 32'h24 && write_data_i == 1) begin 
       led_rst <= 1;
       end 
       
       if( led_rst ) begin 
           led_val <= 0;
           led_mode <= 0;
           led_rst <= 0;
           count <= 0;
       end    
end

always_comb begin 
        if (req_i == 1 && write_enable_i == 0 && addr_i == 0 && write_data_i <= 65635) begin
                read_data_o <= led_val;
        end                         
        
        
        if (req_i == 1 && write_enable_i == 0 && addr_i == 32'h4 && write_data_i <= 1) begin
                read_data_o <= led_mode;
        end                         
end
endmodule
