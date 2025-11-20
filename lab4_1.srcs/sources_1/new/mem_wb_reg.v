`timescale 1ns / 1ps
module mem_wb_reg(
  input              clock,
  input      [31:0]  mem_read_data,
  input      [31:0]  mem_alu_result,
  input      [4:0]   mem_rd,
  input              mem_mem_to_reg,
  input              mem_reg_write,
  input              mem_jump,
  input      [31:0]  mem_pc_plus4,

  output reg [31:0]  wb_read_data,
  output reg [31:0]  wb_alu_result,
  output reg [4:0]   wb_rd,
  output reg         wb_mem_to_reg,
  output reg         wb_reg_write,
  output reg         wb_jump,
  output reg [31:0]  wb_pc_plus4
);
  // sim init
  initial begin
    wb_read_data  = 32'd0;
    wb_alu_result = 32'd0;
    wb_rd         = 5'd0;
    wb_mem_to_reg = 1'b0;
    wb_reg_write  = 1'b0;
    wb_jump       = 1'b0;
    wb_pc_plus4   = 32'd0;
  end

  always @(posedge clock) begin
    wb_read_data  <= mem_read_data;
    wb_alu_result <= mem_alu_result;
    wb_rd         <= mem_rd;
    wb_mem_to_reg <= mem_mem_to_reg;
    wb_reg_write  <= mem_reg_write;
    wb_jump       <= mem_jump;
    wb_pc_plus4   <= mem_pc_plus4;
  end
endmodule
