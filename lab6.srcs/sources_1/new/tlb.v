`timescale 1ns / 1ps

module translation_look_aside_buffer (
    input  [13:0] virtual_address,     // VA
    input         input_read_write,    // 1 = write, 0 = read

    // from page table
    input  [31:0] physical_page_tag,   // contains at least valid + PPN
    input         dirty_fetched,
    input         reference_fetched,
    input         page_fault,          // from page table

    // to cache
    output reg [9:0] physical_address, // PA
    output reg       output_read_write,

    // write-back to page table on eviction
    output reg       dirty_write_back,
    output reg       reference_write_back,
    output reg       write_back,
    output reg [5:0] virtual_page_tag, // VPN of entry being written back

    // request to page table
    output reg [5:0] request_page_tag  // VPN whose PTE we want from PT
);

    // 4-entry fully associative TLB
    // tag    : VPN (virtual page number)
    // block  : PPN (physical page number)
    reg [5:0] tag      [0:3];
    reg       valid    [0:3];
    reg       dirty    [0:3];
    reg       reference[0:3];
    reg [1:0] block    [0:3];

    // LRU age: 0 = most recently used, 3 = least recently used
    reg [1:0] age      [0:3];

    integer i;
    integer hit_idx;
    integer victim_idx;
    integer max_age;
    reg     hit;

    // VA breakdown: VPN + page offset
    wire [5:0] vpn    = virtual_address[13:8];
    wire [7:0] offset = virtual_address[7:0];

    // PTE breakdown from physical_page_tag (you defined it as {valid,29'b0,PPN})
    wire       pt_valid = physical_page_tag[31];
    wire [1:0] pt_ppn   = physical_page_tag[1:0];

    initial begin
        for (i = 0; i < 4; i = i + 1) begin
            tag[i]       = 6'b0;
            valid[i]     = 1'b0;
            dirty[i]     = 1'b0;
            reference[i] = 1'b0;
            block[i]     = 2'b0;
            age[i]       = i[1:0];    // different initial ages
        end

        physical_address      = 10'b0;
        output_read_write     = 1'b0;
        dirty_write_back      = 1'b0;
        reference_write_back  = 1'b0;
        write_back            = 1'b0;
        virtual_page_tag      = 6'b0;
        request_page_tag      = 6'b0;
    end

    always @(*) begin
        // default outputs
        physical_address      = 10'b0;
        output_read_write     = input_read_write;
        dirty_write_back      = 1'b0;
        reference_write_back  = 1'b0;
        write_back            = 1'b0;
        virtual_page_tag      = 6'b0;
        request_page_tag      = vpn;      // ask PT for this VPN by default

        hit     = 1'b0;
        hit_idx = 0;

        // if page fault is signaled by PT, do nothing to TLB state
        if (page_fault) begin
            // physical_address can stay 0; state unchanged
        end
        else begin
            // 1) search TLB for hit
            for (i = 0; i < 4; i = i + 1) begin
                if (valid[i] && tag[i] == vpn) begin
                    hit     = 1'b1;
                    hit_idx = i;
                end
            end

            if (hit) begin
                // TLB hit: use cached PPN
                physical_address = {block[hit_idx], offset};

                // write request marks this page dirty in TLB
                if (input_read_write)
                    dirty[hit_idx] = 1'b1;

                // update reference bit for debug printing
                reference[hit_idx] = 1'b1;

                // LRU age update
                for (i = 0; i < 4; i = i + 1) begin
                    if (i != hit_idx && valid[i]) begin
                        if (age[i] < 2'd3)
                            age[i] = age[i] + 1'b1;
                    end
                end
                age[hit_idx] = 2'd0;
            end
            else begin
                // 2) TLB miss: use PT mapping if valid
                if (!pt_valid) begin
                    // PT says invalid; treat as page fault-like, do not change TLB
                    // physical_address remains 0
                end
                else begin
                    // choose victim: first invalid, otherwise oldest age
                    victim_idx = -1;
                    for (i = 0; i < 4; i = i + 1) begin
                        if (!valid[i] && victim_idx == -1)
                            victim_idx = i;
                    end

                    if (victim_idx == -1) begin
                        max_age    = -1;
                        victim_idx = 0;
                        for (i = 0; i < 4; i = i + 1) begin
                            if (age[i] > max_age) begin
                                max_age    = age[i];
                                victim_idx = i;
                            end
                        end

                        // existing valid entry being evicted: write back its metadata to PT
                        if (valid[victim_idx]) begin
                            write_back           = 1'b1;
                            virtual_page_tag     = tag[victim_idx];
                            dirty_write_back     = dirty[victim_idx];
                            reference_write_back = reference[victim_idx];
                        end
                    end

                    // fill new TLB entry from PT
                    tag[victim_idx]       = vpn;
                    valid[victim_idx]     = 1'b1;
                    block[victim_idx]     = pt_ppn;

                    // reference bit: this access counts as a reference
                    reference[victim_idx] = 1'b1;

                    // combine PT's dirty info with current access
                    dirty[victim_idx]     = dirty_fetched | (input_read_write ? 1'b1 : 1'b0);

                    // LRU age update
                    for (i = 0; i < 4; i = i + 1) begin
                        if (i != victim_idx && valid[i]) begin
                            if (age[i] < 2'd3)
                                age[i] = age[i] + 1'b1;
                        end
                    end
                    age[victim_idx] = 2'd0;

                    // resulting physical address for this access
                    physical_address = {pt_ppn, offset};
                end
            end
        end
    end

endmodule
