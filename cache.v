`timescale 1ns / 1ps

// Port order/widths match the provided Lab5_cache_test.v (positional).
module Cache(
    input         cpu_read_write,
    input  [9:0]  cpu_address,
    input  [31:0] cpu_write_data,
    input         mem_done,         // Done from main memory
    input  [127:0] mem_read_data,   // block from main memory
    output reg [31:0] cpu_read_data,
    output reg        cpu_hit,      // used as "done" by CPU/testbench
    output reg        mem_read_write,
    output reg [9:0]  mem_address,
    output reg [127:0] mem_write_data,
    output reg [9:0]  addr_used_main_memory
);
    parameter MISS_DELAY = 12; // ns to keep miss visible for one cycle

    // different part of address
    reg [3:0] tag;
    reg [1:0] blk_index;
    reg [1:0] word_offset;
    reg [1:0] byte_offset;

    // cache: 4 rows*4 words
    reg [31:0] data    [0:3][0:3];
    reg        valid   [0:3];
    reg        dirty   [0:3];
    reg [3:0]  tag_reg [0:3];

    integer k;
    reg [3:0] victim_tag;
    reg [31:0] fetched_word;

    integer i, j;

    initial begin
        for (i = 0; i < 4; i = i + 1) begin
            valid[i]   = 1'b0;
            dirty[i]   = 1'b0;
            tag_reg[i] = 4'b0;
            for (j = 0; j < 4; j = j + 1)
                data[i][j] = 32'b0;
        end
        cpu_read_data        = 32'b0;
        fetched_word         = 32'b0;
        cpu_hit              = 1'bx;
        mem_read_write       = 1'b0;
        mem_address          = 10'b0;
        mem_write_data       = 128'b0;
        addr_used_main_memory= 10'b0;
    end

    // Return either a full word or a single byte depending on byte offset.
    function [31:0] format_read_data;
        input [31:0] word;
        input [1:0]  byte_sel;
        begin
            case (byte_sel)
                2'b00: format_read_data = word;
                2'b01: format_read_data = {24'b0, word[15:8]};
                2'b10: format_read_data = {24'b0, word[23:16]};
                2'b11: format_read_data = {24'b0, word[31:24]};
            endcase
        end
    endfunction

    always @(cpu_read_write or cpu_address or cpu_write_data) begin
        cpu_hit  = 1'b0;

        tag         = cpu_address[9:6];
        blk_index   = cpu_address[5:4];
        word_offset = cpu_address[3:2];
        byte_offset = cpu_address[1:0];

        // only when read_write is 1 or 0
        if (cpu_read_write === 1'b0 || cpu_read_write === 1'b1) begin

            // hit
            if (valid[blk_index] && tag_reg[blk_index] == tag) begin
                cpu_hit = 1'b1;
                if (cpu_read_write == 1'b0) begin
                    // want to read, and hit
                    cpu_read_data = format_read_data(data[blk_index][word_offset], byte_offset);
                end else begin
                    // want to write, and his
                    data[blk_index][word_offset] = cpu_write_data;
                    dirty[blk_index]             = 1'b1;
                end

            //miss
            end else begin
                cpu_hit  = 1'b0;

                //if the block is dirty, we hace to write back to the main memory first
                if (valid[blk_index] && dirty[blk_index]) begin
                    victim_tag    = tag_reg[blk_index];
                    mem_read_write = 1'b1; // write back entire block
                    mem_address    = {victim_tag, blk_index, 4'b0000};
                    mem_write_data = {
                        data[blk_index][3],
                        data[blk_index][2],
                        data[blk_index][1],
                        data[blk_index][0]
                    };
                    addr_used_main_memory = mem_address;
                    wait (mem_done === 1'b1);
                    wait (mem_done === 1'b0);
                end

                // read the requested block from main mem
                mem_read_write = 1'b0;  // read_write=0, read
                mem_address    = {tag, blk_index, 4'b0000};
                addr_used_main_memory = mem_address;

                wait (mem_done === 1'b1);
                {data[blk_index][3], data[blk_index][2], data[blk_index][1], data[blk_index][0]} = mem_read_data;
                fetched_word = data[blk_index][word_offset];
                wait (mem_done === 1'b0);

                tag_reg[blk_index] = tag;
                valid[blk_index]   = 1'b1;
                dirty[blk_index]   = 1'b0;

                //give back to cpu
                if (cpu_read_write == 1'b1) begin
                    data[blk_index][word_offset] = cpu_write_data;
                    dirty[blk_index]             = 1'b1;
                end
                #(MISS_DELAY);
                if (cpu_read_write == 1'b0)
                    cpu_read_data = format_read_data(fetched_word, byte_offset);
                // For a miss we still raise cpu_hit once the transaction is
                // complete so the CPU can advance its request sequence.
                cpu_hit  = 1'b1;
            end
        end
    end

endmodule
