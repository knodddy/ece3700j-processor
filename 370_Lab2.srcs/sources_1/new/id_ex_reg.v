`timescale 1ns / 1ps
module id_ex_reg(
  input              clock,
  // data
  input      [31:0]  id_pc,
  input      [31:0]  id_rs1_data,
  input      [31:0]  id_rs2_data,
  input      [4:0]   id_rs1_addr,
  input      [4:0]   id_rs2_addr,
  input      [31:0]  id_imm,
  input      [2:0]   id_funct3,
  input              id_inst30,
  input      [4:0]   id_rd,
  // control
  input              id_alu_src,
  input      [1:0]   id_alu_op,
  input              id_mem_write,
  input              id_mem_read,
  input              id_branch,
  input      [1:0]   id_br_type,
  input              id_mem_to_reg,
  input              id_reg_write,
  input      [1:0]   id_wb_sel,   // 00:+4, 01:pc+imm, 10:rs1+imm
  input              id_jump,     // jal/jalr

  output reg [31:0]  ex_pc,
  output reg [31:0]  ex_rs1_data,
  output reg [31:0]  ex_rs2_data,
  output reg [4:0]   ex_rs1_addr,
  output reg [4:0]   ex_rs2_addr,
  output reg [31:0]  ex_imm,
  output reg [2:0]   ex_funct3,
  output reg         ex_inst30,
  output reg [4:0]   ex_rd,

  output reg         ex_alu_src,
  output reg [1:0]   ex_alu_op,
  output reg         ex_mem_write,
  output reg         ex_mem_read,
  output reg         ex_branch,
  output reg [1:0]   ex_br_type,
  output reg         ex_mem_to_reg,
  output reg         ex_reg_write,
  output reg [1:0]   ex_wb_sel,
  output reg         ex_jump
);
  // sim init
  initial begin
    ex_pc         = 32'd0;
    ex_rs1_data   = 32'd0;
    ex_rs2_data   = 32'd0;
    ex_rs1_addr   = 5'd0;
    ex_rs2_addr   = 5'd0;
    ex_imm        = 32'd0;
    ex_funct3     = 3'd0;
    ex_inst30     = 1'b0;
    ex_rd         = 5'd0;

    ex_alu_src    = 1'b0;
    ex_alu_op     = 2'b00;
    ex_mem_write  = 1'b0;
    ex_mem_read   = 1'b0;
    ex_branch     = 1'b0;
    ex_br_type    = 2'b00;
    ex_mem_to_reg = 1'b0;
    ex_reg_write  = 1'b0;
    ex_wb_sel     = 2'b00;
    ex_jump       = 1'b0;
  end

  always @(posedge clock) begin
    ex_pc         <= id_pc;
    ex_rs1_data   <= id_rs1_data;
    ex_rs2_data   <= id_rs2_data;
    ex_rs1_addr   <= id_rs1_addr;
    ex_rs2_addr   <= id_rs2_addr;
    ex_imm        <= id_imm;
    ex_funct3     <= id_funct3;
    ex_inst30     <= id_inst30;
    ex_rd         <= id_rd;

    ex_alu_src    <= id_alu_src;
    ex_alu_op     <= id_alu_op;
    ex_mem_write  <= id_mem_write;
    ex_mem_read   <= id_mem_read;
    ex_branch     <= id_branch;
    ex_br_type    <= id_br_type;
    ex_mem_to_reg <= id_mem_to_reg;
    ex_reg_write  <= id_reg_write;
    ex_wb_sel     <= id_wb_sel;
    ex_jump       <= id_jump;
  end
endmodule
