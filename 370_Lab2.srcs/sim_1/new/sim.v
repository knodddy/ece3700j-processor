`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 10/13/2025 07:30:10 PM
// Design Name:
// Module Name: sim
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

module sim;
    parameter half_period = 3;
    parameter MAX_CYCLES  = 5000;

    reg clk;
    initial clk = 1'b0;
    always #(half_period) clk = ~clk;

    top SCP(.clock(clk));

    integer cyc = 0;
    initial begin
        forever begin
            @(posedge clk);
            cyc = cyc + 1;
            if (cyc >= MAX_CYCLES) begin
                $display("Timeout: hit %0d cycles without HALT, stopping.", MAX_CYCLES);
                $finish;
            end
        end
    end

    integer drain = -1;
    initial begin
        forever begin
            @(posedge clk);
            #1;

            $display("time: %0t", $time);
            $display("ra = 0x%08h", SCP.i_reg_file.regs[1]);
            $display("t0 = 0x%08h", SCP.i_reg_file.regs[5]);
            $display("t1 = 0x%08h", SCP.i_reg_file.regs[6]);
            $display("t2 = 0x%08h", SCP.i_reg_file.regs[7]);
            $display("t3 = 0x%08h", SCP.i_reg_file.regs[28]);
            $display("t4 = 0x%08h", SCP.i_reg_file.regs[29]);

            if (SCP.wb_reg_write && SCP.wb_rd != 5'd0) begin
                $display("WB: t=%0t rd=x%0d <= %08h (mem=%b jump=%b) ALU=%08h MEM=%08h PC4=%08h",
                         $time, SCP.wb_rd, SCP.wb_write_data, SCP.wb_mem_to_reg, SCP.wb_jump,
                         SCP.wb_alu_result, SCP.wb_read_data, SCP.wb_pc_plus4);
            end
        end
    end
endmodule
