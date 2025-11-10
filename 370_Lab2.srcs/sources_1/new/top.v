`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/10/2025 06:18:22 PM
// Design Name: 
// Module Name: top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module top(
    input clock
    );
    
    wire [31:0] next_pc;
    wire [31:0] q_pc;
    wire [31:0] pc;
    wire [31:0] branch_pc;
    wire [31:0] inst;
    wire [31:0] imm;
    
    wire alu_src;
    wire [1:0] alu_op;
    wire mem_write;
    wire mem_read;
    wire branch;
    wire branch_ne;
    wire mem_to_reg;
    wire reg_write;
    wire [31:0] mem_to_reg_data;
    
    wire zero;
    wire branch_taken = branch & (zero ^ branch_ne);
    wire [31:0] alu_result;
    
    wire [31:0] reg_data_1;
    wire [31:0] reg_data_2;
    
    wire [3:0] alu_control_signal;
    wire [31:0] alu_src_data;
    
    wire [31:0] mem_data;
    
    pc_reg i_pc_reg (
        .clock(clock),
        .next_pc(q_pc),
        .pc(pc)
    );
    
    inst_mem i_inst_mem (
        .pc(pc),
        .inst(inst)    
    );
    
    adder pc_incrementer (
        .a(pc),
        .b(32'd4),
        .d(next_pc)
    );
    
    adder pc_branch_calculator(
        .a(pc),
//        .b(imm << 1),
        .b(imm),
        .d(branch_pc)
    );
    
    mux_2x1 pc_branch_selector(
        .i0(next_pc),
        .i1(branch_pc),
        .sel(branch_taken),
        .d(q_pc)
    );
    
    control i_control(
        .opcode(inst[6:0]),
        .funct3(inst[14:12]),
        .alu_src(alu_src),
        .alu_op(alu_op),
        .mem_write(mem_write),
        .mem_read(mem_read),
        .branch(branch),
        .branch_ne(branch_ne),
        .mem_to_reg(mem_to_reg),
        .reg_write(reg_write)
    );
    
    reg_file i_reg_file(
        .clock(clock),
        .reg_1(inst[19:15]),
        .reg_2(inst[24:20]),
        .reg_write(reg_write),
        .write_reg(inst[11:7]),
        .write_data(mem_to_reg_data),
        .data_1(reg_data_1),
        .data_2(reg_data_2)
    );
    
    imm_gen i_imm_gen(
        .inst(inst),
        .imm(imm)
    );
    
    mux_2x1 alu_src_mux(
        .i0(reg_data_2),
        .i1(imm),
        .sel(alu_src),
        .d(alu_src_data)
    );
    
    alu_control i_alu_control(
        .inst_30(inst[30]),
        .funct3(inst[14:12]),
        .alu_op(alu_op),
        .control(alu_control_signal)
    );
    
    alu i_alu(
        .control(alu_control_signal),
        .a(reg_data_1),
        .b(alu_src_data),
        .zero(zero),
        .d(alu_result)
    );
    
    data_mem i_data_mem(
        .clock(clock),
        .addr(alu_result),
        .write_data(reg_data_2),
        .mem_write(mem_write),
        .mem_read(mem_read),
        .data(mem_data)
    );
    
    mux_2x1 alu_mem_data_selector(
        .i0(alu_result),
        .i1(mem_data),
        .sel(mem_to_reg),
        .d(mem_to_reg_data)
    );
endmodule
