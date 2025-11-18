`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18/11/2025 20:00:00 
// Design Name: 
// Module Name: forwarding_unit
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: forwarding unit for EX and MEM hazards
// Dependencies: 
// 
// Revision:
// Revision 0.01
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module forwarding_unit(
    input        ex_mem_reg_write,
    input  [4:0] ex_mem_rd,
    input        mem_wb_reg_write,
    input  [4:0] mem_wb_rd,
    input  [4:0] id_ex_rs1_addr,
    input  [4:0] id_ex_rs2_addr,
    output reg [1:0] forwardA,
    output reg [1:0] forwardB
);
    always @* begin
        // defaults: NO forwarding
        forwardA = 2'b00;
        forwardB = 2'b00;

        // EX hazard: forward from EX/MEM
        if (ex_mem_reg_write && (ex_mem_rd != 5'd0) &&
            (ex_mem_rd == id_ex_rs1_addr))
            forwardA = 2'b10;

        if (ex_mem_reg_write && (ex_mem_rd != 5'd0) &&
            (ex_mem_rd == id_ex_rs2_addr))
            forwardB = 2'b10;

        // MEM hazard: forward from MEM/WB (only if EX hazard not already chosen)
        if (mem_wb_reg_write && (mem_wb_rd != 5'd0) &&
            (mem_wb_rd == id_ex_rs1_addr) &&
            !(ex_mem_reg_write && (ex_mem_rd != 5'd0) &&
              (ex_mem_rd == id_ex_rs1_addr)))
            forwardA = 2'b01;

        if (mem_wb_reg_write && (mem_wb_rd != 5'd0) &&
            (mem_wb_rd == id_ex_rs2_addr) &&
            !(ex_mem_reg_write && (ex_mem_rd != 5'd0) &&
              (ex_mem_rd == id_ex_rs2_addr)))
            forwardB = 2'b01;
    end
endmodule