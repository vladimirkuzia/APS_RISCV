`timescale 1ns / 1ps

module interrupt_controller(
  input  logic        clk_i,
  input  logic        rst_i,
  input  logic        exception_i,
  input  logic        irq_req_i,
  input  logic        mie_i,
  input  logic        mret_i,

  output logic        irq_ret_o,
  output logic [31:0] irq_cause_o,
  output logic        irq_o
);

logic irq_and_mie;
logic nor_wire;
logic irq_o_wire;
logic irq_ret_wire;

logic exc_h_D_wire;
logic irq_h_D_wire;

logic exception_or_exc_h_wire;
logic irq_or_irq_h_wire;

logic exc_h;
logic irq_h;


always_ff @(posedge clk_i) begin 
    if (rst_i) begin
        exc_h <= 0;
    end else begin
        exc_h <= exc_h_D_wire;
    end
end

always_ff @(posedge clk_i) begin 
    if (rst_i) begin
        irq_h <= 0;
    end else begin
        irq_h <= irq_h_D_wire;
    end
end


always_comb begin 

    exception_or_exc_h_wire = exception_i | exc_h;
    exc_h_D_wire = exception_or_exc_h_wire & ~mret_i;
end

always_comb begin 
    irq_or_irq_h_wire = irq_o_wire | irq_h;
    irq_h_D_wire = irq_or_irq_h_wire & ~irq_ret_wire;
end

assign nor_wire = ~(irq_h | exception_or_exc_h_wire);
assign irq_ret_wire = mret_i & ~exception_or_exc_h_wire;
assign irq_and_mie = irq_req_i & mie_i;  
assign irq_o_wire = irq_and_mie & nor_wire;  
assign irq_cause_o = 32'h1000_0010;
assign irq_o = irq_o_wire;  
assign irq_ret_o = irq_ret_wire;

endmodule