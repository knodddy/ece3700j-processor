`timescale 1ns / 1ps

module main_memory(
    input        read_write_mem,     // write <- 1, read <- 0
    input  [9:0] address_mem,        // byte address
    input  [31:0] write_data_mem,    // data from cache
    output reg [31:0] read_data_mem, // data to cache
    output reg       Done            // signals mem op complete
);
    parameter MEM_DELAY = 2; 

    reg [7:0] mem [0:1023];
    integer i;

    initial begin
        // initialization: random content
        for (i = 0; i < 1024; i = i + 1)
            mem[i] = $random;
        Done          = 1'b0;
        read_data_mem = 32'b0;
    end

    always @(read_write_mem or address_mem or write_data_mem) begin
        Done = 1'b0;
        if (read_write_mem === 1'b0) begin
            // READ
            #MEM_DELAY;
            read_word(address_mem, read_data_mem);
            Done = 1'b1;
            #1;
            Done = 1'b0;
        end else if (read_write_mem === 1'b1) begin
            // WRITE
            #MEM_DELAY;
            write_word(address_mem, write_data_mem);
            Done = 1'b1;
            #1;
            Done = 1'b0;
        end
    end

    task read_word(input [9:0] addr, output [31:0] data);
        reg [9:0] base;
        begin
            base = {addr[9:2], 2'b00}; 
            data = { mem[base+3], mem[base+2], mem[base+1], mem[base] };
        end
    endtask

    task write_word(input [9:0] addr, input [31:0] data);
        reg [9:0] base;
        begin
            base        = {addr[9:2], 2'b00};
            mem[base]   = data[7:0];
            mem[base+1] = data[15:8];
            mem[base+2] = data[23:16];
            mem[base+3] = data[31:24];
        end
    endtask

endmodule
