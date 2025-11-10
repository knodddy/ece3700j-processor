`timescale 1ns/1ps
module inst_test_add;

  // ---------------- clock ----------------
  reg clock = 0;
  always #50 clock = ~clock; // 100 ns period (times are 100000, 200000, 300000)

  // ---------------- DUT ------------------
  top dut(.clock(clock));

  // ---------------- program load (your style) ----------------
  initial begin
    // Wait 1ns to avoid racing the inst_mem initial zeroing
    #1;
    // Same style as your comments in inst_mem (little-endian word stores)
    // addi t0, x0, 6  -> 32'h0060_0293
    {dut.i_inst_mem.mem[3],  dut.i_inst_mem.mem[2],
     dut.i_inst_mem.mem[1],  dut.i_inst_mem.mem[0]}  = 32'h0060_0293;

    // addi t1, x0, 7  -> 32'h0070_0313
    {dut.i_inst_mem.mem[7],  dut.i_inst_mem.mem[6],
     dut.i_inst_mem.mem[5],  dut.i_inst_mem.mem[4]}  = 32'h0070_0313;

    // add  t2, t0, t1 -> 32'h0062_83b3
    {dut.i_inst_mem.mem[11], dut.i_inst_mem.mem[10],
     dut.i_inst_mem.mem[9],  dut.i_inst_mem.mem[8]}  = 32'h0062_83b3;

    // (Add more words by continuing the pattern in 4-byte steps: 12..15, 16..19, etc.)
  end

  // ---------------- checker ----------------
  task check_line;
    input [1:0] which;              // 0: addi t0, 1: addi t1, 2: add t2
    input [31:0] ex_t0, ex_t1, ex_t2;
    reg   [31:0] t0, t1, t2;
    reg pass;
  begin
    // t0=x5, t1=x6, t2=x7  (adjust regs[] if your array name differs)
    t0 = dut.i_reg_file.regs[5];
    t1 = dut.i_reg_file.regs[6];
    t2 = dut.i_reg_file.regs[7];
    pass = (t0==ex_t0) && (t1==ex_t1) && (t2==ex_t2);

    // Print with *literal* message (no %s => no padding)
    case (which)
      2'd0: $display("[%0t] addi t0, x0, 6 | t0 = %0d, t1 = %0d, t2 = %0d, EX_t0 = %0d, EX_t1 = %0d, EX_t2 = %0d %s",
                     $time, t0, t1, t2, ex_t0, ex_t1, ex_t2, pass ? "PASS" : "FAIL");
      2'd1: $display("[%0t] addi t1, x0, 7 | t0 = %0d, t1 = %0d, t2 = %0d, EX_t0 = %0d, EX_t1 = %0d, EX_t2 = %0d %s",
                     $time, t0, t1, t2, ex_t0, ex_t1, ex_t2, pass ? "PASS" : "FAIL");
      default:
           $display("[%0t] add t2, t0, t1 | t0 = %0d, t1 = %0d, t2 = %0d, EX_t0 = %0d, EX_t1 = %0d, EX_t2 = %0d %s",
                     $time, t0, t1, t2, ex_t0, ex_t1, ex_t2, pass ? "PASS" : "FAIL");
    endcase

    if (!pass) begin
      $display("[%0t] SUMMARY | Test FAILED", $time);
      $stop;
    end
  end
  endtask

  // ---------------- sequence ----------------
  initial begin
    // sample at 100ns after first posedge (50ns), then every 100ns
    #100 check_line(2'd0, 32'd6, 32'd0, 32'd0);   // addi t0, x0, 6
    #100 check_line(2'd1, 32'd6, 32'd7, 32'd0);   // addi t1, x0, 7
    #100 check_line(2'd2, 32'd6, 32'd7, 32'd13);  // add t2, t0, t1

    $display("[%0t] SUMMARY | All tests PASSED", $time);
    #10 $finish;
  end

endmodule
