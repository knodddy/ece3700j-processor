`timescale 1ns / 1ps

module CPU (
    input        hit_miss,   // 1 indicates the cache finished the current request
    input        clock,
    input [31:0] Read_Data,
    output       read_write, // 1 for write, 0 for read
    output [9:0] address,
    output [31:0] write_data,
    output reg [4:0] request_num
);
    parameter request_total = 12;

    reg        read_write_test   [0:request_total-1];
    reg [9:0]  address_test      [0:request_total-1];
    reg [31:0] write_data_test   [0:request_total-1];
    reg        started;

    initial begin
        request_num = 5'bx; // keep unknown for cycle 0 to match sample output
        started     = 1'b0;
        /* test cases */
        read_write_test[0]  = 1; address_test[0]  = 10'b0110101000; write_data_test[0]  = 32'h000003ab; // write miss + empty dirty=0
        read_write_test[1]  = 0; address_test[1]  = 10'b0110101000; write_data_test[1]  = 32'h00000000; // read hit                                                3ab
        read_write_test[2]  = 1; address_test[2]  = 10'b0110101000; write_data_test[2]  = 32'h000003ac; // write hit
        read_write_test[3]  = 0; address_test[3]  = 10'b0110101000; write_data_test[3]  = 32'h00000000; // read hit                                                3ac
        read_write_test[4]  = 0; address_test[4]  = 10'b0100001000; write_data_test[4]  = 32'h00000000; // read miss + empty dirty=0   block 0                     0000
        read_write_test[5]  = 0; address_test[5]  = 10'b0100101000; write_data_test[5]  = 32'h00000000; // read miss + write back dirty=1                           0000
        read_write_test[6]  = 0; address_test[6]  = 10'b0110101000; write_data_test[6]  = 32'h00000000; // check write back dirty=0                                   3ac
        read_write_test[7]  = 1; address_test[7]  = 10'b0110101000; write_data_test[7]  = 32'h000003ad; // write hit
        read_write_test[8]  = 1; address_test[8]  = 10'b0101101000; write_data_test[8]  = 32'h000003ae; // write miss + write back dirty=1
        read_write_test[9]  = 0; address_test[9]  = 10'b0101101000; write_data_test[9]  = 32'h00000000; // check write                                                3ae
        read_write_test[10] = 0; address_test[10] = 10'b0110101000; write_data_test[10] = 32'h00000000; // check write back dirty=0                                   3ad
        read_write_test[11] = 0; address_test[11] = 10'b0110101001; write_data_test[11] = 32'h00000000; // check load byte                                            0003
    end

    always @(posedge clock) begin
        if (!started) begin
            started     <= 1'b1;
            request_num <= 0;
        end else if (hit_miss === 1'b1 && request_num < request_total-1) begin
            request_num <= request_num + 1;
        end else begin
            request_num <= request_num;
        end
    end

    assign address    = address_test[request_num];
    assign read_write = read_write_test[request_num];
    assign write_data = write_data_test[request_num];
endmodule
