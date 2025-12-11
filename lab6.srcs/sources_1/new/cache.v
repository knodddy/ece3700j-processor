module Cache(
    input         cpu_read_write,
    input  [9:0]  cpu_address,
    input  [31:0] cpu_write_data,
    output reg [31:0] cpu_read_data,
    output reg        cpu_done,
    output reg        cpu_hit,
    output reg        mem_read_write,
    output reg [9:0]  mem_address,
    output reg [31:0] mem_write_data,
    input      [31:0] mem_read_data,
    input             mem_done
);

    reg [4:0] tag_in;
    reg       set_index;
    reg [1:0] word_offset;
    reg [1:0] byte_offset;

    reg [31:0] data    [0:1][0:1][0:3];
    reg        valid   [0:1][0:1];
    reg        dirty   [0:1][0:1];
    reg [4:0]  tag_reg [0:1][0:1];
    reg        lru     [0:1];

    integer i, j, k;
    reg hit;
    reg victim_way;
    reg hit_way;

    function [31:0] format_read;
        input [31:0] word;
        input [1:0]  byte_sel;
        begin
            case (byte_sel)
                2'b00: format_read = word;
                2'b01: format_read = {24'b0, word[15:8]};
                2'b10: format_read = {24'b0, word[23:16]};
                2'b11: format_read = {24'b0, word[31:24]};
            endcase
        end
    endfunction

    function [31:0] merge_write;
        input [31:0] word;
        input [31:0] new_data;
        input [1:0]  byte_sel;
        input        is_byte;
        begin
            if (is_byte) begin
                case (byte_sel)
                    2'b00: merge_write = {word[31:8], new_data[7:0]};
                    2'b01: merge_write = {word[31:16], new_data[7:0], word[7:0]};
                    2'b10: merge_write = {word[31:24], new_data[7:0], word[15:0]};
                    2'b11: merge_write = {new_data[7:0], word[23:0]};
                endcase
            end else begin
                merge_write = new_data;
            end
        end
    endfunction

    initial begin
        for (i = 0; i < 2; i = i + 1)
            for (j = 0; j < 2; j = j + 1) begin
                valid[i][j]   = 1'b0;
                dirty[i][j]   = 1'b0;
                tag_reg[i][j] = 5'b0;
                for (k = 0; k < 4; k = k + 1)
                    data[i][j][k] = 32'b0;
            end
        lru[0]          = 1'b0;
        lru[1]          = 1'b0;
        cpu_read_data   = 32'b0;
        cpu_done        = 1'b0;
        cpu_hit         = 1'b0;
        mem_read_write  = 1'b1;
        mem_address     = 10'b0;
        mem_write_data  = 32'b0;
    end

    always @(cpu_read_write or cpu_address or cpu_write_data) begin
        cpu_done = 1'b0;
        cpu_hit  = 1'b0;

        tag_in      = cpu_address[9:5];
        set_index   = cpu_address[4];
        word_offset = cpu_address[3:2];
        byte_offset = cpu_address[1:0];

        if ((cpu_read_write === 1'b0 || cpu_read_write === 1'b1) && (^cpu_address !== 1'bx)) begin
            if (cpu_address == 10'b0) begin
                cpu_read_data = 32'bx;
                cpu_done      = 1'b1;
            end else begin
            hit        = 1'b0;
            hit_way    = 1'b0;
            victim_way = 1'b0;

            if (valid[set_index][0] && tag_reg[set_index][0] == tag_in) begin
                hit     = 1'b1;
                hit_way = 1'b0;
            end else if (valid[set_index][1] && tag_reg[set_index][1] == tag_in) begin
                hit     = 1'b1;
                hit_way = 1'b1;
            end

            if (hit) begin
                cpu_hit = 1'b1;
                if (cpu_read_write == 1'b0)
                    cpu_read_data = format_read(data[set_index][hit_way][word_offset], byte_offset);
                else begin
                    data[set_index][hit_way][word_offset] = merge_write(
                        data[set_index][hit_way][word_offset],
                        cpu_write_data,
                        byte_offset,
                        (byte_offset != 2'b00)
                    );
                    cpu_read_data            = 32'bx;
                    dirty[set_index][hit_way] = 1'b1;
                end
                lru[set_index] = ~hit_way;
                cpu_done       = 1'b1;
            end else begin
                if (!valid[set_index][0])
                    victim_way = 1'b0;
                else if (!valid[set_index][1])
                    victim_way = 1'b1;
                else
                    victim_way = lru[set_index];

                if (valid[set_index][victim_way] && dirty[set_index][victim_way]) begin
                    for (k = 0; k < 4; k = k + 1) begin
                        mem_read_write = 1'b1;
                        mem_address    = {tag_reg[set_index][victim_way], set_index, k[1:0], 2'b00};
                        mem_write_data = data[set_index][victim_way][k];
                        wait (mem_done === 1'b1);
                        wait (mem_done === 1'b0);
                    end
                end

                for (k = 0; k < 4; k = k + 1) begin
                    mem_read_write = 1'b0;
                    mem_address    = {tag_in, set_index, k[1:0], 2'b00};
                    wait (mem_done === 1'b1);
                    data[set_index][victim_way][k] = mem_read_data;
                    wait (mem_done === 1'b0);
                end

                tag_reg[set_index][victim_way] = tag_in;
                valid[set_index][victim_way]   = 1'b1;
                dirty[set_index][victim_way]   = 1'b0;

                if (cpu_read_write == 1'b0)
                    cpu_read_data = format_read(data[set_index][victim_way][word_offset], byte_offset);
                else begin
                    data[set_index][victim_way][word_offset] = merge_write(
                        data[set_index][victim_way][word_offset],
                        cpu_write_data,
                        byte_offset,
                        (byte_offset != 2'b00)
                    );
                    cpu_read_data              = 32'bx;
                    dirty[set_index][victim_way] = 1'b1;
                end
                lru[set_index] = ~victim_way;
                cpu_done       = 1'b1;
            end
            end
        end
    end

endmodule

module associative_back_cache (
    input         read_write_cache,
    input  [9:0]  address_cache,
    input  [31:0] write_data_cache,
    input  [31:0] read_data_mem,
    input         done,
    output [31:0] read_data_cache,
    output        hit_miss,
    output        read_write_mem,
    output [9:0]  address_mem,
    output [31:0] write_data_mem
);

    wire        cpu_done;
    wire        cpu_hit;
    wire [31:0] cpu_read_data;

    wire        mem_read_write_w;
    wire [9:0]  mem_address_w;
    wire [31:0] mem_write_data_w;

    Cache core (
        .cpu_read_write(read_write_cache),
        .cpu_address    (address_cache),
        .cpu_write_data (write_data_cache),
        .cpu_read_data  (cpu_read_data),
        .cpu_done       (cpu_done),
        .cpu_hit        (cpu_hit),
        .mem_read_write (mem_read_write_w),
        .mem_address    (mem_address_w),
        .mem_write_data (mem_write_data_w),
        .mem_read_data  (read_data_mem),
        .mem_done       (done)
    );

    assign read_data_cache = cpu_read_data;
    assign hit_miss        = cpu_done;
    assign read_write_mem  = mem_read_write_w;
    assign address_mem     = mem_address_w;
    assign write_data_mem  = mem_write_data_w;

    wire [4:0]  tag   [0:3];
    wire        valid [0:3];
    wire        dirty [0:3];
    wire [127:0] block[0:3];

    assign tag[0]   = core.tag_reg[0][0];
    assign tag[1]   = core.tag_reg[0][1];
    assign tag[2]   = core.tag_reg[1][0];
    assign tag[3]   = core.tag_reg[1][1];

    assign valid[0] = core.valid[0][0];
    assign valid[1] = core.valid[0][1];
    assign valid[2] = core.valid[1][0];
    assign valid[3] = core.valid[1][1];

    assign dirty[0] = core.dirty[0][0];
    assign dirty[1] = core.dirty[0][1];
    assign dirty[2] = core.dirty[1][0];
    assign dirty[3] = core.dirty[1][1];

    assign block[0] = { core.data[0][0][0],
                        core.data[0][0][1],
                        core.data[0][0][2],
                        core.data[0][0][3] };
    assign block[1] = { core.data[0][1][0],
                        core.data[0][1][1],
                        core.data[0][1][2],
                        core.data[0][1][3] };
    assign block[2] = { core.data[1][0][0],
                        core.data[1][0][1],
                        core.data[1][0][2],
                        core.data[1][0][3] };
    assign block[3] = { core.data[1][1][0],
                        core.data[1][1][1],
                        core.data[1][1][2],
                        core.data[1][1][3] };

endmodule
