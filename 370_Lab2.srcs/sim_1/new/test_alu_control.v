`timescale 1ns/1ps

module test_alu_control;

  // DUT I/O
  reg        inst_30;
  reg  [2:0] funct3;
  reg  [1:0] alu_op;
  wire [3:0] control;

  // DUT
  alu_control dut (
    .inst_30(inst_30),
    .funct3(funct3),
    .alu_op(alu_op),
    .control(control)
  );

  // Reference model
  function [3:0] ref_ctrl;
    input        i30;
    input [2:0]  f3;
    input [1:0]  ao;
    begin
      if (ao == 2'b00) begin
        ref_ctrl = 4'b0010;                         // ADD
      end else if (ao == 2'b01) begin
        ref_ctrl = 4'b0110;                         // SUB
      end else if (ao == 2'b10) begin
        case ({i30, f3})
          4'b0000: ref_ctrl = 4'b0010;              // ADD
          4'b1000: ref_ctrl = 4'b0110;              // SUB
          4'b0111: ref_ctrl = 4'b0000;              // AND
          4'b0110: ref_ctrl = 4'b0001;              // OR
          default: ref_ctrl = 4'b0010;              // default ADD
        endcase
      end else begin
        ref_ctrl = 4'b0010;
      end
    end
  endfunction

  // One-line checker
  task check_case;
    input [8*64-1:0] label;
    input [1:0] ao;
    input [2:0] f3;
    input       i30;
    reg [3:0] exp;
    begin
      alu_op  = ao;
      funct3  = f3;
      inst_30 = i30;
      #1; // settle
      exp = ref_ctrl(i30, f3, ao);

      if (control !== exp) begin
        $display("[%0t] %0s | ALUOP:%b f3:%b i30:%0d | CTRL:%b EXP:%b FAIL",
                 $time, label, ao, f3, i30, control, exp);
        $finish;
      end else begin
        $display("[%0t] %0s | ALUOP:%b f3:%b i30:%0d | CTRL:%b EXP:%b PASS",
                 $time, label, ao, f3, i30, control, exp);
      end
      #9;
    end
  endtask

  // Randomized single run (ao in {00,01,10})
  task rand_once;
    integer sel;
    reg [1:0] ao;
    reg [2:0] f3;
    reg       i30;
    reg [8*64-1:0] lbl;
    begin
      sel = $random % 3; if (sel < 0) sel = -sel;
      case (sel)
        0: begin
             ao = 2'b00; f3 = ($random & 3'b111); i30 = ($random & 1'b1);
             lbl = "RANDOM ALUOP=00";
           end
        1: begin
             ao = 2'b01; f3 = ($random & 3'b111); i30 = ($random & 1'b1);
             lbl = "RANDOM ALUOP=01";
           end
        default: begin
             ao = 2'b10; // R-type map
             if (($random & 3'h7) < 3) begin
               case ($random & 2'b11)
                 2'd0: begin i30=1'b0; f3=3'b000; end // ADD
                 2'd1: begin i30=1'b1; f3=3'b000; end // SUB
                 2'd2: begin i30=1'b0; f3=3'b111; end // AND
                 default: begin i30=1'b0; f3=3'b110; end // OR
               endcase
             end else begin
               i30 = ($random & 1'b1);
               f3  = ($random & 3'b111);
             end
             lbl = "RANDOM ALUOP=10";
           end
      endcase
      check_case(lbl, ao, f3, i30);
    end
  endtask

  // Test sequence
  initial begin
    alu_op = 2'b00; funct3 = 3'b000; inst_30 = 1'b0;
    #10;

    // Specific cases
    check_case("ALUOP=00 -> ADD (ignore f3/i30)", 2'b00, 3'b111, 1'b1);
    check_case("ALUOP=01 -> SUB (ignore f3/i30)", 2'b01, 3'b000, 1'b0);

    check_case("R-type ADD", 2'b10, 3'b000, 1'b0);
    check_case("R-type SUB", 2'b10, 3'b000, 1'b1);
    check_case("R-type AND", 2'b10, 3'b111, 1'b0);
    check_case("R-type OR",  2'b10, 3'b110, 1'b0);

    // Unknown R-type funct3 -> default ADD
    check_case("R-type unknown -> default ADD", 2'b10, 3'b001, 1'b0);

    // Two randoms
    rand_once();
    rand_once();

    $display("[%0t] SUMMARY | All tests PASSED", $time);
    $finish;
  end

endmodule
