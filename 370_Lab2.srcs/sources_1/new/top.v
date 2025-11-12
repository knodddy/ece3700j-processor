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
    wire [31:0] alu_result;
    
    wire [31:0] reg_data_1;
    wire [31:0] reg_data_2;
    
    wire [3:0] alu_control_signal;
    wire [31:0] alu_src_data;
    
    wire [31:0] mem_data;

    pc_reg i_pc_reg (.clock(clock), .next_pc(q_pc), .pc(pc));
    inst_mem i_inst_mem (.pc(pc), .inst(inst));
    adder pc_incrementer (.a(pc), .b(32'd4), .d(next_pc));

    wire [31:0] if_id_pc, if_id_inst;
    if_id_reg U_IFID (.clock(clock), .if_pc(pc), .if_inst(inst), .id_pc(if_id_pc), .id_inst(if_id_inst));

    wire jump;
    wire [1:0] br_type;
    wire [1:0] br_wb_sel;
    assign branch_ne = 1'b0;

    control i_control(
        .opcode(if_id_inst[6:0]),
        .funct3(if_id_inst[14:12]),
        .alu_src(alu_src),
        .alu_op(alu_op),
        .mem_write(mem_write),
        .mem_read(mem_read),
        .branch(branch),
        .br_type(br_type),
        .mem_to_reg(mem_to_reg),
        .reg_write(reg_write),
        .wb_sel(br_wb_sel),
        .jump(jump)
    );
    
    reg_file i_reg_file(
        .clock(clock),
        .reg_1(if_id_inst[19:15]),
        .reg_2(if_id_inst[24:20]),
        .reg_write(wb_reg_write),
        .write_reg(wb_rd),
        .write_data(mem_to_reg_data),
        .data_1(reg_data_1),
        .data_2(reg_data_2)
    );

    imm_gen i_imm_gen(.inst(if_id_inst), .imm(imm));

    wire [31:0] id_ex_pc, id_ex_rs1, id_ex_rs2, id_ex_imm;
    wire [2:0] id_ex_funct3;
    wire id_ex_inst30;
    wire [4:0] id_ex_rd;
    wire id_ex_mem_write, id_ex_mem_read, id_ex_branch, id_ex_mem_to_reg, id_ex_reg_write, id_ex_jump;
    wire [1:0] id_ex_alu_op, id_ex_br_type, id_ex_wb_sel;
    wire id_ex_alu_src;

    id_ex_reg U_IDEX(
        .clock(clock),
        .id_pc(if_id_pc),
        .id_rs1_data(reg_data_1),
        .id_rs2_data(reg_data_2),
        .id_imm(imm),
        .id_funct3(if_id_inst[14:12]),
        .id_inst30(if_id_inst[30]),
        .id_rd(if_id_inst[11:7]),
        .id_alu_src(alu_src),
        .id_alu_op(alu_op),
        .id_mem_write(mem_write),
        .id_mem_read(mem_read),
        .id_branch(branch),
        .id_br_type(br_type),
        .id_mem_to_reg(mem_to_reg),
        .id_reg_write(reg_write),
        .id_wb_sel(br_wb_sel),
        .id_jump(jump),
        .ex_pc(id_ex_pc),
        .ex_rs1_data(id_ex_rs1),
        .ex_rs2_data(id_ex_rs2),
        .ex_imm(id_ex_imm),
        .ex_funct3(id_ex_funct3),
        .ex_inst30(id_ex_inst30),
        .ex_rd(id_ex_rd),
        .ex_alu_src(id_ex_alu_src),
        .ex_alu_op(id_ex_alu_op),
        .ex_mem_write(id_ex_mem_write),
        .ex_mem_read(id_ex_mem_read),
        .ex_branch(id_ex_branch),
        .ex_br_type(id_ex_br_type),
        .ex_mem_to_reg(id_ex_mem_to_reg),
        .ex_reg_write(id_ex_reg_write),
        .ex_wb_sel(id_ex_wb_sel),
        .ex_jump(id_ex_jump)
    );
    
    mux_2x1 alu_src_mux(
        .i0(id_ex_rs2),
        .i1(id_ex_imm),
        .sel(id_ex_alu_src),
        .d(alu_src_data)
    );
    
    alu_control i_alu_control(
        .inst_30(id_ex_inst30),
        .funct3(id_ex_funct3),
        .alu_op(id_ex_alu_op),
        .control(alu_control_signal)
    );
    
    alu i_alu(
        .control(alu_control_signal),
        .a(id_ex_rs1),
        .b(alu_src_data),
        .zero(zero),
        .d(alu_result)
    );

    wire branch_meet;
    compare i_compare(.zero(zero), .alu_result(alu_result), .br_type(id_ex_br_type), .branch_meet(branch_meet));

    wire [31:0] ex_pc_plus_imm;
    adder pc_branch_calculator(.a(id_ex_pc), .b(id_ex_imm), .d(ex_pc_plus_imm));
    assign branch_pc = ex_pc_plus_imm;

    wire [31:0] ex_rs1_plus_imm, ex_jalr_target;
    adder ex_jalr_add(.a(id_ex_rs1), .b(id_ex_imm), .d(ex_rs1_plus_imm));
    assign ex_jalr_target = {ex_rs1_plus_imm[31:1], 1'b0};

    wire [31:0] ex_pc_plus4;
    adder pc_inc_ex (.a(id_ex_pc), .b(32'd4), .d(ex_pc_plus4));

    wire [1:0] final_sel;
    check_sel i_check_sel(.wb_sel(id_ex_wb_sel), .branch(id_ex_branch), .branch_meet(branch_meet), .final_sel(final_sel));

    mux_3x1 pc_branch_selector(
        .i0(next_pc),
        .i1(ex_pc_plus_imm),
        .i2(ex_jalr_target),
        .sel(final_sel),
        .d(q_pc)
    );

    wire [31:0] ex_mem_alu_result, ex_mem_write_data, ex_mem_pc_plus4;
    wire [4:0] ex_mem_rd;
    wire ex_mem_mem_write, ex_mem_mem_read, ex_mem_mem_to_reg, ex_mem_reg_write, ex_mem_jump;
    wire [2:0] ex_mem_funct3;

    ex_mem_reg U_EXMEM(
        .clock(clock),
        .ex_alu_result(alu_result),
        .ex_write_data(id_ex_rs2),
        .ex_rd(id_ex_rd),
        .ex_mem_write(id_ex_mem_write),
        .ex_mem_read(id_ex_mem_read),
        .ex_mem_to_reg(id_ex_mem_to_reg),
        .ex_reg_write(id_ex_reg_write),
        .ex_jump(id_ex_jump),
        .ex_pc_plus4(ex_pc_plus4),
        .ex_funct3(id_ex_funct3),
        .mem_alu_result(ex_mem_alu_result),
        .mem_write_data(ex_mem_write_data),
        .mem_rd(ex_mem_rd),
        .mem_mem_write(ex_mem_mem_write),
        .mem_mem_read(ex_mem_mem_read),
        .mem_mem_to_reg(ex_mem_mem_to_reg),
        .mem_reg_write(ex_mem_reg_write),
        .mem_jump(ex_mem_jump),
        .mem_pc_plus4(ex_mem_pc_plus4),
        .mem_funct3(ex_mem_funct3)
    );

    data_mem i_data_mem(
        .clock(clock),
        .addr(ex_mem_alu_result),
        .write_data(ex_mem_write_data),
        .mem_write(ex_mem_mem_write),
        .mem_read(ex_mem_mem_read),
        .funct3(ex_mem_funct3),
        .data(mem_data)
    );

    wire [31:0] wb_read_data, wb_alu_result, wb_pc_plus4;
    wire [4:0] wb_rd;
    wire wb_mem_to_reg, wb_reg_write, wb_jump;

    mem_wb_reg U_MEMWB(
        .clock(clock),
        .mem_read_data(mem_data),
        .mem_alu_result(ex_mem_alu_result),
        .mem_rd(ex_mem_rd),
        .mem_mem_to_reg(ex_mem_mem_to_reg),
        .mem_reg_write(ex_mem_reg_write),
        .mem_jump(ex_mem_jump),
        .mem_pc_plus4(ex_mem_pc_plus4),
        .wb_read_data(wb_read_data),
        .wb_alu_result(wb_alu_result),
        .wb_rd(wb_rd),
        .wb_mem_to_reg(wb_mem_to_reg),
        .wb_reg_write(wb_reg_write),
        .wb_jump(wb_jump),
        .wb_pc_plus4(wb_pc_plus4)
    );

    wire [31:0] wb_write_data;
    assign wb_write_data = wb_mem_to_reg ? wb_read_data : (wb_jump ? wb_pc_plus4 : wb_alu_result);
    assign mem_to_reg_data = wb_write_data;
endmodule
