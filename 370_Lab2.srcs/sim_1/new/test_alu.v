`timescale 1ns/1ps

module test_alu;

  // DUT I/O
  reg  [3:0]  control;
  reg  [31:0] a, b;
  wire        zero;
  wire [31:0] d;

  // Instantiate DUT
  alu dut (
    .control(control),
    .a(a),
    .b(b),
    .zero(zero),
    .d(d)
  );

  // ---------------- reference model ----------------
  function [31:0] ref_alu;
    input [3:0]  c;
    input [31:0] aa, bb;
    begin
      case (c)
        4'b0000: ref_alu = aa & bb;    // AND
        4'b0001: ref_alu = aa | bb;    // OR
        4'b0010: ref_alu = aa + bb;    // ADD
        4'b0110: ref_alu = aa - bb;    // SUB
        default: ref_alu = 32'h0000_0000;
      endcase
    end
  endfunction

  // One-line checker (left-aligned with '|')
  task check_case;
    input [8*64-1:0] label;   // up to 64 chars
    input [3:0]       c;
    input [31:0]      aa, bb;
    reg   [31:0]      exp_d;
    reg               exp_z;
    begin
      control = c; a = aa; b = bb;
      #1; // allow comb to settle
      exp_d = ref_alu(c, aa, bb);
      exp_z = (exp_d == 32'h0);
      if (d !== exp_d || zero !== exp_z) begin
        $display("[%0t] %0s | ctrl:%b a:%h b:%h d:%h z:%0d EXPd:%h EXPz:%0d FAIL",
                 $time, label, c, aa, bb, d, zero, exp_d, exp_z);
        $finish;
      end else begin
        $display("[%0t] %0s | ctrl:%b a:%h b:%h d:%h z:%0d EXPd:%h EXPz:%0d PASS",
                 $time, label, c, aa, bb, d, zero, exp_d, exp_z);
      end
      #9; // space tests to advance time ~10ns per case
    end
  endtask

  // Randomized single run
  task rand_once;
    reg [3:0]  c;
    reg [31:0] aa, bb;
    reg [8*64-1:0] lbl;
    reg [1:0] sel;
    begin
      sel = ($random & 2'b11);
      case (sel)
        2'd0: begin c = 4'b0000; lbl = "RANDOM AND"; end
        2'd1: begin c = 4'b0001; lbl = "RANDOM OR";  end
        2'd2: begin c = 4'b0010; lbl = "RANDOM ADD"; end
        default: begin c = 4'b0110; lbl = "RANDOM SUB"; end
      endcase
      aa = $random;
      bb = $random;
      check_case(lbl, c, aa, bb);
    end
  endtask

  // ---------------- test sequence ----------------
  initial begin
    // Initialize inputs
    control = 4'b0000; a = 32'h0; b = 32'h0;
    #10;

    // Edge / specific cases
    check_case("AND zero result",       4'b0000, 32'h0000_0000, 32'hDEAD_BEEF);
    check_case("AND non-zero result",   4'b0000, 32'hFFFF_0000, 32'h00FF_00FF);
    check_case("OR propagate",          4'b0001, 32'h0000_0000, 32'h1234_5678);
    check_case("ADD wrap to zero",      4'b0010, 32'h0000_0001, 32'hFFFF_FFFF);
    check_case("SUB zero result",       4'b0110, 32'hCAFE_BABE, 32'hCAFE_BABE);
    check_case("SUB negative result",   4'b0110, 32'h0000_0001, 32'h0000_0002);
    check_case("DEFAULT opcode -> 0",   4'b1111, 32'h1234_5678, 32'h9ABC_DEF0);

    // Minimal randomized cases (2x)
    rand_once();
    rand_once();

    $display("[%0t] SUMMARY | All tests PASSED", $time);
    $finish;
  end

endmodule
