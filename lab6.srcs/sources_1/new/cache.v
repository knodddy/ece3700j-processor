module Cache(
    // CPU side
    input         cpu_read_write,
    input  [9:0]  cpu_address,
    input  [31:0] cpu_write_data,
    output reg [31:0] cpu_read_data,
    output reg        cpu_done,
    output reg        cpu_hit,

    // Memory side
    output reg        mem_read_write,
    output reg [9:0]  mem_address,
    output reg [31:0] mem_write_data,
    input      [31:0] mem_read_data,
    input             mem_done
);

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

    integer i, j;

    initial begin
        for (i = 0; i < 4; i = i + 1) begin
            valid[i]   = 1'b0;
            dirty[i]   = 1'b0;
            tag_reg[i] = 4'b0;
            for (j = 0; j < 4; j = j + 1)
                data[i][j] = 32'b0;
        end
        cpu_done       = 1'b0;
        cpu_hit        = 1'b0;
        mem_read_write = 1'b0;
        mem_address    = 10'b0;
        mem_write_data = 32'b0;
    end

    always @(cpu_read_write or cpu_address or cpu_write_data) begin
        cpu_done = 1'b0;
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
                    cpu_read_data = data[blk_index][word_offset];
                end else begin
                    // want to write, and his
                    data[blk_index][word_offset] = cpu_write_data;
                    dirty[blk_index]             = 1'b1;
                end
                cpu_done = 1'b1;

            //miss
            end else begin
                cpu_hit  = 1'b0;
                cpu_done = 1'b0;

                //if the block is dirty, we hace to write back to the main memory first
                if (valid[blk_index] && dirty[blk_index]) begin
                    victim_tag = tag_reg[blk_index];
                    for (k = 0; k < 4; k = k + 1) begin
                        mem_read_write = 1'b1; //transfer to the main-mem, tell it to write in
                        mem_address    = {victim_tag, blk_index, k[1:0], 2'b00};
                        mem_write_data = data[blk_index][k];

                        // wait for main mem to finish writing
                        wait (mem_done === 1'b1);
                        wait (mem_done === 1'b0);
                    end
                    dirty[blk_index] = 1'b0;
                    valid[blk_index] = 1'b0;
                end

                // read the new block from main mem
                for (k = 0; k < 4; k = k + 1) begin
                    mem_read_write = 1'b0;  // read_write=0, read
                    mem_address    = {tag, blk_index, k[1:0], 2'b00};

                    wait (mem_done === 1'b1);
                    data[blk_index][k] = mem_read_data;
                    wait (mem_done === 1'b0);
                end
                tag_reg[blk_index] = tag;
                valid[blk_index]   = 1'b1;
                dirty[blk_index]   = 1'b0;

                //give back to cpu
                if (cpu_read_write == 1'b0) begin
                    cpu_read_data = data[blk_index][word_offset];
                end else begin
                    data[blk_index][word_offset] = cpu_write_data;
                    dirty[blk_index]             = 1'b1;
                end
                cpu_done = 1'b1;
            end
        end
    end

endmodule

module associative_back_cache (
    // From TLB / “CPU”
    input         read_write_cache,     // 1 = write, 0 = read
    input  [9:0]  address_cache,        // physical address
    input  [31:0] write_data_cache,     // data from CPU/TLB

    // From main memory
    input  [31:0] read_data_mem,
    input         done,                 // mem_done from main_memory

    // Back to CPU
    output [31:0] read_data_cache,
    output        hit_miss,             // “request finished”

    // To main memory
    output        read_write_mem,
    output [9:0]  address_mem,
    output [31:0] write_data_mem
);

    // --- wires between wrapper and core Cache ---
    wire        cpu_done;
    wire        cpu_hit;
    wire [31:0] cpu_read_data;

    wire        mem_read_write_w;
    wire [9:0]  mem_address_w;
    wire [31:0] mem_write_data_w;

    // connect core Cache
    Cache core (
        // CPU side
        .cpu_read_write(read_write_cache),
        .cpu_address    (address_cache),
        .cpu_write_data (write_data_cache),
        .cpu_read_data  (cpu_read_data),
        .cpu_done       (cpu_done),
        .cpu_hit        (cpu_hit),

        // Memory side
        .mem_read_write (mem_read_write_w),
        .mem_address    (mem_address_w),
        .mem_write_data (mem_write_data_w),
        .mem_read_data  (read_data_mem),
        .mem_done       (done)
    );

    // outputs to vm_test
    assign read_data_cache = cpu_read_data;
    assign hit_miss        = cpu_done;        // “op completed”
    assign read_write_mem  = mem_read_write_w;
    assign address_mem     = mem_address_w;
    assign write_data_mem  = mem_write_data_w;
    // debug views for vm_test: cache.tag[i], cache.valid[i], etc.
    // 4 blocks, each block = 4 words = 128 bits

    wire [3:0]  tag   [0:3];
    wire        valid [0:3];
    wire        dirty [0:3];
    wire [127:0] block[0:3];

    genvar gi;
    generate
        for (gi = 0; gi < 4; gi = gi + 1) begin : mirror
            assign tag[gi]   = core.tag_reg[gi];
            assign valid[gi] = core.valid[gi];
            assign dirty[gi] = core.dirty[gi];

            // pack 4×32-bit words into one 128-bit block
            assign block[gi] = { core.data[gi][3],
                                 core.data[gi][2],
                                 core.data[gi][1],
                                 core.data[gi][0] };
        end
    endgenerate

endmodule