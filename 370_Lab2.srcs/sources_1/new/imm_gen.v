`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/10/2025 06:22:29 PM
// Design Name: 
// Module Name: imm_gen
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

// Generates immediates from 32-bit operations
module imm_gen(
    input [31:0] inst,
    output reg [31:0] imm
    );
    
    always @* begin
        case (inst[6:0])
            7'b0010011: // addi immediate
                imm = {{20{inst[31]}}, inst[31:20]};
            7'b0000011: // lw immediate
                imm = {{20{inst[31]}}, inst[31:20]};
            7'b0100011: // sw immediate
                imm = {{20{inst[31]}}, inst[31:25], inst[11:7]};
            7'b1100011: // beq & bne immediate
//                imm = {{20{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8]};
                imm = {{19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};
            default:
                imm = 32'b0;
        endcase
    end
endmodule
