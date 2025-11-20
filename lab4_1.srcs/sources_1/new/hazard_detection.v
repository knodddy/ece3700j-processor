`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/19 22:21:32
// Design Name: 
// Module Name: hazard_detection
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


module hazard_detection(
    // ---------- data hazard ----------
    // ID/EX 阶段的信息
    input        id_ex_mem_read,     // ID/EX.MemRead
    input        id_ex_reg_write,    // ID/EX.RegWrite
    input  [4:0] id_ex_rd,           // ID/EX.rd

    // EX/MEM 阶段的信息（为了 lw + branch 要 stall 两拍）
    input        ex_mem_mem_read,    // EX/MEM.MemRead  ★ 新增
    input  [4:0] ex_mem_rd,          // EX/MEM.rd       ★ 新增

    // IF/ID 阶段当前指令（通常是 branch）的寄存器号
    input  [4:0] if_id_rs1,          // IF/ID.rs1
    input  [4:0] if_id_rs2,          // IF/ID.rs2

    // IF/ID 当前是不是 branch
    input        if_id_is_branch,    // ID 阶段 branch 信号（来自 control）

    // ---------- control hazard ----------
    input  [1:0] id_final_sel,       // from check_sel in ID stage

    // ---------- outputs ----------
    output reg   PC_write,
    output reg   IF_ID_write,
    output reg   clear_control,      // bubble in ID/EX
    output reg   IF_Flush            // flush IF/ID
);

    // 1) 普通 load-use hazard：lw x1,...; 后面任意指令用 x1（非 branch）
    wire load_use_hazard =
        id_ex_mem_read &&
        !if_id_is_branch &&                 // 这里不包括 branch，用下面专门的 load-branch 逻辑
        (id_ex_rd != 5'd0) &&               // ignore x0
        ((id_ex_rd == if_id_rs1) ||
         (id_ex_rd == if_id_rs2));

    // 2) EX→ID 的 ALU + branch hazard：add x4,...; beq x1,x4
    wire ex_branch_hazard =
        id_ex_reg_write &&                  // EX 这条会写 rd
        !id_ex_mem_read &&                  // 排除 lw，lw 用 load_branch_hazard 处理
        if_id_is_branch &&
        (id_ex_rd != 5'd0) &&
        ((id_ex_rd == if_id_rs1) ||
         (id_ex_rd == if_id_rs2));

    // 3) lw + branch hazard：lw x1,...; beq x1,x4
    //    需要 stall 两个 cycle：
    //    第 1 拍：load 在 EX（ID/EX.MemRead=1）
    //    第 2 拍：load 在 MEM（EX/MEM.MemRead=1）
    wire load_branch_hazard_stage1 =
        if_id_is_branch &&
        id_ex_mem_read &&
        (id_ex_rd != 5'd0) &&
        ((id_ex_rd == if_id_rs1) ||
         (id_ex_rd == if_id_rs2));

    wire load_branch_hazard_stage2 =
        if_id_is_branch &&
        ex_mem_mem_read &&
        (ex_mem_rd != 5'd0) &&
        ((ex_mem_rd == if_id_rs1) ||
         (ex_mem_rd == if_id_rs2));

    wire load_branch_hazard = load_branch_hazard_stage1 | load_branch_hazard_stage2;

    // 需要 stall 的所有情况
    wire need_stall = load_use_hazard | ex_branch_hazard | load_branch_hazard;

    always @* begin
    // 默认：不 stall、不 flush
    PC_write      = 1'b1;
    IF_ID_write   = 1'b1;
    clear_control = 1'b0;
    IF_Flush      = 1'b0;

    if (need_stall) begin
        // data hazard：stall 一拍（或两拍）
        PC_write      = 1'b0;   // hold PC
        IF_ID_write   = 1'b0;   // hold IF/ID
        clear_control = 1'b1;   // 把当前要进 ID/EX 的那条清成 NOP
        // IF_Flush = 0
    end 
    // *** 这里改动：控制冒险不再清 ID/EX，只 flush IF/ID ***
    else if (id_final_sel != 2'b00) begin
        // control hazard：branch taken / jal / jalr
        IF_Flush      = 1'b1;   // 丢掉 IF 里已经取到的下一条（错路径）
        // clear_control 保持 0，让当前 ID 这条 branch/jal/jalr 正常流进 EX/MEM/WB
        // PC_write / IF_ID_write 继续为 1，让 PC 跳转生效
    end
end

endmodule