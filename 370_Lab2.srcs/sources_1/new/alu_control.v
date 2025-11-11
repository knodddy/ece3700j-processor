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
        if (alu_op == 2'b00) begin //addi, andi, slli, srli,lw, sw,lb, lbu,sb
            case (funct3)
                3'b000: control = 4'b0010;//addi,lb,sb
                3'b111: control = 4'b0000;//andi
                3'b001: control = 4'b0011;//slli
                3'b101: control = 4'b0100;//srli
                3'b010: control = 4'b0010;//lw,sw
                3'b100: control = 4'b0010;//lbu
                default: control = 4'b0010; // default to ADD
            endcase 
        end
        else if (alu_op == 2'b01) begin //beq,bne,bge,blt
            control = 4'b0110;
        end
        else if (alu_op == 2'b10) begin//add,sub,AND,OR，sll,srl,sra : R type
            case ({inst_30, funct3})
                4'b0000: control = 4'b0010;//add
                4'b1000: control = 4'b0110;//sub
                4'b0111: control = 4'b0000;//and
                4'b0110: control = 4'b0001;//or
                4'b0001: control = 4'b0011;//sll
                4'b0101: control = 4'b0100;//srl
                4'b1101: control = 4'b0101;//sra
                default: control = 4'b0010; // default to ADD
            endcase
        end
    end
endmodule
