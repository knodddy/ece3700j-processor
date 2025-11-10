`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/10/2025 09:26:56 PM
// Design Name: 
// Module Name: alu_control
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

module alu_control(
    input inst_30,
    input [2:0] funct3,
    input [1:0] alu_op,
    output reg [3:0] control
    );
    
    always @* begin
        if (alu_op == 2'b00 || alu_op == 2'b01) begin
            case (alu_op)
                2'b00: control = 4'b0010;
                2'b01: control = 4'b0110;
                default: control = 4'b0010; // default to ADD
            endcase
        end else if (alu_op == 2'b10) begin
            case ({inst_30, funct3})
                4'b0000: control = 4'b0010;
                4'b1000: control = 4'b0110;
                4'b0111: control = 4'b0000;
                4'b0110: control = 4'b0001;
                default: control = 4'b0010; // default to ADD
            endcase
        end
    end
endmodule
