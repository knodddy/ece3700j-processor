`timescale 1ns / 1ps
module if_id_reg(
  input              clock,
  input      [31:0]  if_pc,
  input      [31:0]  if_inst,
  output reg [31:0]  id_pc,
  output reg [31:0]  id_inst
);
  // sim init
  initial begin
    id_pc   = 32'd0;
    id_inst = 32'd0;
  end

  always @(posedge clock) begin
    id_pc   <= if_pc;
    id_inst <= if_inst;
  end
endmodule
