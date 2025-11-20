`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/12 17:26:36
// Design Name: 
// Module Name: mux_3x1
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


module mux_3x1(
    input [31:0] i0,
    input [31:0] i1,
    input [31:0] i2,
    input [1:0]sel,
    output reg [31:0] d
    );
    always @* begin
        case (sel)
            2'b00: d = i0;
            2'b01: d = i1;
            2'b10: d = i2;
            default: d = 32'b0;
        endcase
    end
endmodule
