`timescale 1ns/1ps

module test_control;

  // DUT I/O
  reg  [6:0] opcode;
  reg  [2:0] funct3;
  wire       alu_src;
  wire [1:0] alu_op;
  wire       mem_write, mem_read;
  wire       branch, branch_ne;
  wire       mem_to_reg, reg_write;

  // Instantiate DUT
  control dut (
    .opcode(opcode),
    .funct3(funct3),
    .alu_src(alu_src),
    .alu_op(alu_op),
    .mem_write(mem_write),
    .mem_read(mem_read),
    .branch(branch),
    .branch_ne(branch_ne),
    .mem_to_reg(mem_to_reg),
    .reg_write(reg_write)
  );

  // -------- reference model: expected packing --------
  // Pack order: {AS, AO[1:0], MW, MR, BR, BNE, M2R, RW}  -> 9 bits total
  function [8:0] ref_pack;
    input [6:0] opc;
    input [2:0] f3;
    begin
      case (opc)
        7'b0110011: ref_pack = {1'b0, 2'b10, 1'b0,1'b0,1'b0,1'b0,1'b0,1'b1};                // R
        7'b0000011: ref_pack = {1'b1, 2'b00, 1'b0,1'b1,1'b0,1'b0,1'b1,1'b1};                // LW
        7'b0100011: ref_pack = {1'b1, 2'b00, 1'b1,1'b0,1'b0,1'b0,1'b0,1'b0};                // SW
        7'b1100011: ref_pack = {1'b0, 2'b01, 1'b0,1'b0,1'b1,(f3==3'b001),1'b0,1'b0};        // BEQ/BNE
        7'b0010011: ref_pack = {1'b1, 2'b00, 1'b0,1'b0,1'b0,1'b0,1'b0,1'b1};                // ADDI (I-type ALU)
        default:    ref_pack = {1'b0, 2'b00, 1'b0,1'b0,1'b0,1'b0,1'b0,1'b0};                // default
      endcase
    end
  endfunction

  // -------- one-line checker --------
  task check_case;
    input [8*64-1:0] label; // up to 64 chars
    input [6:0] opc;
    input [2:0] f3;
    reg [8:0] exp;
    begin
      opcode = opc; funct3 = f3;
      #1; // allow comb to settle
      exp = ref_pack(opc, f3);

      if ( {alu_src, alu_op, mem_write, mem_read, branch, branch_ne, mem_to_reg, reg_write} !== exp ) begin
        $display("[%0t] %0s | OPC:%b f3:%b | AS:%0d AO:%b MW:%0d MR:%0d BR:%0d BNE:%0d M2R:%0d RW:%0d | EXP AS:%0d AO:%b MW:%0d MR:%0d BR:%0d BNE:%0d M2R:%0d RW:%0d FAIL",
                 $time, label, opc, f3,
                 alu_src, alu_op, mem_write, mem_read, branch, branch_ne, mem_to_reg, reg_write,
                 exp[8], exp[7:6], exp[5], exp[4], exp[3], exp[2], exp[1], exp[0]);
        $finish;
      end else begin
        $display("[%0t] %0s | OPC:%b f3:%b | AS:%0d AO:%b MW:%0d MR:%0d BR:%0d BNE:%0d M2R:%0d RW:%0d PASS",
                 $time, label, opc, f3,
                 alu_src, alu_op, mem_write, mem_read, branch, branch_ne, mem_to_reg, reg_write);
      end
      #9; // space tests to get neat timestamps (~10ns per case)
    end
  endtask

  // -------- randomized single run --------
  task rand_once;
    integer sel;
    reg [6:0] opc;
    reg [2:0] f3;
    reg [8*64-1:0] lbl;
    begin
      sel = $random % 6; if (sel < 0) sel = -sel;
      case (sel)
        0: begin opc = 7'b0110011; f3 = 3'b000; lbl = "RANDOM R-type"; end
        1: begin opc = 7'b0000011; f3 = 3'b010; lbl = "RANDOM LW";     end
        2: begin opc = 7'b0100011; f3 = 3'b010; lbl = "RANDOM SW";     end
        3: begin opc = 7'b1100011; f3 = ( $random & 1 ) ? 3'b001 : 3'b000; lbl = "RANDOM BR"; end
        4: begin opc = 7'b0010011; f3 = 3'b000; lbl = "RANDOM ADDI";   end
        default: begin opc = $random; opc = opc[6:0]; f3 = $random; f3 = f3[2:0]; lbl = "RANDOM DEFAULT/OTHER"; end
      endcase
      check_case(lbl, opc, f3);
    end
  endtask

  // -------- test sequence --------
  initial begin
    opcode = 7'd0; funct3 = 3'd0;
    #10;

    // Edge / specific cases
    check_case("R-type",                7'b0110011, 3'b000);
    check_case("LW",                    7'b0000011, 3'b010);
    check_case("SW",                    7'b0100011, 3'b010);
    check_case("BEQ",                   7'b1100011, 3'b000);
    check_case("BNE",                   7'b1100011, 3'b001);
    check_case("ADDI (I-type ALU)",     7'b0010011, 3'b000);
    check_case("DEFAULT opcode -> 0s",  {7{1'b1}},  3'b111); // unknown opcode

    // Minimal randomized cases (2x)
    rand_once();
    rand_once();

    $display("[%0t] SUMMARY | All tests PASSED", $time);
    $finish;
  end

endmodule
