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
    input [2:0] funct3,
    output reg [31:0] data
    );
    reg [7:0] mem [0:MAX_MEM_SIZE];
    
    integer i;
    initial begin
        for (i = 0; i <= MAX_MEM_SIZE; i = i + 1) begin
            mem[i] = 8'd0;
        end
    end

    wire [7:0] rd_byte  = mem[addr];
    wire [31:0] rd_word = {mem[addr+3], mem[addr+2], mem[addr+1], mem[addr+0]};

    // Write
    always @(posedge clock) begin
        if (mem_write) begin
            case (funct3)
                3'b000: begin // sb
                    mem[addr] <= write_data[7:0];
                end
                3'b010: begin // sw
                    mem[addr]   <= write_data[7:0];
                    mem[addr+1] <= write_data[15:8];
                    mem[addr+2] <= write_data[23:16];
                    mem[addr+3] <= write_data[31:24];
                end
            endcase
        end
    end

    // Read
    always @* begin
        if (mem_read) begin
            case (funct3)
                3'b000: data = {{24{rd_byte[7]}}, rd_byte}; // lb
                3'b100: data = {24'd0, rd_byte};            // lbu
                3'b010: data = rd_word;                     // lw
                default: data = 32'd0;
            endcase
        end else begin
            data = 32'd0;
        end
    end
endmodule

