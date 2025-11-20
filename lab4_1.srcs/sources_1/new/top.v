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
    wire [31:0] pc;
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

    wire [31:0] ex_mem_alu_result, ex_mem_write_data, ex_mem_pc_plus4;
    wire [4:0] ex_mem_rd, ex_mem_rs2_addr;
    wire ex_mem_mem_write, ex_mem_mem_read, ex_mem_mem_to_reg, ex_mem_reg_write, ex_mem_jump;
    wire [2:0] ex_mem_funct3;

    wire [31:0] wb_read_data, wb_alu_result, wb_pc_plus4;
    wire [4:0] wb_rd;
    wire wb_mem_to_reg, wb_reg_write, wb_jump;
    wire [31:0] wb_write_data;
    
    
    wire PC_write;
    wire IF_ID_write;
    wire clear_control;

    wire [31:0] q_pc_new;

    
////////////////////////////////////////////////////PC////////////////////////////////////////////////////

    pc_reg i_pc_reg (
        .clock(clock),
        .next_pc(q_pc_new),   
        .PC_write(PC_write),
        .pc(pc)
    );    

    inst_mem i_inst_mem (
        .pc(pc), 
        .inst(inst)
    );

    // pc + 4，作为"顺序执行"的下一条 PC
    adder pc_incrementer (
        .a(pc), 
        .b(32'd4), 
        .d(next_pc)
    );
    
    
////////////////////////////////////////////////////IF-ID////////////////////////////////////////////////////
    wire [31:0] if_id_pc, if_id_inst;
    wire IF_Flush;
    
    if_id_reg U_IFID (
        .clock      (clock),
        .IF_Flush   (IF_Flush),
        .IF_ID_write(IF_ID_write),
        .if_pc      (pc),
        .if_inst    (inst),
        .id_pc      (if_id_pc),
        .id_inst    (if_id_inst)
    );    
    
    
////////////////////////////////////////////////////ID////////////////////////////////////////////////////
    wire jump;
    wire [1:0] br_type;
    wire [1:0] br_wb_sel;
    assign branch_ne = 1'b0;
    
    
    control i_control(
        .opcode    (if_id_inst[6:0]),
        .funct3    (if_id_inst[14:12]),
        .alu_src   (alu_src),
        .alu_op    (alu_op),
        .mem_write (mem_write),
        .mem_read  (mem_read),
        .branch    (branch),
        .br_type   (br_type),
        .mem_to_reg(mem_to_reg),
        .reg_write (reg_write),
        .wb_sel    (br_wb_sel),
        .jump      (jump)            // JAL / JALR: jump = 1
    );
    
    reg_file i_reg_file(
        .clock     (clock),
        .reg_1     (if_id_inst[19:15]),
        .reg_2     (if_id_inst[24:20]),
        .reg_write (wb_reg_write),
        .write_reg (wb_rd),
        .write_data(mem_to_reg_data),
        .data_1    (reg_data_1),
        .data_2    (reg_data_2)
    );

    imm_gen i_imm_gen(
        .inst(if_id_inst), 
        .imm(imm)
    );
    
    
    wire [4:0] id_ex_rd;
    wire id_ex_mem_write, id_ex_mem_read, id_ex_branch, id_ex_mem_to_reg, id_ex_reg_write, id_ex_jump;
    wire [4:0] id_rs1_addr, id_rs2_addr;
    assign id_rs1_addr = if_id_inst[19:15];
    assign id_rs2_addr = if_id_inst[24:20];
    
    wire [1:0] id_final_sel_new;

    hazard_detection i_hazard_detection(
        .id_ex_mem_read (id_ex_mem_read),
        .id_ex_reg_write(id_ex_reg_write),
        .id_ex_rd       (id_ex_rd),

        .ex_mem_mem_read(ex_mem_mem_read),   
        .ex_mem_rd      (ex_mem_rd),         

        .if_id_rs1      (id_rs1_addr),
        .if_id_rs2      (id_rs2_addr),

        // 这里建议在 hazard_detection 里，把 "控制转移" 统一看作：
        // id_final_sel_new != 2'b00 就表示当前 ID 指令改变了 PC（branch taken / jal / jalr）
        // if_id_is_branch 信号可以不用只看 branch，而是结合 id_final_sel_new 来判断
        .if_id_is_branch(branch),       // 如果你修改了接口，可以改成 .if_id_is_ctrl(id_final_sel_new != 2'b00)

        .id_final_sel   (id_final_sel_new),

        .PC_write       (PC_write),
        .IF_ID_write    (IF_ID_write),
        .clear_control  (clear_control),
        .IF_Flush       (IF_Flush)
    );
    
    wire [31:0] br_op1_id;
    wire [31:0] br_op2_id;
    
    // EX/MEM -> ID forwarding（用于 branch / jalr 的 rs1 / rs2）
    assign br_op1_id =
        (ex_mem_reg_write && (ex_mem_rd != 5'd0) && (ex_mem_rd == id_rs1_addr))
            ? ex_mem_alu_result
            : reg_data_1;
    
    assign br_op2_id =
        (ex_mem_reg_write && (ex_mem_rd != 5'd0) && (ex_mem_rd == id_rs2_addr))
            ? ex_mem_alu_result
            : reg_data_2;
    
    wire id_branch_meet_new;
    compare_new id_compare_new(
        .reg_data_1 (br_op1_id),
        .reg_data_2 (br_op2_id),
        .br_type    (br_type),
        .branch_meet(id_branch_meet_new)
    );
        
        
    check_sel id_check_sel_new(
        .wb_sel     (br_wb_sel),
        .branch     (branch),
        .branch_meet(id_branch_meet_new),
        .final_sel  (id_final_sel_new)
    );
    
    // *** 重要修改 1：jalr 目标地址要用"已经做了 ID 阶段 forwarding 的 rs1"
    // 否则如果上一条指令刚写 rs1，这里会用到旧值
    wire [31:0] jalr_sum;
    adder id_jalr_calculate_new(
        .a(br_op1_id),   // 原来是 reg_data_1，这里改成 br_op1_id
        .b(imm),
        .d(jalr_sum)
    );

    // RISC-V 规定 jalr 目标地址最低位清零
    wire [31:0] id_jalr_target_new = {jalr_sum[31:1], 1'b0};
    
    wire [31:0] id_pc_plus_imm_new;
    adder id_pc_plus_imm(
        .a(if_id_pc),
        .b(imm),
        .d(id_pc_plus_imm_new)
    );
    
    // 最终 PC 选择：
    // sel = 2'b00: 顺序执行 PC+4
    // sel = 2'b01: branch taken 或 jal（PC + imm）
    // sel = 2'b10: jalr（rs1 + imm，对齐）
    mux_3x1 id_sel_pc_new(
        .i0(next_pc),
        .i1(id_pc_plus_imm_new),
        .i2(id_jalr_target_new),
        .sel(id_final_sel_new),
        .d(q_pc_new)
    );
    
    
////////////////////////////////////////////////////ID-EX////////////////////////////////////////////////////

    wire [31:0] id_ex_pc, id_ex_rs1, id_ex_rs2, id_ex_imm;
    wire [2:0] id_ex_funct3;
    wire id_ex_inst30;
    
    wire [1:0] id_ex_alu_op, id_ex_br_type, id_ex_wb_sel;
    wire id_ex_alu_src;

    // rs1/rs2 indices in EX + forwarding control
    wire [4:0] id_ex_rs1_addr, id_ex_rs2_addr;
    wire [1:0] forwardA, forwardB;
    wire [31:0] ex_rs1_fwd, ex_rs2_fwd;

    id_ex_reg U_IDEX(
        .clock        (clock),
        .clear_control(clear_control),

        .id_pc        (if_id_pc),
        .id_rs1_data  (reg_data_1),
        .id_rs2_data  (reg_data_2),
        .id_rs1_addr  (id_rs1_addr),
        .id_rs2_addr  (id_rs2_addr),
        .id_imm       (imm),
        .id_funct3    (if_id_inst[14:12]),
        .id_inst30    (if_id_inst[30]),
        .id_rd        (if_id_inst[11:7]),

        .id_alu_src   (alu_src),
        .id_alu_op    (alu_op),
        .id_mem_write (mem_write),
        .id_mem_read  (mem_read),
        .id_branch    (branch),
        .id_br_type   (br_type),
        .id_mem_to_reg(mem_to_reg),
        .id_reg_write (reg_write),
        .id_wb_sel    (br_wb_sel),
        .id_jump      (jump),

        .ex_pc        (id_ex_pc),
        .ex_rs1_data  (id_ex_rs1),
        .ex_rs2_data  (id_ex_rs2),
        .ex_rs1_addr  (id_ex_rs1_addr),
        .ex_rs2_addr  (id_ex_rs2_addr),
        .ex_imm       (id_ex_imm),
        .ex_funct3    (id_ex_funct3),
        .ex_inst30    (id_ex_inst30),
        .ex_rd        (id_ex_rd),

        .ex_alu_src   (id_ex_alu_src),
        .ex_alu_op    (id_ex_alu_op),
        .ex_mem_write (id_ex_mem_write),
        .ex_mem_read  (id_ex_mem_read),
        .ex_branch    (id_ex_branch),
        .ex_br_type   (id_ex_br_type),
        .ex_mem_to_reg(id_ex_mem_to_reg),
        .ex_reg_write (id_ex_reg_write),
        .ex_wb_sel    (id_ex_wb_sel),
        .ex_jump      (id_ex_jump)
    );
    
    
    
////////////////////////////////////////////////////EX////////////////////////////////////////////////////

    // forwarding logic for EX and MEM hazards
    forwarding_unit i_forwarding(
        .ex_mem_reg_write(ex_mem_reg_write),
        .ex_mem_rd       (ex_mem_rd),
        .mem_wb_reg_write(wb_reg_write),
        .mem_wb_rd       (wb_rd),
        .id_ex_rs1_addr  (id_ex_rs1_addr),
        .id_ex_rs2_addr  (id_ex_rs2_addr),
        .forwardA        (forwardA),
        .forwardB        (forwardB)
    );

    // Forwarding muxes for ALU inputs (and store data via ex_rs2_fwd)
    mux_3x1 fwdA_mux(
        .i0(id_ex_rs1),         // 00: original rs1
        .i1(wb_write_data),     // 01: from MEM/WB
        .i2(ex_mem_alu_result), // 10: from EX/MEM
        .sel(forwardA),
        .d(ex_rs1_fwd)
    );

    mux_3x1 fwdB_mux(
        .i0(id_ex_rs2),         // 00: original rs2
        .i1(wb_write_data),     // 01: from MEM/WB
        .i2(ex_mem_alu_result), // 10: from EX/MEM
        .sel(forwardB),
        .d(ex_rs2_fwd)
    );

    mux_2x1 alu_src_mux(
        .i0(ex_rs2_fwd),
        .i1(id_ex_imm),
        .sel(id_ex_alu_src),
        .d(alu_src_data)
    );
    
    alu_control i_alu_control(
        .inst_30(id_ex_inst30),
        .funct3 (id_ex_funct3),
        .alu_op (id_ex_alu_op),
        .control(alu_control_signal)
    );
    
    alu i_alu(
        .control(alu_control_signal),
        .a      (ex_rs1_fwd),
        .b      (alu_src_data),
        .zero   (zero),
        .d      (alu_result)
    );
    
    
    wire [31:0] ex_pc_plus4;
    adder pc_inc_ex (
        .a(id_ex_pc),
        .b(32'd4),
        .d(ex_pc_plus4)
    );

       
    
////////////////////////////////////////////////////EX-MEM////////////////////////////////////////////////////
    ex_mem_reg U_EXMEM(
        .clock        (clock),
        .ex_alu_result(alu_result),
        .ex_write_data(ex_rs2_fwd),
        .ex_rd        (id_ex_rd),
        .ex_rs2_addr  (id_ex_rs2_addr),
        .ex_mem_write (id_ex_mem_write),
        .ex_mem_read  (id_ex_mem_read),
        .ex_mem_to_reg(id_ex_mem_to_reg),
        .ex_reg_write (id_ex_reg_write),
        .ex_jump      (id_ex_jump),
        .ex_pc_plus4  (ex_pc_plus4),
        .ex_funct3    (id_ex_funct3),

        .mem_alu_result(ex_mem_alu_result),
        .mem_write_data(ex_mem_write_data),
        .mem_rd        (ex_mem_rd),
        .mem_rs2_addr  (ex_mem_rs2_addr),
        .mem_mem_write (ex_mem_mem_write),
        .mem_mem_read  (ex_mem_mem_read),
        .mem_mem_to_reg(ex_mem_mem_to_reg),
        .mem_reg_write (ex_mem_reg_write),
        .mem_jump      (ex_mem_jump),
        .mem_pc_plus4  (ex_mem_pc_plus4),
        .mem_funct3    (ex_mem_funct3)
    );
    
    
    
////////////////////////////////////////////////////MEM////////////////////////////////////////////////////
    wire [31:0] mem_stage_write_data;
    wire memsrc;

    // store-after-load 的 MEM hazard：把刚 load 出来的数据直接 forward 给 store
    assign memsrc = ex_mem_mem_write &&
                    wb_mem_to_reg &&
                    wb_reg_write &&
                    (wb_rd != 5'd0) &&
                    (wb_rd == ex_mem_rs2_addr);

    mux_2x1 mem_write_data_mux(
        .i0(ex_mem_write_data),
        .i1(wb_read_data),
        .sel(memsrc),
        .d(mem_stage_write_data)
    );

    data_mem i_data_mem(
        .clock    (clock),
        .addr     (ex_mem_alu_result),
        .write_data(mem_stage_write_data),
        .mem_write(ex_mem_mem_write),
        .mem_read (ex_mem_mem_read),
        .funct3   (ex_mem_funct3),
        .data     (mem_data)
    );
    
    
////////////////////////////////////////////////////MEM-WB////////////////////////////////////////////////////
    mem_wb_reg U_MEMWB(
        .clock        (clock),
        .mem_read_data(mem_data),
        .mem_alu_result(ex_mem_alu_result),
        .mem_rd       (ex_mem_rd),
        .mem_mem_to_reg(ex_mem_mem_to_reg),
        .mem_reg_write(ex_mem_reg_write),
        .mem_jump     (ex_mem_jump),
        .mem_pc_plus4 (ex_mem_pc_plus4),

        .wb_read_data (wb_read_data),
        .wb_alu_result(wb_alu_result),
        .wb_rd        (wb_rd),
        .wb_mem_to_reg(wb_mem_to_reg),
        .wb_reg_write (wb_reg_write),
        .wb_jump      (wb_jump),
        .wb_pc_plus4  (wb_pc_plus4)
    );
    
    
    
////////////////////////////////////////////////////WB////////////////////////////////////////////////////
    // WB 选择：
    // mem_to_reg = 1: 从数据存储器读出（load）
    // mem_to_reg = 0 且 jump = 1: 写回 PC+4（jal / jalr）
    // 其他：写回 ALU 结果
    assign wb_write_data = wb_mem_to_reg 
                           ? wb_read_data 
                           : (wb_jump ? wb_pc_plus4 : wb_alu_result);

    assign mem_to_reg_data = wb_write_data;
endmodule
