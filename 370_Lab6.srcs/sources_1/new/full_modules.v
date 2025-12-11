`timescale 1ns / 1ps
// --------------------------------------------------------
// Designed Modules
// --------------------------------------------------------

module main_mem(
    input read_write_mem,          // 1 = Write, 0 = Read
    input [9:0] address_mem,       // Physical Address
    input [127:0] write_data_mem,  // 128-bit write data
    output reg [127:0] read_data_mem, // 128-bit read data
    output reg done
);
    // 64 blocks of 16 bytes.
    // Padded to 154 bits to match reference initialization syntax
    reg [153:0] mem [0:63];
    integer i;

    initial begin
        for (i=0; i<64; i=i+1) mem[i] = 154'b0;
        
        // Load Reference Data
        // Order: {padding(26), Word0(32), Word1(32), Word2(32), Word3(32)} 
        // Logic reads [127:0], which captures Word0..Word3.
        mem[0] = {26'b0, 32'hA, 32'hE, 32'hF, 32'h55555555};
        mem[4] = {26'b0, 32'hBBBBBBBB, 32'hAAAAAAAA, 32'hEEEEEEEE, 32'hCCCCCCCC};
        mem[16] = {26'b0, 32'h11111111, 32'h22222222, 32'h33333333, 32'h44444444};
        mem[20] = {26'b0, 32'h00000281, 32'h00000285, 32'h00000000, 32'h0000028d}; 
        mem[21] = {26'b0, 32'h281, 32'h285, 32'h0, 32'h28d};
        mem[25] = {26'b0, 32'h00000191, 32'h00000195, 32'h00000199, 32'h00000dac};
        mem[29] = {26'b0, 32'h000001d1, 32'h000001d5, 32'h000001d9, 32'h000001dd};
        mem[33] = {26'b0, 32'h55555555, 32'h66666666, 32'h77777777, 32'h88888888};
        mem[40] = {26'b0, 32'h00000281, 32'h00000000, 32'h00000285, 32'h0000028d};
        mem[48] = {26'b0, 32'h55555555, 32'h66666666, 32'h77777777, 32'h88888888};
        mem[49] = {26'b0, 32'h55555555, 32'h66666666, 32'h77777777, 32'h88888888};
        mem[57] = {26'b0, 32'h00000391, 32'h00000000, 32'h00000fac, 32'h0000039d}; 
        mem[61] = {26'b0, 32'h000003d1, 32'h000003d5, 32'h000003d9, 32'h000003dd};
    end

    // Read Logic
    always @(address_mem) begin
        read_data_mem = mem[address_mem[9:4]][127:0];
        done = 1;
    end
    
    // Write Logic
    always @(read_write_mem or address_mem or write_data_mem) begin
        if (read_write_mem) begin 
             mem[address_mem[9:4]] = {26'b0, write_data_mem};
             done = 1;
        end
    end
endmodule

module page_table(
    input dirty_write_back,
    input reference_write_back,
    input write_back,
    input [5:0] virtual_page_tag,
    output reg [31:0] physical_page_tag,
    output reg dirty_fetched,
    output reg reference_fetched,
    output reg page_fault,
    input [5:0] request_page_tag
);
    reg [31:0] pt_entry [0:63]; 
    integer i;

    initial begin
        for (i=0; i<64; i=i+1) pt_entry[i] = 32'b0;
        
        // Format: {Valid (1), 29'b0, PPN (2)}
        pt_entry[0] = {1'b1, 29'b0, 2'd1};
        pt_entry[1] = {1'b1, 29'b0, 2'd3};
        pt_entry[2] = {1'b0, 29'b0, 2'd2};
        pt_entry[3] = {1'b1, 29'b0, 2'd3};
        pt_entry[4] = {1'b1, 29'b0, 2'd2};
        pt_entry[7] = {1'b1, 29'b0, 2'd1}; 
        pt_entry[8] = {1'b1, 29'b0, 2'd1};
        pt_entry[10] = {1'b1, 29'b0, 2'd1}; 
    end

    always @(request_page_tag) begin
        if (pt_entry[request_page_tag][31]) begin
            page_fault = 0;
            physical_page_tag = pt_entry[request_page_tag];
            dirty_fetched = 0; 
            reference_fetched = 0;
        end else begin
            page_fault = 1;
            physical_page_tag = 32'b0;
            dirty_fetched = 0;
            reference_fetched = 0;
        end
    end

    always @(write_back or virtual_page_tag) begin
        // Placeholder for write-back logic (optional for this lab)
    end
endmodule

module translation_look_aside_buffer(
    input [13:0] virtual_address,
    input input_read_write,
    input [31:0] physical_page_tag, // Input from PT
    input dirty_fetched,
    input reference_fetched,
    output reg [9:0] physical_address,
    output reg output_read_write,
    output reg dirty_write_back,
    output reg reference_write_back,
    output reg write_back,
    output reg [5:0] virtual_page_tag,
    input page_fault,
    output reg [5:0] request_page_tag
);
    reg [5:0] tag [0:3];
    reg [1:0] block [0:3];
    reg valid [0:3];
    reg dirty [0:3];
    reg reference [0:3];
    reg [1:0] lru_age [0:3]; 
    
    integer i;
    initial begin
        for (i=0; i<4; i=i+1) begin
            tag[i] = 0; block[i] = 0; valid[i] = 0; dirty[i] = 0; reference[i] = 0; 
            // Inverted Init: Block 00 (index 0) gets age 3 (LRU), so it is replaced first.
            lru_age[i] = 3 - i; 
        end
    end

    reg [5:0] vpn;
    reg hit;
    reg [1:0] hit_index;
    reg [1:0] victim_index;

    // Trigger on any input change (Combinational Logic)
    always @(*) begin
        vpn = virtual_address[13:8];
        hit = 0;
        hit_index = 0;
        victim_index = 0;
        
        for (i=0; i<4; i=i+1) begin
            if (valid[i] && tag[i] == vpn) begin
                hit = 1;
                hit_index = i[1:0];
            end
        end

        // Defaults
        write_back = 0;
        virtual_page_tag = 0;
        dirty_write_back = 0;
        reference_write_back = 0;
        request_page_tag = vpn; // Drive PT
        output_read_write = input_read_write;
        physical_address = 10'bx;

        // Allow page table outputs to settle for this VPN before populating TLB
        #1;

        if (hit) begin
            physical_address = {block[hit_index], virtual_address[7:0]};
            
            // Simplified Behavioral LRU Update
            if (lru_age[hit_index] != 0) begin
                for (i=0; i<4; i=i+1) begin
                    if (lru_age[i] < lru_age[hit_index]) lru_age[i] = lru_age[i] + 1;
                end
                lru_age[hit_index] = 0;
            end
            
            reference[hit_index] = 1;
            if (input_read_write) dirty[hit_index] = 1;
            
        end else begin
            // Miss: Select Victim (Age 3)
            for (i=0; i<4; i=i+1) begin
                if (lru_age[i] == 3) victim_index = i[1:0];
            end
            
            // Write Back Check
            if (valid[victim_index] && dirty[victim_index]) begin
                write_back = 1;
                virtual_page_tag = tag[victim_index];
                dirty_write_back = dirty[victim_index];
                reference_write_back = reference[victim_index];
            end
            
            if (!page_fault && physical_page_tag[31]) begin
                // Update Entry
                tag[victim_index] = vpn;
                block[victim_index] = physical_page_tag[1:0];
                valid[victim_index] = 1;
                dirty[victim_index] = (input_read_write) ? 1 : 0;
                reference[victim_index] = 1;
                
                // Update LRU
                for (i=0; i<4; i=i+1) begin
                    if (lru_age[i] < lru_age[victim_index]) lru_age[i] = lru_age[i] + 1;
                end
                lru_age[victim_index] = 0;
                
                physical_address = {block[victim_index], virtual_address[7:0]};
            end else begin
                physical_address = 10'bx;
            end
        end
    end
endmodule

module associative_back_cache(
    input read_write_cache, 
    input [9:0] address_cache,
    input [31:0] write_data_cache,
    input [127:0] read_data_mem, // 128-bit
    input done,
    output reg [31:0] read_data_cache,
    output reg hit_miss, 
    output reg read_write_mem, 
    output reg [9:0] address_mem,
    output reg [127:0] write_data_mem // 128-bit
);
    reg [127:0] block [0:3]; 
    reg [4:0] tag [0:3];
    reg valid [0:3];
    reg dirty [0:3];
    reg lru [0:1]; // 0: Way0 MRU, 1: Way1 MRU
                   
    integer i;
    initial begin
        for (i=0; i<4; i=i+1) begin
            block[i] = 0; tag[i] = 0; valid[i] = 0; dirty[i] = 0;
        end
        lru[0] = 1; // Way 1 MRU, so Way 0 is LRU (first victim)
        lru[1] = 1;
    end

    // Helper routines for word/byte level access
    function [31:0] select_word;
        input [127:0] blk;
        input [1:0] word_index;
        begin
            case(word_index)
                2'b00: select_word = blk[127:96];
                2'b01: select_word = blk[95:64];
                2'b10: select_word = blk[63:32];
                default: select_word = blk[31:0];
            endcase
        end
    endfunction

    function [127:0] place_word;
        input [127:0] blk;
        input [1:0] word_index;
        input [31:0] new_word;
        begin
            case(word_index)
                2'b00: place_word = {new_word, blk[95:0]};
                2'b01: place_word = {blk[127:96], new_word, blk[63:0]};
                2'b10: place_word = {blk[127:64], new_word, blk[31:0]};
                default: place_word = {blk[127:32], new_word};
            endcase
        end
    endfunction

    function [31:0] merge_write;
        input [31:0] original;
        input [31:0] new_data;
        input [1:0] byte_sel;
        input word_aligned;
        reg [31:0] mask;
        begin
            if (word_aligned) merge_write = new_data;
            else begin
                mask = ~(32'hFF << (byte_sel * 8));
                merge_write = (original & mask) | ((new_data & 32'hFF) << (byte_sel * 8));
            end
        end
    endfunction

    function [31:0] extract_read;
        input [31:0] word_value;
        input [1:0] byte_sel;
        input word_aligned;
        begin
            if (word_aligned) extract_read = word_value;
            else extract_read = {24'b0, (word_value >> (byte_sel * 8)) & 8'hFF};
        end
    endfunction

    wire [4:0] current_tag;
    wire set_index;
    wire [3:0] offset;
    
    assign current_tag = address_cache[9:5];
    assign set_index = address_cache[4]; 
    assign offset = address_cache[3:0];
    
    reg way0_hit, way1_hit;
    reg [1:0] hit_way;
    reg [1:0] victim_way;
    reg [31:0] selected_word;
    reg [31:0] updated_word;
    reg word_aligned;
    wire [1:0] base; 
    assign base = (set_index) ? 2 : 0;

    always @(*) begin
        // Defaults
        way0_hit = 0;
        way1_hit = 0;
        hit_miss = 0;
        hit_way = 0;
        victim_way = 0;
        word_aligned = 0;
        selected_word = 0;
        updated_word = 0;
        read_write_mem = 0; 
        address_mem = 0;
        write_data_mem = 0;
        read_data_cache = 32'bx;

        if ((^address_cache === 1'bX) || (^read_write_cache === 1'bX)) begin
            // Input not stable yet; hold defaults
            hit_miss = 0;
        end else begin
            // Check Hit
            way0_hit = (valid[base] && tag[base] == current_tag);
            way1_hit = (valid[base+1] && tag[base+1] == current_tag);
            hit_miss = (way0_hit || way1_hit);

            if (hit_miss) begin
                // HIT
                hit_way = (way0_hit) ? base : base+1;
                word_aligned = (offset[1:0] == 2'b00);
                selected_word = select_word(block[hit_way], offset[3:2]);
                
                if (read_write_cache) begin // Write
                    updated_word = merge_write(selected_word, write_data_cache, offset[1:0], word_aligned);
                    block[hit_way] = place_word(block[hit_way], offset[3:2], updated_word);
                    dirty[hit_way] = 1;
                end else begin // Read
                    read_data_cache = extract_read(selected_word, offset[1:0], word_aligned);
                end
                lru[set_index] = (way0_hit) ? 0 : 1; 

            end else begin
            // MISS
            victim_way = base;
            if (lru[set_index] == 0) victim_way = base+1;
            
            // Write Back
            if (valid[victim_way] && dirty[victim_way]) begin
                read_write_mem = 1; 
                address_mem = {tag[victim_way], set_index, 4'b0000};
                write_data_mem = block[victim_way];
                #1; // allow write-back to commit before issuing read
            end
                
                // Read New Block
                read_write_mem = 0; 
                address_mem = {current_tag, set_index, 4'b0000};
                
                // Simulation Delay: Ensures main_mem responds before sampling
                #1;
                
                if (done) begin 
                    block[victim_way] = read_data_mem;
                    tag[victim_way] = current_tag;
                    valid[victim_way] = 1;
                    dirty[victim_way] = 0;
                    word_aligned = (offset[1:0] == 2'b00);
                    selected_word = select_word(block[victim_way], offset[3:2]);
                    
                    // Retry Request
                    if (read_write_cache) begin 
                        updated_word = merge_write(selected_word, write_data_cache, offset[1:0], word_aligned);
                        block[victim_way] = place_word(block[victim_way], offset[3:2], updated_word);
                        dirty[victim_way] = 1;
                    end else begin 
                        read_data_cache = extract_read(selected_word, offset[1:0], word_aligned);
                    end
                    
                    lru[set_index] = (victim_way == base) ? 0 : 1;
                    hit_miss = 1; 
                end
            end
        end
    end
endmodule
