`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/20 02:23:43
// Design Name: 
// Module Name: lab4sim
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: c
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module lab4sim;
    reg clk;
	top SCP (clk);
    initial begin
        clk=0;
        forever #1 clk = ~clk;
    end
    initial begin
        while ($time < 60) @(posedge clk)begin
            $display("===============================================");
            $display("Clock cycle %d, PC = %H", $time/2, SCP.pc);
            $display("ra = %H, t0 = %H, t1 = %H", SCP.i_reg_file.regs[1], SCP.i_reg_file.regs[5], SCP.i_reg_file.regs[6]);
            $display("t2 = %H, t3 = %H, t4 = %H", SCP.i_reg_file.regs[7], SCP.i_reg_file.regs[28], SCP.i_reg_file.regs[29]);
            $display("===============================================");
        end
        $finish();
    end
    
endmodule
