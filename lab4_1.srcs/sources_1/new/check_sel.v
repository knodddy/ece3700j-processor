`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/12 17:30:09
// Design Name: 
// Module Name: check_sel
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


module check_sel(
    input [1:0] wb_sel,
    input branch,
    input branch_meet,
    output reg [1:0] final_sel
    );
    
    always @* begin
        if (branch==1'b1)
        begin
            case (branch_meet)
                1'b1: final_sel=wb_sel;
                1'b0: final_sel=2'b00;
            endcase
        end
        else final_sel=wb_sel;
    end
endmodule
