`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/11/2025 04:47:30 PM
// Design Name: 
// Module Name: pc_reg
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


module pc_reg(
    input        clock,
    input        PC_write,
    input [31:0] next_pc,
    output reg [31:0] pc
);
    initial begin
        pc = 32'd0;   // initialize pc to 0
    end
    always @(posedge clock) begin
        if (PC_write)
            pc <= next_pc;
    end
endmodule
