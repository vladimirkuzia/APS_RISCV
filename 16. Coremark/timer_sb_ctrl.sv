
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.04.2024 15:21:59
// Design Name: 
// Module Name: timer_sb_ctrl
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


module timer_sb_ctrl(
/*
    Часть интерфейса модуля, отвечающая за подключение к системной шине
*/
  input  logic        clk_i,
  input  logic        rst_i,
  input  logic        req_i,
  input  logic        write_enable_i,
  input  logic [31:0] addr_i,
  input  logic [31:0] write_data_i,  // не используется, добавлен для
                                     // совместимости с системной шиной
  output logic [31:0] read_data_o,
  output logic        ready_o,
/*
    Часть интерфейса модуля, отвечающая за отправку запросов на прерывание
    процессорного ядра
*/
  output logic        interrupt_request_o
);

logic [63:0] system_counter;
logic [63:0] delay;
enum logic [1:0] {OFF, NTIMES, FOREVER1} mode, next_mode;
logic [31:0] repeat_counter;
logic [63:0] system_counter_at_start;

always_comb begin
    if( write_enable_i == 1 && req_i == 1) begin
        ready_o = 1;
    end    
    case (addr_i[7:0])
        32'h0:  read_data_o    = system_counter;
        32'h4:  delay          = write_data_i;
        32'h8:  begin
            case(write_data_i)
                0: next_mode = OFF;
                1: next_mode = NTIMES;
                2: next_mode = FOREVER1;
                default: next_mode = OFF; 
            endcase
        end
        32'hC:  repeat_counter = write_data_i;
        32'h24: read_data_o = 0;
        default: read_data_o = 0; 
    endcase   
end

always_ff @(posedge clk_i) begin
    if(rst_i) begin 
        system_counter <= 0;
               ready_o <= 0; 
    end else begin
 
        system_counter <= system_counter + 1;
        mode <= next_mode; 
    end //if (write_enable_i && req_i) begin

//        ready_o <= 0;
//    end       
end 

always_comb
    case(mode)
        OFF: begin
            system_counter_at_start = 0;
            interrupt_request_o = 0;
        end
        NTIMES: begin
                system_counter_at_start = system_counter;
            if ( (system_counter - system_counter_at_start) == delay ) begin
                //interupt
                interrupt_request_o = 1;
                system_counter_at_start = system_counter;
                repeat_counter = repeat_counter - 1;
            end 
            if (repeat_counter == 0) begin
                next_mode = OFF;
            end
        end
        FOREVER1: begin
            if (system_counter == delay) begin
                //interupt
                interrupt_request_o = 1;
            end
        end
    endcase
endmodule 
