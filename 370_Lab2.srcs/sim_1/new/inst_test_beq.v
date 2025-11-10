`timescale 1ns/1ps
module inst_test_beq;

  // ---------------- clock ----------------
  reg clock = 0;
  always #50 clock = ~clock; // 100 ns period (times are 100000, 200000, 300000, ...)

  // ---------------- DUT ------------------
  top dut(.clock(clock));

  // ---------------- program load (your style) ----------------
  initial begin
    // Wait 1ns to avoid racing the inst_mem initial zeroing
    #1;
    // Program @ 0x00:
    // 0x00: addi t0, x0, 67           -> 32'h0430_0293
    // 0x04: add  t1, x0, t0           -> 32'h0050_0333
    // 0x08: beq  t1, t0, IS_EQUAL     -> 32'h0053_0463  (taken, skips 0x0C)
    // 0x0C: addi t2, x0, 1            -> 32'h0010_0393  (skipped)
    // 0x10: IS_EQUAL: addi t2, x0, -1 -> 32'hfff0_0393
    {dut.i_inst_mem.mem[3],  dut.i_inst_mem.mem[2],
     dut.i_inst_mem.mem[1],  dut.i_inst_mem.mem[0]}   = 32'h0430_0293;

    {dut.i_inst_mem.mem[7],  dut.i_inst_mem.mem[6],
     dut.i_inst_mem.mem[5],  dut.i_inst_mem.mem[4]}   = 32'h0050_0333;

    {dut.i_inst_mem.mem[11], dut.i_inst_mem.mem[10],
     dut.i_inst_mem.mem[9],  dut.i_inst_mem.mem[8]}   = 32'h0053_0463;

    {dut.i_inst_mem.mem[15], dut.i_inst_mem.mem[14],
     dut.i_inst_mem.mem[13], dut.i_inst_mem.mem[12]}  = 32'h0010_0393;

    {dut.i_inst_mem.mem[19], dut.i_inst_mem.mem[18],
     dut.i_inst_mem.mem[17], dut.i_inst_mem.mem[16]}  = 32'hfff0_0393;
  end

  // ---------------- checker ----------------
  task check_line;
      input [1:0] which;
      input  signed [31:0] ex_t0, ex_t1, ex_t2; // SIGNED expected regs
      input         [31:0] ex_pc;               // PC stays unsigned
      reg    signed [31:0] t0, t1, t2;          // SIGNED observed regs
      reg           [31:0] pc;
      reg pass;
  begin
    // t0=x5, t1=x6, t2=x7
    t0 = dut.i_reg_file.regs[5];
    t1 = dut.i_reg_file.regs[6];
    t2 = dut.i_reg_file.regs[7];

    // Observed PC (as seen by instruction memory) - this is the next PC
    pc = dut.i_inst_mem.pc;

    pass = (t0==ex_t0) && (t1==ex_t1) && (t2==ex_t2) && (pc==ex_pc);

    case (which)
      2'd0: $display("[%0t] addi t0, x0, 67 | t0 = %0d, t1 = %0d, t2 = %0d, PC = 0x%08h, EX_t0 = %0d, EX_t1 = %0d, EX_t2 = %0d, EX_PC = 0x%08h %s",
                     $time, t0, t1, t2, pc, ex_t0, ex_t1, ex_t2, ex_pc, pass ? "PASS" : "FAIL");
      2'd1: $display("[%0t] add  t1, x0, t0 | t0 = %0d, t1 = %0d, t2 = %0d, PC = 0x%08h, EX_t0 = %0d, EX_t1 = %0d, EX_t2 = %0d, EX_PC = 0x%08h %s",
                     $time, t0, t1, t2, pc, ex_t0, ex_t1, ex_t2, ex_pc, pass ? "PASS" : "FAIL");
      2'd2: $display("[%0t] beq  t1, t0, IS_EQUAL | t0 = %0d, t1 = %0d, t2 = %0d, PC = 0x%08h, EX_t0 = %0d, EX_t1 = %0d, EX_t2 = %0d, EX_PC = 0x%08h %s",
                     $time, t0, t1, t2, pc, ex_t0, ex_t1, ex_t2, ex_pc, pass ? "PASS" : "FAIL");
      default:
           $display("[%0t] IS_EQUAL: addi t2, x0, -1 | t0 = %0d, t1 = %0d, t2 = %0d, PC = 0x%08h, EX_t0 = %0d, EX_t1 = %0d, EX_t2 = %0d, EX_PC = 0x%08h %s",
                     $time, t0, t1, t2, pc, ex_t0, ex_t1, ex_t2, ex_pc, pass ? "PASS" : "FAIL");
    endcase

    if (!pass) begin
      $display("[%0t] SUMMARY | Test FAILED", $time);
      $stop;
    end
  end
  endtask

  // ---------------- sequence ----------------
  initial begin
    // Sample at 100ns after start, then every 100ns.
    // Expected PCs are the "next fetch" addresses after each instruction.
    #100 check_line(2'd0, 32'd67, 32'd0,   32'd0,    32'h0000_0004); // after addi @0x00, next PC=0x04
    #100 check_line(2'd1, 32'd67, 32'd67,  32'd0,    32'h0000_0008); // after add  @0x04, next PC=0x08
    #100 check_line(2'd2, 32'd67, 32'd67,  32'd0,    32'h0000_0010); // after beq @0x08 (taken), next PC=0x10
    #100 check_line(2'd3, 32'd67, 32'd67,  -32'sd1,  32'h0000_0014); // after addi @0x10, next PC=0x14

    $display("[%0t] SUMMARY | All tests PASSED", $time);
    #10 $finish;
  end

endmodule
