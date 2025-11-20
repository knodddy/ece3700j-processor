`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/10/2025 09:16:38 PM
// Design Name: 
// Module Name: mux_2x1
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


module mux_2x1(
    input [31:0] i0,
    input [31:0] i1,
    input sel,
    output reg [31:0] d
    );
    always @* begin
        case (sel)
            1'b0: d = i0;
            1'b1: d = i1;
        endcase
    end
endmodule
