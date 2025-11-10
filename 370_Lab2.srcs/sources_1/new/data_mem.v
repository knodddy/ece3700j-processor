`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/11/2025 02:42:07 PM
// Design Name: 
// Module Name: data_mem
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


module data_mem #(parameter MAX_MEM_SIZE = 1023) (
    input clock,
    input [31:0] addr,
    input [31:0] write_data,
    input mem_write,
    input mem_read,
    output reg [31:0] data
    );
    reg [7:0] mem [0:MAX_MEM_SIZE];
    
    integer i;
    initial begin
        for (i = 0; i <= MAX_MEM_SIZE; i = i + 1) begin
            mem[i] = 8'd0;
        end
    end
    
    always @(posedge clock) begin // also bounded by clock?
        if (mem_write) begin
            mem[addr]   <= write_data[7:0];
            mem[addr+1] <= write_data[15:8];
            mem[addr+2] <= write_data[23:16];
            mem[addr+3] <= write_data[31:24];
        end
    end
    
    always @* begin
        if (mem_read)
            data = {mem[addr+3], mem[addr+2], mem[addr+1], mem[addr+0]};
        else
            data = 32'b0;
    end
endmodule
