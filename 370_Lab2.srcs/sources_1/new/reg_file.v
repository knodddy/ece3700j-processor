`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/11/2025 03:02:36 PM
// Design Name: 
// Module Name: reg_file
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


module reg_file(
    input clock,
    input [4:0] reg_1,
    input [4:0] reg_2,
    input reg_write,
    input [4:0] write_reg,
    input [31:0] write_data,
    output [31:0] data_1,
    output [31:0] data_2
);
    reg [31:0] regs [0:31];
    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1) regs[i] = 32'd0;
    end

    assign data_1 = (reg_1 == 5'd0) ? 32'd0 : regs[reg_1];
    assign data_2 = (reg_2 == 5'd0) ? 32'd0 : regs[reg_2];

    always @(posedge clock) begin // need clock cause of timing sensitive
        if (reg_write && (write_reg != 5'd0))
            regs[write_reg] <= write_data;
    end
endmodule

