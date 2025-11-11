`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/10/2025 09:36:21 PM
// Design Name: 
// Module Name: control
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


module control(
    input [6:0] opcode,
    input [2:0] funct3,
    output reg alu_src,
    output reg [1:0] alu_op,
    output reg mem_write,
    output reg mem_read,
    output reg branch,
    output reg branch_ne,
    output reg mem_to_reg,
    output reg reg_write
    );
    
    always @* begin
        case (opcode)
            //add,sub,and,or,sll,srl,sra
            7'b0110011: begin
                alu_src    = 1'b0;
                alu_op     = 2'b10;
                mem_write  = 1'b0;
                mem_read   = 1'b0;
                branch     = 1'b0;
                branch_ne  = 1'b0;
                mem_to_reg = 1'b0;
                reg_write  = 1'b1;
            end
            //lw,lb,lbu
            7'b0000011: begin
                alu_src    = 1'b1;
                alu_op     = 2'b00;
                mem_write  = 1'b0;
                mem_read   = 1'b1;
                branch     = 1'b0;
                branch_ne  = 1'b0;
                mem_to_reg = 1'b1;
                reg_write  = 1'b1;
            end
            //sw,sb
            7'b0100011: begin
                alu_src    = 1'b1;
                alu_op     = 2'b00;
                mem_write  = 1'b1;
                mem_read   = 1'b0;
                branch     = 1'b0;
                branch_ne  = 1'b0;
                mem_to_reg = 1'b0;
                reg_write  = 1'b0;
            end
            //beq,bne,bge,blt
            7'b1100011: begin
                alu_src    = 1'b0;
                alu_op     = 2'b01;
                mem_write  = 1'b0;
                mem_read   = 1'b0;
                branch     = 1'b1;
                branch_ne  = (funct3 == 3'b001);
                mem_to_reg = 1'b0;
                reg_write  = 1'b0;
            end
            //addi, andi,slli,srli
            7'b0010011: begin
                alu_src    = 1'b1;
                alu_op     = 2'b00;
                mem_write  = 1'b0;
                mem_read   = 1'b0;
                branch     = 1'b0;
                branch_ne  = 1'b0;
                mem_to_reg = 1'b0;
                reg_write  = 1'b1;
            end
            
            default: begin
                alu_src=0; alu_op=2'b00; mem_write=0; mem_read=0;
                branch=0; branch_ne=0; mem_to_reg=0; reg_write=0;
            end
        endcase
    end
endmodule
