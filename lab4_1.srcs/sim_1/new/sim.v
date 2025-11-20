`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 10/13/2025 07:30:10 PM
// Design Name:
// Module Name: sim
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

module lab4Test;
    reg clk;
	top SCP (clk);
    initial begin
        clk=0;
        forever #1 clk = ~clk;
    end
    initial begin
        while ($time < 60) @(posedge clk)begin
            $display("===============================================");
            $display("Clock cycle %d, PC = %H", $time/2, SCP.IF_PCout);
            $display("ra = %H, t0 = %H, t1 = %H", SCP.ID_stage.rf.regMem[1], SCP.ID_stage.rf.regMem[5], SCP.ID_stage.rf.regMem[6]);
            $display("t2 = %H, t3 = %H, t4 = %H", SCP.ID_stage.rf.regMem[7], SCP.ID_stage.rf.regMem[28], SCP.ID_stage.rf.regMem[29]);
            $display("===============================================");
        end
        $finish();
    end
endmodule
