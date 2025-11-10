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


// sim.v
module sim;
  parameter half_period = 3;
  reg clk, rst;
  top SCP(.clock(clk));   // add reset to top (see §2)

  // clock: known from t=0
  initial clk = 0;
  always #(half_period) clk = ~clk;

  // reset: hold for a couple of cycles
  initial begin
    rst = 1;
    repeat (2) @(posedge clk);
    rst = 0;
  end

  // print *after* each posedge so you see committed state
  initial begin
    forever begin
      @(posedge clk);
      #1;  // tiny delay to let combo settle
      $display("time:%8t", $time);
      $display("PC:%08h",  SCP.pc);
      $display("Inst:%08h", SCP.inst);
      $display("x5(t0):%08h",  SCP.i_reg_file.regs[5]);
      $display("x6(t1):%08h",  SCP.i_reg_file.regs[6]);
      $display("x7(t2):%08h",  SCP.i_reg_file.regs[7]);
      $display("x28(t3):%08h", SCP.i_reg_file.regs[28]);
      $display("x29(t4):%08h", SCP.i_reg_file.regs[29]);
      $display("x8(s0):%08h",  SCP.i_reg_file.regs[8]);
      $display("x9(s1):%08h",  SCP.i_reg_file.regs[9]);
      $display("Mem[0]:%08h", {SCP.i_data_mem.mem[3],SCP.i_data_mem.mem[2],SCP.i_data_mem.mem[1],SCP.i_data_mem.mem[0]});
      $display("Mem[4]:%08h", {SCP.i_data_mem.mem[7],SCP.i_data_mem.mem[6],SCP.i_data_mem.mem[5],SCP.i_data_mem.mem[4]});
    end
  end

  initial #110 $stop;
endmodule


