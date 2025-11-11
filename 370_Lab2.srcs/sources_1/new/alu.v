`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/10/2025 09:22:39 PM
// Design Name: 
// Module Name: alu
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


module alu(
    input [3:0] control,
    input [31:0] a,
    input [31:0] b,
    output reg zero,
    output reg [31:0] d
    );
    
    always @* begin
        case (control)
        //+,-,and,or, shift left, shift right
            4'b0000: d = a & b;               // AND
            4'b0001: d = a | b;               // OR
            4'b0010: d = a + b;               // ADD
            4'b0110: d = a - b;               // SUB
            4'b0011: d = a << b[4:0];         // SLL shift left logic
            4'b0100: d = a >> b[4:0];         // SRL shift right logic
            4'b0101: d = $signed(a) >>> b[4:0]; // SRA shift right arithmetic
        endcase
        
        if (d == 32'b0)
            zero = 1'b1;
        else
            zero = 1'b0;
    end
endmodule
