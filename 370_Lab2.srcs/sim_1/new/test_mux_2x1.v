`timescale 1ns/1ps

module test_mux_2x1;

  // DUT I/O
  reg  [31:0] i0, i1;
  reg         sel;
  wire [31:0] d;

  // Instantiate DUT
  mux_2x1 dut (
    .i0(i0),
    .i1(i1),
    .sel(sel),
    .d(d)
  );

  // ---------- one-line checker ----------
  task check_case;
    input [8*64-1:0] label; // up to 64 chars
    input       s;
    input [31:0] a0, a1;
    reg   [31:0] exp;
    begin
      sel = s; i0 = a0; i1 = a1;
      #1; // combinational settle
      exp = (s ? a1 : a0);
      if (d !== exp) begin
        $display("[%0t] %0s | sel:%0d i0:%h i1:%h d:%h EXP:%h FAIL",
                 $time, label, s, a0, a1, d, exp);
        $finish;
      end else begin
        $display("[%0t] %0s | sel:%0d i0:%h i1:%h d:%h EXP:%h PASS",
                 $time, label, s, a0, a1, d, exp);
      end
      #9; // space tests (~10ns per case)
    end
  endtask

  // ---------- test sequence ----------
  reg [31:0] r0, r1;
  integer k;

  initial begin
    // Optional VCD (harmless in Vivado)
    $dumpfile("mux_2x1_tb.vcd");
    $dumpvars(0, test_mux_2x1);

    // Init
    sel = 1'b0; i0 = 32'h0; i1 = 32'h0;
    #10;

    // Edge / specific cases
    check_case("sel=0 picks i0 (i0=0, i1=FFFFFFFF)", 1'b0, 32'h0000_0000, 32'hFFFF_FFFF);
    check_case("sel=1 picks i1 (i1=DEADBEEF)",       1'b1, 32'h0000_0000, 32'hDEAD_BEEF);
    check_case("sel=0 nonzero i0",                   1'b0, 32'h1234_5678, 32'h9ABC_DEF0);
    check_case("sel=1 with zero i1",                 1'b1, 32'hCAFE_BABE, 32'h0000_0000);
    check_case("both inputs equal",                  1'b1, 32'hA5A5_A5A5, 32'hA5A5_A5A5);

    // Minimal random cases (2x)
    r0 = $random; r1 = $random;
    check_case("RANDOM #1", ($random & 1'b1), r0, r1);

    r0 = $random; r1 = $random;
    check_case("RANDOM #2", ($random & 1'b1), r0, r1);

    $display("[%0t] SUMMARY | All tests PASSED", $time);
    $finish;
  end

endmodule
