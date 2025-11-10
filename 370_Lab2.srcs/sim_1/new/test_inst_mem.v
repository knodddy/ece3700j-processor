`timescale 1ns/1ps

module test_inst_mem;

  // DUT I/O
  reg  [31:0] pc;
  wire [31:0] inst;

  // Instantiate DUT
  inst_mem dut (
    .pc(pc),
    .inst(inst)
  );

  // -------- expected value helper (matches DUT init contents) --------
  function [31:0] exp_for_pc;
    input [31:0] addr;
    begin
      case (addr)
        32'd0  : exp_for_pc = 32'hff60_0293;
        32'd4  : exp_for_pc = 32'h0052_8333;
        32'd8  : exp_for_pc = 32'h4062_83b3;
        32'd12 : exp_for_pc = 32'h0003_7e33;
        32'd16 : exp_for_pc = 32'h0053_6eb3;
        32'd20 : exp_for_pc = 32'h01d0_2023;
        32'd24 : exp_for_pc = 32'h0050_2223;
        32'd28 : exp_for_pc = 32'h0002_8463;
        32'd32 : exp_for_pc = 32'h0003_0eb3;
        32'd36 : exp_for_pc = 32'h01d3_1463;
        32'd40 : exp_for_pc = 32'h01c3_1463;
        32'd44 : exp_for_pc = 32'h0000_03b3;
        32'd48 : exp_for_pc = 32'h0000_2403;
        32'd52 : exp_for_pc = 32'h0040_2483;
        32'd56 : exp_for_pc = 32'h0084_8493;
        32'd60 : exp_for_pc = 32'h0094_0463;
        32'd64 : exp_for_pc = 32'h0000_03b3;
        32'd68 : exp_for_pc = 32'h0073_83b3;
        // Misaligned example at PC=1 (byte-wise fetch across words)
        32'd1  : exp_for_pc = 32'h33ff_6002;
        default: exp_for_pc = 32'h0000_0000;
      endcase
    end
  endfunction

  // -------- one-line checker --------
  task check_case;
    input [8*64-1:0] label;   // up to 64 chars
    input [31:0]     pc_in;
    reg   [31:0]     exp;
    begin
      pc  = pc_in;
      #1; // combinational settle
      exp = exp_for_pc(pc_in);
      if (inst !== exp) begin
        $display("[%0t] %0s | PC:%h INST:%h EXP:%h FAIL",
                 $time, label, pc_in, inst, exp);
        $finish;
      end else begin
        $display("[%0t] %0s | PC:%h INST:%h EXP:%h PASS",
                 $time, label, pc_in, inst, exp);
      end
      #9; // space tests
    end
  endtask

  // -------- pick a random PC from known set (needs 1 input in Verilog) --------
  function [31:0] pick_random_pc;
    input integer seed; // dummy to satisfy Verilog rule
    integer sel;
    begin
      sel = seed % 20; if (sel < 0) sel = -sel;
      case (sel)
        0: pick_random_pc = 32'd0;    1: pick_random_pc = 32'd4;
        2: pick_random_pc = 32'd8;    3: pick_random_pc = 32'd12;
        4: pick_random_pc = 32'd16;   5: pick_random_pc = 32'd20;
        6: pick_random_pc = 32'd24;   7: pick_random_pc = 32'd28;
        8: pick_random_pc = 32'd32;   9: pick_random_pc = 32'd36;
        10: pick_random_pc = 32'd40; 11: pick_random_pc = 32'd44;
        12: pick_random_pc = 32'd48; 13: pick_random_pc = 32'd52;
        14: pick_random_pc = 32'd56; 15: pick_random_pc = 32'd60;
        16: pick_random_pc = 32'd64; 17: pick_random_pc = 32'd68;
        18: pick_random_pc = 32'd72;  // zero-filled region
        default: pick_random_pc = 32'd100; // zero-filled region
      endcase
    end
  endfunction

  // -------- test sequence --------
  initial begin
    // Optional VCD
    $dumpfile("inst_mem_tb.vcd");
    $dumpvars(0, test_inst_mem);

    // Wait a bit so DUT's initial block runs
    #10;

    // Specific aligned words
    check_case("read PC=0",   32'd0);
    check_case("read PC=4",   32'd4);
    check_case("read PC=8",   32'd8);
    check_case("read PC=12",  32'd12);
    check_case("read PC=68",  32'd68);

    // Misaligned read across two words
    check_case("misaligned read PC=1", 32'd1);

    // After program area (should be zeros)
    check_case("read PC=72 (zero area)", 32'd72);
    check_case("read PC=100 (zero area)", 32'd100);

    // Minimal random cases (2x) from known set
    check_case("RANDOM #1", pick_random_pc($random));
    check_case("RANDOM #2", pick_random_pc($random));

    $display("[%0t] SUMMARY | All tests PASSED", $time);
    $finish;
  end

endmodule
