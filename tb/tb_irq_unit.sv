/* -----------------------------------------------------------------------------
* Project Name   : Architectures of Processor Systems (APS) lab work
* Organization   : National Research University of Electronic Technology (MIET)
* Department     : Institute of Microdevices and Control Systems
* Author(s)      : Andrei Solodovnikov
* Email(s)       : hepoh@org.miet.ru

See https://github.com/MPSU/APS/blob/master/LICENSE file for licensing details.
* ------------------------------------------------------------------------------
*/
module tb_irq_unit();

    reg clk;
    reg rst;
    reg [31:0] int_req;
    
    
    riscv_unit unit(
    .clk_i(clk),
    .resetn_i(rst),
    .int_req(int_req)
    );

    initial begin
      repeat(1000) begin
        @(posedge clk);
      end
      $fatal(1, "Test has been interrupted by watchdog timer");
    end

    initial clk = 0;
    always #10 clk = ~clk;

    initial begin
        $display( "\nStart test: \n\n==========================\nCLICK THE BUTTON 'Run All'\n==========================\n"); $stop();
        int_req = 0;
        rst = 1;
        #20;
        rst = 0;
        int_req = 1;
        repeat(20)@(posedge clk);
        int_req = 1;
        while(int_req == 0) begin
          @(posedge clk);
        end
        int_req = 0;
        repeat(20)@(posedge clk);
        $display("\n The test is over \n See the internal signals of the module on the waveform \n");
        $finish;
    end

endmodule
