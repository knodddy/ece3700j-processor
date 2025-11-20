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
    input        id_ex_mem_read,     // ID/EX.MemRead
    input        id_ex_reg_write,    // ID/EX.RegWrite
    input  [4:0] id_ex_rd,           // ID/EX.rd

    // EX/MEM stage signal（for lw + branch, stall 2 cycles）
    input        ex_mem_mem_read,    // EX/MEM.MemRead  
    input  [4:0] ex_mem_rd,          // EX/MEM.rd       

    // IF/ID stage instruction
    input  [4:0] if_id_rs1,          // IF/ID.rs1
    input  [4:0] if_id_rs2,          // IF/ID.rs2

    // if IF/ID inst is a branch or not
    input        if_id_is_branch,    // ID sta branch（from control）

    // ---------- control hazard ----------
    input  [1:0] id_final_sel,       // from check_sel in ID stage

    // ---------- outputs ----------
    output reg   PC_write,
    output reg   IF_ID_write,
    output reg   clear_control,      // bubble in ID/EX
    output reg   IF_Flush            // flush IF/ID
);

    // 1) load-use hazard
    wire load_use_hazard =
        id_ex_mem_read &&
        !if_id_is_branch &&                 // ont include branch
        (id_ex_rd != 5'd0) &&               // ignore x0
        ((id_ex_rd == if_id_rs1) ||
         (id_ex_rd == if_id_rs2));

    // 2) ALU + branch hazard
    wire ex_branch_hazard =
        id_ex_reg_write &&                  // EX will write into rd
        !id_ex_mem_read &&                  // not lw
        if_id_is_branch &&
        (id_ex_rd != 5'd0) &&
        ((id_ex_rd == if_id_rs1) ||
         (id_ex_rd == if_id_rs2));

    // 3) lw + branch hazard
    //    stall two cycles：
    //    1 ：load in EX（ID/EX.MemRead=1）
    //    2 ：load in MEM（EX/MEM.MemRead=1）
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

    // all cases that requires stall
    wire need_stall = load_use_hazard | ex_branch_hazard | load_branch_hazard;

    always @* begin
    // default：no stall,no flush
    PC_write      = 1'b1;
    IF_ID_write   = 1'b1;
    clear_control = 1'b0;
    IF_Flush      = 1'b0;

    if (need_stall) begin
        // data hazard：stall one clk cyce or two
        PC_write      = 1'b0;   // hold PC
        IF_ID_write   = 1'b0;   // hold IF/ID
        clear_control = 1'b1;   // 把当前要进 ID/EX 的那条清成 NOP
        // IF_Flush = 0
    end 
    //  only flush IF/ID
    else if (id_final_sel != 2'b00) begin
        // control hazard：branch taken / jal / jalr
        IF_Flush      = 1'b1;   // flush the wrong inst in IF/ID reg
        // clear_control keeps 0 to let the current branch/jal/jalr ID stage flow into EX/MEM/WB
        // PC_write / IF_ID_write keeps to be 1 to let branch/jump happen
    end
end

endmodule