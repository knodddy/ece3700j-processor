`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/10/2025 10:38:28 PM
// Design Name: 
// Module Name: inst_mem
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


module inst_mem #(parameter MAX_INST_SIZE = 255) (
    input [31:0] pc,
    output [31:0] inst
    );
    reg [7:0] mem [0:MAX_INST_SIZE];
    
    integer i;

    // initialization
    initial begin
        for(i=0;i<MAX_INST_SIZE+1;i=i+1)begin
            mem[i] = 8'b0000_0000;
        end
        
//        {mem[3],mem[2],mem[1],mem[0]} = 32'hff60_0293;
//        {mem[7],mem[6],mem[5],mem[4]} = 32'h0052_8333;
//        {mem[11],mem[10],mem[9],mem[8]} = 32'h4062_83b3;
//        {mem[15],mem[14],mem[13],mem[12]} = 32'h0003_7e33;
//        {mem[19],mem[18],mem[17],mem[16]} = 32'h0053_6eb3;
//        {mem[23],mem[22],mem[21],mem[20]} = 32'h01d0_2023;
//        {mem[27],mem[26],mem[25],mem[24]} = 32'h0050_2223;
//        {mem[31],mem[30],mem[29],mem[28]} = 32'h0002_8463;
//        {mem[35],mem[34],mem[33],mem[32]} = 32'h0003_0eb3;
//        {mem[39],mem[38],mem[37],mem[36]} = 32'h01d3_1463;
//        {mem[43],mem[42],mem[41],mem[40]} = 32'h01c3_1463;
//        {mem[47],mem[46],mem[45],mem[44]} = 32'h0000_03b3;
//        {mem[51],mem[50],mem[49],mem[48]} = 32'h0000_2403;
//        {mem[55],mem[54],mem[53],mem[52]} = 32'h0040_2483;
//        {mem[59],mem[58],mem[57],mem[56]} = 32'h0084_8493;
//        {mem[63],mem[62],mem[61],mem[60]} = 32'h0094_0463;
//        {mem[67],mem[66],mem[65],mem[64]} = 32'h0000_03b3;
//        {mem[71],mem[70],mem[69],mem[68]} = 32'h0073_83b3;
    end
    
    assign inst = {mem[pc+3], mem[pc+2], mem[pc+1], mem[pc+0]};
endmodule
