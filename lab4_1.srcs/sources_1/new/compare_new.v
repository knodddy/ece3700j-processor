`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/19 23:11:31
// Design Name: 
// Module Name: compare_new
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


module compare_new(
    input [31:0] reg_data_1,
    input [31:0] reg_data_2,
    input [1:0] br_type,
    output reg branch_meet
    );

    always @* begin
        case (br_type)
            2'b00: branch_meet = (reg_data_1 == reg_data_2);                   // beq
            2'b01: branch_meet = (reg_data_1 != reg_data_2);                   // bne
            2'b10: branch_meet = ($signed(reg_data_1) <  $signed(reg_data_2)); // blt
            2'b11: branch_meet = ($signed(reg_data_1) >= $signed(reg_data_2)); // bge
            default: branch_meet = 1'b0;
        endcase
    end
endmodule
