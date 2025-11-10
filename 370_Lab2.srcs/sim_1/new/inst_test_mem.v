`timescale 1ns/1ps
module inst_test_mem;

  // -------- clock --------
  reg clock = 0;
  always #50 clock = ~clock; // 100 ns period (timestamps: 100000, 200000, 300000)

  // -------- DUT ---------
  top dut(.clock(clock));

  // -------- program load (your packed-word style) --------
  initial begin
    // Wait a moment so inst_mem's zeroing finishes
    #1;
    // addi t0, x0, 67  -> 32'h0430_0293
    {dut.i_inst_mem.mem[3],  dut.i_inst_mem.mem[2],
     dut.i_inst_mem.mem[1],  dut.i_inst_mem.mem[0]}  = 32'h0430_0293;

    // sw t0, 0(x0)     -> 32'h0050_2023
    {dut.i_inst_mem.mem[7],  dut.i_inst_mem.mem[6],
     dut.i_inst_mem.mem[5],  dut.i_inst_mem.mem[4]}  = 32'h0050_2023;

    // lw t1, 0(x0)     -> 32'h0000_2303
    {dut.i_inst_mem.mem[11], dut.i_inst_mem.mem[10],
     dut.i_inst_mem.mem[9],  dut.i_inst_mem.mem[8]}  = 32'h0000_2303;
  end

  // -------- checker --------
  task check_line;
    input [1:0] which;              // 0:addi, 1:sw, 2:lw (for literal text)
    input [31:0] ex_t0, ex_t1, ex_mem0;
    reg   [31:0] t0, t1, mem0;
    reg pass;
  begin
    // t0=x5, t1=x6; Mem[0] assumes a word array mem[0] inside i_data_mem
    t0   = dut.i_reg_file.regs[5];
    t1   = dut.i_reg_file.regs[6];
    mem0 = dut.i_data_mem.mem[0];     // If your data memory is byte-arrayed, adjust to combine bytes.

    pass = (t0==ex_t0) && (t1==ex_t1) && (mem0==ex_mem0);

    case (which)
      2'd0:
        $display("[%0t] addi t0, x0, 67 | t0 = %0d, t1 = %0d, MEM[0] = %0d, EX_t0 = %0d, EX_t1 = %0d, EX_MEM0 = %0d %s",
                 $time, t0, t1, mem0, ex_t0, ex_t1, ex_mem0, pass ? "PASS" : "FAIL");
      2'd1:
        $display("[%0t] sw t0, 0(x0)    | t0 = %0d, t1 = %0d, MEM[0] = %0d, EX_t0 = %0d, EX_t1 = %0d, EX_MEM0 = %0d %s",
                 $time, t0, t1, mem0, ex_t0, ex_t1, ex_mem0, pass ? "PASS" : "FAIL");
      default:
        $display("[%0t] lw t1, 0(x0)    | t0 = %0d, t1 = %0d, MEM[0] = %0d, EX_t0 = %0d, EX_t1 = %0d, EX_MEM0 = %0d %s",
                 $time, t0, t1, mem0, ex_t0, ex_t1, ex_mem0, pass ? "PASS" : "FAIL");
    endcase

    if (!pass) begin
      $display("[%0t] SUMMARY | Test FAILED", $time);
      $stop;
    end
  end
  endtask

  // -------- sequence --------
  initial begin
    // posedges at 50,150,250ns; sample at 100,200,300ns (stable)
    // After addi: t0=67, t1=0, Mem[0]=0
    #100 check_line(2'd0, 32'd67, 32'd0, 32'd0);

    // After sw: t0=67, t1=0, Mem[0]=67
    #100 check_line(2'd1, 32'd67, 32'd0, 32'd67);

    // After lw: t0=67, t1=67, Mem[0]=67
    #100 check_line(2'd2, 32'd67, 32'd67, 32'd67);

    // Final summary (same timestamp as last check)
    $display("[%0t] SUMMARY | All tests PASSED", $time);
    #10 $finish;
  end

endmodule
