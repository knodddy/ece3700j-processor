`timescale 1ns / 1ps

module main_mem (
    input          read_write_mem, // 0 = Read, 1 = Write
    input  [9:0]   address_mem,
    input  [31:0]  write_data_mem,
    output reg [31:0] read_data_mem,
    output reg     done
);
    reg [7:0] ram [0:1023];
    integer i;

    task set_block;
        input [9:0] blk_idx;
        input [31:0] w0;
        input [31:0] w1;
        input [31:0] w2;
        input [31:0] w3;
        reg [9:0] base;
        begin
            base = blk_idx * 16;
            ram[base+0] = w0[7:0]; ram[base+1] = w0[15:8]; ram[base+2] = w0[23:16]; ram[base+3] = w0[31:24];
            ram[base+4] = w1[7:0]; ram[base+5] = w1[15:8]; ram[base+6] = w1[23:16]; ram[base+7] = w1[31:24];
            ram[base+8] = w2[7:0]; ram[base+9] = w2[15:8]; ram[base+10]= w2[23:16]; ram[base+11]= w2[31:24];
            ram[base+12]= w3[7:0]; ram[base+13]= w3[15:8]; ram[base+14]= w3[23:16]; ram[base+15]= w3[31:24];
        end
    endtask

    initial begin
        done = 0;
        for (i = 0; i < 1024; i = i + 1) ram[i] = 0;

        set_block(0,  32'h0000000A, 32'h0000000E, 32'h0000000F, 32'h55555555);
        set_block(4,  32'hBBBBBBBB, 32'hAAAAAAAA, 32'hEEEEEEEE, 32'hCCCCCCCC);
        set_block(16, 32'h11111111, 32'h22222222, 32'h33333333, 32'h44444444);
        set_block(20, 32'h00000281, 32'h00000285, 32'h00000000, 32'h0000028d);
        set_block(21, 32'h00000281, 32'h00000285, 32'h00000000, 32'h0000028d);
        set_block(25, 32'h00000191, 32'h00000195, 32'h00000199, 32'h00000191);
        set_block(29, 32'h000001d1, 32'h000001d5, 32'h000001d9, 32'h000001dd);
        set_block(33, 32'h55555555, 32'h66666666, 32'h77777777, 32'h88888888);
        set_block(40, 32'h00000281, 32'h00000000, 32'h00000285, 32'h0000028d);
        set_block(48, 32'h55555555, 32'h66666666, 32'h77777777, 32'h88888888);
        set_block(49, 32'h55555555, 32'h66666666, 32'h77777777, 32'h88888888);
        set_block(57, 32'h00000391, 32'h00000000, 32'h00000395, 32'h0000039d);
        set_block(61, 32'h000003d1, 32'h000003d5, 32'h000003d9, 32'h000003dd);
    end

    always @(read_write_mem or address_mem or write_data_mem) begin
        done = 0;
        if (read_write_mem) begin
            ram[address_mem]     = write_data_mem[7:0];
            ram[address_mem + 1] = write_data_mem[15:8];
            ram[address_mem + 2] = write_data_mem[23:16];
            ram[address_mem + 3] = write_data_mem[31:24];
        end else begin
            read_data_mem = {ram[address_mem + 3], ram[address_mem + 2], ram[address_mem + 1], ram[address_mem]};
        end
        done = 1;
    end
endmodule

// -------------------------------------------------------------------------
// Module: Page Table
// -------------------------------------------------------------------------
module page_table (
    input          dirty_write_back,
    input          reference_write_back,
    input          write_back,
    input  [5:0]   virtual_page_tag,
    output reg [1:0] physical_page_tag,
    output reg     dirty_fetched,
    output reg     reference_fetched,
    output reg     page_fault,
    input  [5:0]   request_page_tag
);
    reg [1:0] ppn [0:63];
    reg       valid [0:63];
    reg       dirty [0:63];
    reg       ref [0:63];
    integer i;

    initial begin
        for (i = 0; i < 64; i = i + 1) begin
            valid[i] = 0; dirty[i] = 0; ref[i] = 0; ppn[i] = 0;
        end
        valid[0] = 1; ppn[0] = 1; 
        valid[1] = 1; ppn[1] = 3; 
        valid[2] = 0; ppn[2] = 2; 
        valid[3] = 1; ppn[3] = 3;
        valid[4] = 1; ppn[4] = 2; 
        valid[7] = 1; ppn[7] = 1;
        valid[8] = 1; ppn[8] = 1;
        valid[10] = 1; ppn[10] = 1;
    end

    always @(write_back or virtual_page_tag or dirty_write_back or reference_write_back) begin
        if (write_back) begin
            dirty[virtual_page_tag] = dirty_write_back;
            ref[virtual_page_tag]   = reference_write_back;
        end
    end

    always @(request_page_tag) begin
        physical_page_tag = ppn[request_page_tag];
        dirty_fetched     = dirty[request_page_tag];
        reference_fetched = ref[request_page_tag];
        page_fault        = ~valid[request_page_tag];
    end
endmodule

// -------------------------------------------------------------------------
// Module: Translation Lookaside Buffer (TLB)
// -------------------------------------------------------------------------
module translation_look_aside_buffer (
    input  [13:0]  virtual_address,
    input          input_read_write,
    input  [1:0]   physical_page_tag,
    input          dirty_fetched,
    input          reference_fetched,
    output reg [9:0]  physical_address,
    output         output_read_write,
    output reg     dirty_write_back,
    output reg     reference_write_back,
    output reg     write_back,
    output reg [5:0]  virtual_page_tag,
    input          page_fault,
    output reg [5:0]  request_page_tag
);
    reg [5:0] tag [0:3];     
    reg [1:0] block [0:3];   
    reg       valid [0:3];
    reg       dirty [0:3];
    reg       reference [0:3];
    reg [1:0] lru_age [0:3];
    
    integer i;
    reg hit;
    reg [1:0] hit_idx;
    reg [1:0] victim_idx;
    reg [5:0] vpn;
    reg [1:0] old_age; 

    assign output_read_write = input_read_write;

    initial begin
        for (i = 0; i < 4; i = i + 1) begin
            valid[i] = 0; tag[i] = 0; block[i] = 0; 
            dirty[i] = 0; reference[i] = 0; 
            lru_age[i] = i; 
        end
        write_back = 0;
        request_page_tag = 0;
        dirty_write_back = 0;
        reference_write_back = 0;
        virtual_page_tag = 0;
    end

    always @(virtual_address or input_read_write) begin
        if (^virtual_address === 1'bx) begin
             // Do nothing
        end else begin
            vpn = virtual_address[13:8];
            request_page_tag = vpn; 
            
            hit = 0;
            hit_idx = 0;
            write_back = 0;
            
            // Output X on fault so cache returns X data
            physical_address = 10'bx; 
            
            for (i = 0; i < 4; i = i + 1) begin
                if (valid[i] && tag[i] == vpn) begin
                    hit = 1;
                    hit_idx = i;
                end
            end

            if (!hit) begin
                victim_idx = 0;
                for (i = 0; i < 4; i = i + 1) begin
                    if (lru_age[i] == 0) victim_idx = i;
                end
                
                if (valid[victim_idx] && dirty[victim_idx]) begin
                    virtual_page_tag = tag[victim_idx];
                    dirty_write_back = dirty[victim_idx];
                    reference_write_back = reference[victim_idx];
                    write_back = 1;
                end
                
                #1; 
                
                if (!page_fault) begin
                    tag[victim_idx]       = vpn;
                    block[victim_idx]     = physical_page_tag;
                    valid[victim_idx]     = 1;
                    // Start clean (0) on load. Only becomes dirty if this op is a Write.
                    dirty[victim_idx]     = 0; 
                    reference[victim_idx] = reference_fetched;
                    
                    for (i = 0; i < 4; i = i + 1) begin
                       if (lru_age[i] > 0) lru_age[i] = lru_age[i] - 1;
                    end
                    lru_age[victim_idx] = 3;
                    
                    hit_idx = victim_idx;
                    hit = 1; 
                end
            end else begin
                 old_age = lru_age[hit_idx];
                 for (i = 0; i < 4; i = i + 1) begin
                     if (lru_age[i] > old_age) lru_age[i] = lru_age[i] - 1;
                 end
                 lru_age[hit_idx] = 3;
            end

            if (hit) begin
                physical_address = {block[hit_idx], virtual_address[7:0]};
                if (input_read_write) dirty[hit_idx] = 1;
                reference[hit_idx] = 1;
            end
        end
    end
endmodule

// -------------------------------------------------------------------------
// Module: Associative Back Cache
// -------------------------------------------------------------------------
module associative_back_cache (
    input          read_write_cache,
    input  [9:0]   address_cache,
    input  [31:0]  write_data_cache,
    input  [31:0]  read_data_mem,
    input          done,
    output reg [31:0] read_data_cache,
    output reg     hit_miss,
    output reg     read_write_mem,
    output reg [9:0]  address_mem,
    output reg [31:0] write_data_mem
);
    reg [4:0]   tag [0:3];
    reg         valid [0:3];
    reg         dirty [0:3];
    reg [127:0] block [0:3];
    
    reg lru_bit [0:1]; 

    integer i;
    reg [4:0] t_tag;
    reg       t_set;
    reg [3:0] t_offset;
    reg       hit;
    
    reg       way_idx; // 1-bit
    reg [1:0] abs_idx;
    reg [31:0] word_data;

    initial begin
        hit_miss = 0;
        read_write_mem = 0;
        for (i = 0; i < 4; i = i + 1) begin
            valid[i] = 0; dirty[i] = 0; tag[i] = 0; block[i] = 0;
        end
        lru_bit[0] = 1; lru_bit[1] = 1;
        read_data_cache = 32'bx; 
        address_mem = 0;
        write_data_mem = 0;
    end

    always @(address_cache or read_write_cache or write_data_cache) begin
        if (^address_cache === 1'bx) begin
             read_data_cache = 32'bx;
             // Ensure hit_miss is 1 during runtime faults to advance request_num, 
             // but 0 during initialization to avoid spurious increments.
             if (read_write_cache === 1'bx) hit_miss = 0;
             else hit_miss = 1; 
        end else begin
            hit_miss = 0; 
            read_write_mem = 0;
            read_data_cache = 32'bx; 
            
            t_tag    = address_cache[9:5];
            t_set    = address_cache[4];
            t_offset = address_cache[3:0];
            
            hit = 0;
            if (valid[{t_set, 1'b0}] && tag[{t_set, 1'b0}] == t_tag) begin
                hit = 1; way_idx = 0; abs_idx = {t_set, 1'b0};
            end else if (valid[{t_set, 1'b1}] && tag[{t_set, 1'b1}] == t_tag) begin
                hit = 1; way_idx = 1; abs_idx = {t_set, 1'b1};
            end
            
            if (!hit) begin
                way_idx = ~lru_bit[t_set]; 
                abs_idx = {t_set, way_idx};
                
                if (valid[abs_idx] && dirty[abs_idx]) begin
                    read_write_mem = 1;
                    address_mem = {tag[abs_idx], t_set, 4'b0000}; write_data_mem = block[abs_idx][31:0];   #1;
                    address_mem = {tag[abs_idx], t_set, 4'b0100}; write_data_mem = block[abs_idx][63:32];  #1;
                    address_mem = {tag[abs_idx], t_set, 4'b1000}; write_data_mem = block[abs_idx][95:64];  #1;
                    address_mem = {tag[abs_idx], t_set, 4'b1100}; write_data_mem = block[abs_idx][127:96]; #1;
                end
                
                read_write_mem = 0;
                address_mem = {t_tag, t_set, 4'b0000}; #1; block[abs_idx][31:0]   = read_data_mem;
                address_mem = {t_tag, t_set, 4'b0100}; #1; block[abs_idx][63:32]  = read_data_mem;
                address_mem = {t_tag, t_set, 4'b1000}; #1; block[abs_idx][95:64]  = read_data_mem;
                address_mem = {t_tag, t_set, 4'b1100}; #1; block[abs_idx][127:96] = read_data_mem;
                
                tag[abs_idx]   = t_tag;
                valid[abs_idx] = 1;
                dirty[abs_idx] = 0;
            end
            
            lru_bit[t_set] = way_idx;
            
            if (read_write_cache) begin
                dirty[abs_idx] = 1;
                if (t_offset[1:0] == 0) begin
                   case (t_offset[3:2])
                       0: block[abs_idx][31:0]   = write_data_cache;
                       1: block[abs_idx][63:32]  = write_data_cache;
                       2: block[abs_idx][95:64]  = write_data_cache;
                       3: block[abs_idx][127:96] = write_data_cache;
                   endcase
                end else begin
                   case (t_offset[3:2])
                       0: case (t_offset[1:0]) 
                              0: block[abs_idx][7:0]   = write_data_cache[7:0]; 
                              1: block[abs_idx][15:8]  = write_data_cache[7:0];
                              2: block[abs_idx][23:16] = write_data_cache[7:0];
                              3: block[abs_idx][31:24] = write_data_cache[7:0]; 
                          endcase
                       1: case (t_offset[1:0])
                              0: block[abs_idx][39:32] = write_data_cache[7:0];
                              1: block[abs_idx][47:40] = write_data_cache[7:0];
                              2: block[abs_idx][55:48] = write_data_cache[7:0];
                              3: block[abs_idx][63:56] = write_data_cache[7:0];
                          endcase
                       2: case (t_offset[1:0]) 
                              0: block[abs_idx][71:64] = write_data_cache[7:0];
                              1: block[abs_idx][79:72] = write_data_cache[7:0];
                              2: block[abs_idx][87:80] = write_data_cache[7:0];
                              3: block[abs_idx][95:88] = write_data_cache[7:0];
                          endcase
                       3: case (t_offset[1:0]) 
                              0: block[abs_idx][103:96]  = write_data_cache[7:0];
                              1: block[abs_idx][111:104] = write_data_cache[7:0];
                              2: block[abs_idx][119:112] = write_data_cache[7:0];
                              3: block[abs_idx][127:120] = write_data_cache[7:0];
                          endcase
                   endcase
                end
            end else begin
                case (t_offset[3:2])
                   0: word_data = block[abs_idx][31:0];
                   1: word_data = block[abs_idx][63:32];
                   2: word_data = block[abs_idx][95:64];
                   3: word_data = block[abs_idx][127:96];
                endcase
                
                if (t_offset[1:0] == 0) begin
                    read_data_cache = word_data;
                end else begin
                    case (t_offset[1:0])
                        1: read_data_cache = {24'b0, word_data[15:8]};
                        2: read_data_cache = {24'b0, word_data[23:16]};
                        3: read_data_cache = {24'b0, word_data[31:24]};
                        default: read_data_cache = word_data;
                    endcase
                end
            end
            hit_miss = 1;
        end
    end
endmodule

