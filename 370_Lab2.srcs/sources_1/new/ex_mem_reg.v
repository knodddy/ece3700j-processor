`timescale 1ns / 1ps
module ex_mem_reg(
  input              clock,
  input      [31:0]  ex_alu_result,
  input      [31:0]  ex_write_data,
  input      [4:0]   ex_rd,
  input              ex_mem_write,
  input              ex_mem_read,
  input              ex_mem_to_reg,
  input              ex_reg_write,
  input              ex_jump,
  input      [31:0]  ex_pc_plus4,
  input  [2:0]  ex_funct3,

  output reg [31:0]  mem_alu_result,
  output reg [31:0]  mem_write_data,
  output reg [4:0]   mem_rd,
  output reg         mem_mem_write,
  output reg         mem_mem_read,
  output reg         mem_mem_to_reg,
  output reg         mem_reg_write,
  output reg         mem_jump,
  output reg [31:0]  mem_pc_plus4,
  output reg [2:0]  mem_funct3
);
  // sim init
  initial begin
    mem_alu_result = 32'd0;
    mem_write_data = 32'd0;
    mem_rd         = 5'd0;
    mem_mem_write  = 1'b0;
    mem_mem_read   = 1'b0;
    mem_mem_to_reg = 1'b0;
    mem_reg_write  = 1'b0;
    mem_jump       = 1'b0;
    mem_pc_plus4   = 32'd0;
  end

  always @(posedge clock) begin
    mem_alu_result <= ex_alu_result;
    mem_write_data <= ex_write_data;
    mem_rd         <= ex_rd;

    mem_mem_write  <= ex_mem_write;
    mem_mem_read   <= ex_mem_read;
    mem_mem_to_reg <= ex_mem_to_reg;
    mem_reg_write  <= ex_reg_write;

    mem_jump       <= ex_jump;
    mem_pc_plus4   <= ex_pc_plus4;
    
    mem_funct3 <= ex_funct3;
  end
endmodule
