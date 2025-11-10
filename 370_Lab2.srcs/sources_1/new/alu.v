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
            4'b0000: d = a & b;
            4'b0001: d = a | b;
            4'b0010: d = a + b;
            4'b0110: d = a - b;
            default: d = 32'b0;
        endcase
        
        if (d == 32'b0)
            zero = 1'b1;
        else
            zero = 1'b0;
    end
endmodule
