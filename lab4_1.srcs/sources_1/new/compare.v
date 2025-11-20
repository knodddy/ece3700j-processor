`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/12 15:38:30
// Design Name: 
// Module Name: compare
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


module compare(
    input zero,
    input [31:0] alu_result,
    input [1:0] br_type,
    output reg branch_meet
    );
    always @* begin
        case (br_type)
            2'b00: begin //beq
                if (zero==1'b1) branch_meet=1'b1;
                else branch_meet=1'b0;
            end
            2'b01: begin //bne
                if (zero==1'b1) branch_meet=1'b0;
                else branch_meet=1'b1;                
            end
            2'b10:  //blt
                branch_meet = alu_result[0];              
            2'b11://bge
                branch_meet = ~alu_result[0];
            default: branch_meet=1'b0;
        endcase
    end
endmodule
