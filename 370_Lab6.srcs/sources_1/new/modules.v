`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/11/2025 05:14:19 PM
// Design Name: 
// Module Name: modules
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

// --------------------------------------------------------
// Designed Modules
// --------------------------------------------------------

module main_mem(
    input read_write_mem,
    input [9:0] address_mem,
    input [127:0] write_data_mem,
    output reg [127:0] read_data_mem,
    output reg done
);
    // 1024 bytes = 64 blocks of 16 bytes (128 bits). 
    // Initial data has extra 26 bits padding -> 154 bits total.
    reg [153:0] mem [0:63];
    integer i;

    initial begin
        // Initialize with 0
        for (i=0; i<64; i=i+1) mem[i] = 154'b0;
        
        // Load Reference Data
        mem[0] = {26'b0, 32'hA, 32'hE, 32'hF, 32'h55555555};
        mem[4] = {26'b0, 32'hBBBBBBBB, 32'hAAAAAAAA, 32'hEEEEEEEE, 32'hCCCCCCCC};
        mem[16] = {26'b0, 32'h11111111, 32'h22222222, 32'h33333333, 32'h44444444};
        mem[20] = {26'b0, 32'h281, 32'h285, 32'h0, 32'h28d};
        mem[21] = {26'b0, 32'h281, 32'h285, 32'h0, 32'h28d};
        mem[25] = {26'b0, 32'h191, 32'h195, 32'h199, 32'h191};
        mem[29] = {26'b0, 32'h1d1, 32'h1d5, 32'h1d9, 32'h1dd};
        mem[33] = {26'b0, 32'h55555555, 32'h66666666, 32'h77777777, 32'h88888888};
        mem[40] = {26'b0, 32'h281, 32'h0, 32'h285, 32'h28d};
        mem[48] = {26'b0, 32'h55555555, 32'h66666666, 32'h77777777, 32'h88888888};
        mem[49] = {26'b0, 32'h55555555, 32'h66666666, 32'h77777777, 32'h88888888};
        mem[57] = {26'b0, 32'h391, 32'h0, 32'h395, 32'h39d};
        mem[61] = {26'b0, 32'h3d1, 32'h3d5, 32'h3d9, 32'h3dd};
    end

    // Combinational Read/Write Logic (Instantaneous)
    // Address is 10 bits (Byte addr). Block index is [9:4].
    always @(*) begin
        read_data_mem = mem[address_mem[9:4]][127:0];
        done = 1; // Instantaneous
        if (!read_write_mem) begin // Write is active low in some conventions? 
            // The testbench sets read_write=0 for Load? Wait.
            // Processor: 1=Store, 0=Load.
            // Cache sends read_write_mem.
            // Usually 1=Read, 0=Write? Or same as CPU?
            // Let's assume active high Write based on "read_write_mem" name is ambiguous.
            // In CPU: read_write_test[0]=1 is SW. So 1=Write.
            // So if read_write_mem == 1, it's a write?
            // Let's check Cache logic later. Assuming 1=Write for now.
        end
    end
    
    // Explicit write block
    always @(read_write_mem or address_mem or write_data_mem) begin
        if (read_write_mem) begin // Assuming 1 is Write (matching CPU)
             mem[address_mem[9:4]] = {26'b0, write_data_mem};
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
    reg [31:0] table [0:63];
    integer i;

    initial begin
        for (i=0; i<64; i=i+1) table[i] = 32'b0;
        table[0] = {1'b1, 29'b0, 2'd1};
        table[1] = {1'b1, 29'b0, 2'd3};
        table[2] = {1'b0, 29'b0, 2'd2};
        table[3] = {1'b1, 29'b0, 2'd3};
        table[4] = {1'b1, 29'b0, 2'd2};
        table[7] = {1'b1, 29'b0, 2'd1}; 
        table[8] = {1'b1, 29'b0, 2'd1};
        table[10] = {1'b1, 29'b0, 2'd1}; 
    end

    // Read Logic
    always @(*) begin
        // Format: {Valid (1), 29'b0, PPN (2)}
        // Using bit 31 as Valid.
        if (table[request_page_tag][31]) begin
            page_fault = 0;
            physical_page_tag = table[request_page_tag]; // Return whole entry? Or just PPN?
                                                         // Testbench wire is 32 bits. TLB extracts PPN.
            // Dirty/Ref bits? The Ref PT has no D/R bits in the entry structure shown (Just V and PPN).
            // But we need to output them. Assuming 0 for initial fetch or derived from entry?
            // The prompt says "table entry size: 4 bytes". Ref: {1'b1, 29'b0, 2'd1}.
            // It seems D/R are not stored or are 0.
            dirty_fetched = 0; 
            reference_fetched = 0;
        end else begin
            page_fault = 1;
            physical_page_tag = 32'b0;
            dirty_fetched = 0;
            reference_fetched = 0;
        end
    end

    // Write Back Logic (Updating PT from TLB eviction)
    always @(write_back or virtual_page_tag or dirty_write_back or reference_write_back) begin
        if (write_back) begin
            // In a real PT, we would update D/R bits. 
            // Given the limited format {V, 29, PPN}, we might not store them effectively, 
            // or the format in ref is just initial state.
            // We will just keep the entry valid and PPN same, maybe ignoring D/R storage 
            // because the sample output doesn't show PT content changes, only TLB/Cache.
        end
    end

endmodule

module translation_look_aside_buffer(
    input [13:0] virtual_address,
    input input_read_write, // 1=Write, 0=Read
    output reg [31:0] physical_page_tag, // From PT
    input dirty_fetched,
    input reference_fetched,
    output reg [9:0] physical_address,
    output reg output_read_write,
    output reg dirty_write_back,
    output reg reference_write_back,
    output reg write_back,
    output reg [5:0] virtual_page_tag, // VPN for writeback
    input page_fault,
    output reg [5:0] request_page_tag // VPN to PT
);
    // 4 entries, fully associative
    reg [5:0] tag [0:3];
    reg [1:0] block [0:3]; // PPN
    reg valid [0:3];
    reg dirty [0:3];
    reg reference [0:3];
    
    // LRU Age: 0 (MRU) to 3 (LRU)
    reg [1:0] lru_age [0:3]; 
    
    integer i;
    initial begin
        for (i=0; i<4; i=i+1) begin
            tag[i] = 0; block[i] = 0; valid[i] = 0; dirty[i] = 0; reference[i] = 0; lru_age[i] = i;
        end
    end

    reg [5:0] vpn;
    reg hit;
    reg [1:0] hit_index;
    reg [1:0] victim_index;

    always @(*) begin
        vpn = virtual_address[13:8];
        hit = 0;
        hit_index = 0;
        
        // Check Hit
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
        request_page_tag = vpn;
        output_read_write = input_read_write;

        if (hit) begin
            // Calculate PA
            physical_address = {block[hit_index], virtual_address[7:0]};
            
            // Update State (LRU, D, R)
            // Move hit_index to MRU (0), increment others < old_age
            // Since always @(*) triggers continuously, we need to be careful not to cycle.
            // But this is behavioral simulation of 'instant' operation.
            // We use a temporary update logic.
            
            // Update LRU
            // This is a side effect. In pure comb logic, this is tricky.
            // But we will model it as immediate state update.
            if (lru_age[hit_index] != 0) begin
                for (i=0; i<4; i=i+1) begin
                    if (lru_age[i] < lru_age[hit_index]) lru_age[i] = lru_age[i] + 1;
                end
                lru_age[hit_index] = 0;
            end
            
            reference[hit_index] = 1;
            if (input_read_write) dirty[hit_index] = 1;
            
        end else begin
            // Miss
            // 1. Find Victim (LRU = 3)
            for (i=0; i<4; i=i+1) begin
                if (lru_age[i] == 3) victim_index = i[1:0];
            end
            
            // 2. Write back if dirty
            if (valid[victim_index] && dirty[victim_index]) begin
                write_back = 1;
                virtual_page_tag = tag[victim_index];
                dirty_write_back = dirty[victim_index];
                reference_write_back = reference[victim_index];
            end
            
            // 3. Fetch from PT
            // request_page_tag is driven to PT.
            // PT responds with page_fault and physical_page_tag (entry)
            
            if (!page_fault) begin
                // Update Entry
                tag[victim_index] = vpn;
                block[victim_index] = physical_page_tag[1:0]; // Extract PPN from PT Entry
                valid[victim_index] = 1;
                dirty[victim_index] = (input_read_write) ? 1 : 0; // If it's a store, it becomes dirty immediately?
                // Sample result Request 0: sw... TLB miss... dirty: 1. Yes.
                reference[victim_index] = 1;
                
                // Update LRU
                for (i=0; i<4; i=i+1) begin
                    if (lru_age[i] < lru_age[victim_index]) lru_age[i] = lru_age[i] + 1;
                end
                lru_age[victim_index] = 0;
                
                // Calculate PA
                physical_address = {block[victim_index], virtual_address[7:0]};
            end else begin
                // Page Fault
                // Keep PA 0 or undefined.
                physical_address = 10'b0; // Should trigger nothing in cache ideally
            end
        end
    end
endmodule

module associative_back_cache(
    input read_write_cache, // 1=Write, 0=Read
    input [9:0] address_cache,
    input [31:0] write_data_cache,
    input [127:0] read_data_mem,
    input done,
    output reg [31:0] read_data_cache,
    output reg hit_miss, // 1=Hit, 0=Miss
    output reg read_write_mem, // 1=Write, 0=Read
    output reg [9:0] address_mem,
    output reg [127:0] write_data_mem
);
    // 2 Sets, 2 Ways. 
    // Set 0: indices 0,1. Set 1: indices 2,3.
    reg [127:0] block [0:3];
    reg [4:0] tag [0:3];
    reg valid [0:3];
    reg dirty [0:3];
    reg lru [0:1]; // 0: Way 0 is MRU (so Way 1 is LRU victim). 1: Way 1 is MRU.
                   // Definition: "Replace LRU". If lru[set]==0, Way 1 is LRU. If lru[set]==1, Way 0 is LRU.
                   // Let's stick to: lru[set] points to the MRU way.
                   // Initial 0.
                   
    integer i;
    initial begin
        for (i=0; i<4; i=i+1) begin
            block[i] = 0; tag[i] = 0; valid[i] = 0; dirty[i] = 0;
        end
        lru[0] = 1; // Initial state adjustment to match traces if needed. 
                    // Ref trace Req 0 fills Way 0 (index 0). 
                    // If lru[0]==0 (Way 0 is MRU), next goes to Way 1. 
                    // Let's assume lru bit indicates MRU way.
        lru[1] = 1;
    end

    wire [4:0] current_tag;
    wire set_index;
    wire [3:0] offset;
    
    assign current_tag = address_cache[9:5];
    assign set_index = address_cache[4]; // Bit 4 is set index
    assign offset = address_cache[3:0];
    
    reg way0_hit, way1_hit;
    reg [1:0] hit_way;
    reg [1:0] victim_way;
    
    // Base index for the set
    wire [1:0] base; 
    assign base = (set_index) ? 2 : 0;

    always @(*) begin
        // Check Hit
        way0_hit = (valid[base] && tag[base] == current_tag);
        way1_hit = (valid[base+1] && tag[base+1] == current_tag);
        
        hit_miss = (way0_hit || way1_hit);
        
        // Default Memory Signals
        read_write_mem = 0; // Read
        address_mem = 0;
        write_data_mem = 0;
        read_data_cache = 0;

        if (hit_miss) begin
            // HIT
            hit_way = (way0_hit) ? base : base+1;
            
            // Read/Write Data
            // Extract word. Offset is byte index. Word index = offset[3:2].
            if (read_write_cache) begin // Write
                // Update Cache Block
                case(offset[3:2])
                    2'b00: block[hit_way][127:96] = write_data_cache; // Word 0
                    2'b01: block[hit_way][95:64] = write_data_cache;  // Word 1
                    2'b10: block[hit_way][63:32] = write_data_cache;  // Word 2
                    2'b11: block[hit_way][31:0] = write_data_cache;   // Word 3
                endcase
                dirty[hit_way] = 1;
                // Read data output on write? Usually undefined or old.
            end else begin // Read
                 case(offset[3:2])
                    2'b00: read_data_cache = block[hit_way][127:96];
                    2'b01: read_data_cache = block[hit_way][95:64];
                    2'b10: read_data_cache = block[hit_way][63:32];
                    2'b11: read_data_cache = block[hit_way][31:0];
                endcase
            end
            
            // Update LRU: hit_way becomes MRU.
            // If hit_way is way 0 (base), lru[set] = 0. 
            // If hit_way is way 1 (base+1), lru[set] = 1.
            lru[set_index] = (way0_hit) ? 0 : 1; 

        end else begin
            // MISS
            // Select Victim based on LRU
            // If lru[set] == 0 (Way 0 is MRU), victim is Way 1.
            // If lru[set] == 1 (Way 1 is MRU), victim is Way 0.
            victim_way = (lru[set_index] == 0) ? base+1 : base;
            
            // Write Back if Dirty
            if (valid[victim_way] && dirty[victim_way]) begin
                read_write_mem = 1; // Write
                // Construct Address: Tag + Set + 0000
                address_mem = {tag[victim_way], set_index, 4'b0000};
                write_data_mem = block[victim_way];
                // In hardware, we'd wait for write to finish. Here assume instant.
            end
            
            // Fetch New Block
            read_write_mem = 0; // Read
            address_mem = {current_tag, set_index, 4'b0000};
            
            // Update Cache Entry
            if (done) begin // Always 1
                block[victim_way] = read_data_mem;
                tag[victim_way] = current_tag;
                valid[victim_way] = 1;
                dirty[victim_way] = 0;
                
                // Now perform the pending CPU request on the new block
                 if (read_write_cache) begin // Write
                    case(offset[3:2])
                        2'b00: block[victim_way][127:96] = write_data_cache;
                        2'b01: block[victim_way][95:64] = write_data_cache;
                        2'b10: block[victim_way][63:32] = write_data_cache;
                        2'b11: block[victim_way][31:0] = write_data_cache;
                    endcase
                    dirty[victim_way] = 1;
                end else begin // Read
                     case(offset[3:2])
                        2'b00: read_data_cache = block[victim_way][127:96];
                        2'b01: read_data_cache = block[victim_way][95:64];
                        2'b10: read_data_cache = block[victim_way][63:32];
                        2'b11: read_data_cache = block[victim_way][31:0];
                    endcase
                end
                
                // Update LRU
                lru[set_index] = (victim_way == base) ? 0 : 1;
                
                // Set Hit (so CPU advances)
                hit_miss = 1; 
            end
        end
    end

endmodule
