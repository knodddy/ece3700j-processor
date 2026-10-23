`timescale 1ns / 1ps

module main_memory(
    input        read_write_mem,     // write <- 1, read <- 0
    input  [9:0] address_mem,        // byte address
    input  [31:0] write_data_mem,    // data from cache
    output reg [31:0] read_data_mem, // data to cache
    output reg       Done            // signals mem op complete
);
    parameter MEM_DELAY = 0; 

    reg [7:0] mem [0:1023];
    integer i;

    task set_word(input integer block, input integer word, input [31:0] value);
        integer addr;
        begin
            addr       = (block << 4) + (word << 2);
            mem[addr]     = value[7:0];
            mem[addr + 1] = value[15:8];
            mem[addr + 2] = value[23:16];
            mem[addr + 3] = value[31:24];
        end
    endtask

    initial begin
        for (i = 0; i < 1024; i = i + 1)
            mem[i] = 8'b0;
        Done          = 1'b0;
        read_data_mem = 32'b0;

        set_word(0, 0, 32'h0000000a);
        set_word(0, 1, 32'h0000000e);
        set_word(0, 2, 32'h0000000f);
        set_word(0, 3, 32'h55555555);

        set_word(4, 0, 32'hbbbbbbbb);
        set_word(4, 1, 32'haaaaaaaa);
        set_word(4, 2, 32'heeeeeeee);
        set_word(4, 3, 32'hcccccccc);

        set_word(16, 0, 32'h11111111);
        set_word(16, 1, 32'h22222222);
        set_word(16, 2, 32'h33333333);
        set_word(16, 3, 32'h44444444);

        set_word(20, 0, 32'h00000281);
        set_word(20, 1, 32'h00000285);
        set_word(20, 2, 32'h00000000);
        set_word(20, 3, 32'h0000028d);

        set_word(21, 0, 32'h00000281);
        set_word(21, 1, 32'h00000285);
        set_word(21, 2, 32'h00000000);
        set_word(21, 3, 32'h0000028d);

        set_word(25, 0, 32'h00000191);
        set_word(25, 1, 32'h00000195);
        set_word(25, 2, 32'h00000199);
        set_word(25, 3, 32'h00000191);

        set_word(29, 0, 32'h000001d1);
        set_word(29, 1, 32'h000001d5);
        set_word(29, 2, 32'h000001d9);
        set_word(29, 3, 32'h000001dd);

        set_word(33, 0, 32'h55555555);
        set_word(33, 1, 32'h66666666);
        set_word(33, 2, 32'h77777777);
        set_word(33, 3, 32'h88888888);

        set_word(40, 0, 32'h00000281);
        set_word(40, 1, 32'h00000000);
        set_word(40, 2, 32'h00000285);
        set_word(40, 3, 32'h0000028d);

        set_word(48, 0, 32'h55555555);
        set_word(48, 1, 32'h66666666);
        set_word(48, 2, 32'h77777777);
        set_word(48, 3, 32'h88888888);

        set_word(49, 0, 32'h55555555);
        set_word(49, 1, 32'h66666666);
        set_word(49, 2, 32'h77777777);
        set_word(49, 3, 32'h88888888);

        set_word(57, 0, 32'h00000391);
        set_word(57, 1, 32'h00000000);
        set_word(57, 2, 32'h00000395);
        set_word(57, 3, 32'h0000039d);

        set_word(61, 0, 32'h000003d1);
        set_word(61, 1, 32'h000003d5);
        set_word(61, 2, 32'h000003d9);
        set_word(61, 3, 32'h000003dd);
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
