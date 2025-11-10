`timescale 1ns/1ps

module test_imm_gen;

  // DUT I/O
  reg  [31:0] inst;
  wire [31:0] imm;

  // Instantiate DUT
  imm_gen dut (
    .inst(inst),
    .imm(imm)
  );

  // -------- helpers: packers & sign-extend (Verilog-2001) --------
  function [31:0] pack_i;
    input [11:0] imm12;
    input [6:0]  opc;
    input [2:0]  funct3;
    input [4:0]  rs1, rd;
    begin
      pack_i = {imm12, rs1, funct3, rd, opc};
    end
  endfunction

  function [31:0] pack_s;
    input [11:0] imm12;
    input [6:0]  opc;
    input [2:0]  funct3;
    input [4:0]  rs1, rs2;
    begin
      pack_s = {imm12[11:5], rs2, rs1, funct3, imm12[4:0], opc};
    end
  endfunction

  // B-type: imm[12]|imm[10:5]|rs2|rs1|funct3|imm[4:1]|imm[11]|opcode
  function [31:0] pack_b;
    input [12:0] imm13;  // imm[0] must be 0 (even)
    input [6:0]  opc;
    input [2:0]  funct3;
    input [4:0]  rs1, rs2;
    begin
      pack_b = {imm13[12], imm13[10:5], rs2, rs1, funct3, imm13[4:1], imm13[11], opc};
    end
  endfunction

  function [31:0] sxt12;
    input [11:0] x;
    begin
      sxt12 = {{20{x[11]}}, x};
    end
  endfunction

  function [31:0] sxt13;
    input [12:0] x;
    begin
      sxt13 = {{19{x[12]}}, x};
    end
  endfunction

  // -------- one-line checker --------
  task check_case;
    input [8*64-1:0] label;  // up to 64 chars
    input [31:0] inst_in;
    input [31:0] exp;
    begin
      inst = inst_in;
      #1; // combinational settle
      if (imm !== exp) begin
        $display("[%0t] %0s | INST:%h IMM:%h EXP:%h FAIL", $time, label, inst, imm, exp);
        $finish;
      end else begin
        $display("[%0t] %0s | INST:%h IMM:%h EXP:%h PASS", $time, label, inst, imm, exp);
      end
      #9; // space tests (nice timestamps)
    end
  endtask

  // -------- test sequence --------
  integer rsel, v12, v13;
  reg [31:0] inst_build, exp_build;

  initial begin
    // Edge / specific cases
    check_case("I/addi imm=-2048",
      pack_i(12'h800, 7'b0010011, 3'b000, 5'd1, 5'd2),
      sxt12(12'h800));

    check_case("I/lw imm=2047",
      pack_i(12'h7FF, 7'b0000011, 3'b010, 5'd3, 5'd4),
      sxt12(12'h7FF));

    check_case("S/sw imm=-1",
      pack_s(12'hFFF, 7'b0100011, 3'b010, 5'd5, 5'd6),
      sxt12(12'hFFF));

    check_case("B/beq imm=2048",
      pack_b(13'h1000, 7'b1100011, 3'b000, 5'd1, 5'd2),
      sxt13(13'h1000));

    check_case("B/bne imm=-4",
      pack_b(13'h1FFC, 7'b1100011, 3'b001, 5'd2, 5'd3),
      sxt13(13'h1FFC));

    check_case("default opcode -> 0",
      {12'h000, 5'd1, 3'b000, 5'd2, 7'b0110011}, // R-type opcode
      32'h00000000);

    // -------- random case #1 --------
    rsel = ($random % 3); if (rsel < 0) rsel = -rsel;
    if (rsel == 0) begin
      v12 = ($random % 4096); if (v12 < 0) v12 = -v12; v12 = v12 - 2048; // [-2048,2047]
      inst_build = pack_i(v12[11:0], 7'b0010011, 3'b000, 5'd7, 5'd8); // addi
      exp_build  = sxt12(v12[11:0]);
      check_case("RANDOM I/addi", inst_build, exp_build);
    end else if (rsel == 1) begin
      v12 = ($random % 4096); if (v12 < 0) v12 = -v12; v12 = v12 - 2048;
      inst_build = pack_s(v12[11:0], 7'b0100011, 3'b010, 5'd9, 5'd10); // sw
      exp_build  = sxt12(v12[11:0]);
      check_case("RANDOM S/sw", inst_build, exp_build);
    end else begin
      v13 = ($random % 8192); if (v13 < 0) v13 = -v13; v13 = (v13 - 4096) & ~1; // even
      inst_build = pack_b(v13[12:0], 7'b1100011, 3'b000, 5'd11, 5'd12); // beq
      exp_build  = sxt13(v13[12:0]);
      check_case("RANDOM B/beq", inst_build, exp_build);
    end

    // -------- random case #2 --------
    rsel = ($random % 3); if (rsel < 0) rsel = -rsel;
    if (rsel == 0) begin
      v12 = ($random % 4096); if (v12 < 0) v12 = -v12; v12 = v12 - 2048;
      inst_build = pack_i(v12[11:0], 7'b0000011, 3'b010, 5'd13, 5'd14); // lw
      exp_build  = sxt12(v12[11:0]);
      check_case("RANDOM I/lw", inst_build, exp_build);
    end else if (rsel == 1) begin
      v12 = ($random % 4096); if (v12 < 0) v12 = -v12; v12 = v12 - 2048;
      inst_build = pack_s(v12[11:0], 7'b0100011, 3'b010, 5'd15, 5'd16); // sw
      exp_build  = sxt12(v12[11:0]);
      check_case("RANDOM S/sw", inst_build, exp_build);
    end else begin
      v13 = ($random % 8192); if (v13 < 0) v13 = -v13; v13 = (v13 - 4096) & ~1;
      inst_build = pack_b(v13[12:0], 7'b1100011, 3'b001, 5'd17, 5'd18); // bne
      exp_build  = sxt13(v13[12:0]);
      check_case("RANDOM B/bne", inst_build, exp_build);
    end

    $display("[%0t] SUMMARY | All tests PASSED", $time);
    $finish;
  end

endmodule
