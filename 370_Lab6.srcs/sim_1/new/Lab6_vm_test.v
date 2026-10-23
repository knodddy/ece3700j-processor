`timescale 1ns / 1ps

module vm_test;
    reg          clock;
    
    // Interface between cache and CPU
    wire [9:0]   physical_address;
    wire [13:0]  virtual_address;
    wire [31:0]  write_data_cache;
    // Connects Page Table Output to TLB Input
    wire [31:0]  physical_page_tag;
    
    // Interface between cache and main memory
    // 128-bit width for block transfers
    wire [127:0] read_data_mem; 
    wire [31:0]  read_data_cache; 
    wire [127:0] write_data_mem;
    
    wire [9:0]   address_mem;
    wire [5:0]   virtual_page_tag;
    wire [5:0]   request_page_tag;
    
    // Internal signaling
    wire dirty_fetched, reference_fetched;
    wire dirty_write_back, reference_write_back, write_back;
    wire page_fault;
    wire read_write_cache, read_write_mem, done, hit_miss;

    processor                     CPU(
        .hit_miss(hit_miss),
        .clock(clock),
        .read_write(read_write),
        .address(virtual_address),
        .write_data(write_data_cache)
    );
    
    associative_back_cache        cache(
        .read_write_cache(read_write_cache),
        .address_cache(physical_address),
        .write_data_cache(write_data_cache),
        .read_data_mem(read_data_mem),
        .done(done),
        .read_data_cache(read_data_cache),
        .hit_miss(hit_miss),
        .read_write_mem(read_write_mem),
        .address_mem(address_mem),
        .write_data_mem(write_data_mem)
    );
    
    translation_look_aside_buffer TLB(
        .virtual_address(virtual_address),
        .input_read_write(read_write),
        .physical_page_tag(physical_page_tag), // Input from PT
        .dirty_fetched(dirty_fetched),
        .reference_fetched(reference_fetched),
        .physical_address(physical_address),
        .output_read_write(read_write_cache),
        .dirty_write_back(dirty_write_back),
        .reference_write_back(reference_write_back),
        .write_back(write_back),
        .virtual_page_tag(virtual_page_tag),
        .page_fault(page_fault),
        .request_page_tag(request_page_tag)
    );
    
    main_mem                      memory(
        .read_write_mem(read_write_mem),
        .address_mem(address_mem),
        .write_data_mem(write_data_mem),
        .read_data_mem(read_data_mem),
        .done(done)
    );
    
    page_table                    PT(
        .dirty_write_back(dirty_write_back),
        .reference_write_back(reference_write_back),
        .write_back(write_back),
        .virtual_page_tag(virtual_page_tag),
        .physical_page_tag(physical_page_tag), // Output to TLB
        .dirty_fetched(dirty_fetched),
        .reference_fetched(reference_fetched),
        .page_fault(page_fault),
        .request_page_tag(request_page_tag)
    );

    always #5 clock = ~clock;

    always @(posedge clock) begin
        $display("**************************************");
        $display("Request %d: ", CPU.request_num);
        $display("page fault: %b", PT.page_fault);
        // Note: read_data_cache might be X during stores or before hit, which is expected behavior
        $display("data read posedge: %H", read_data_cache);
        $display("contents in TLB: ");
        $display("block 00: tag: %2d, valid: %b, dirty: %b, reference: %b, PPN: %1d", TLB.tag[0], TLB.valid[0], TLB.dirty[0], TLB.reference[0], TLB.block[0]);
        $display("block 01: tag: %2d, valid: %b, dirty: %b, reference: %b, PPN: %1d", TLB.tag[1], TLB.valid[1], TLB.dirty[1], TLB.reference[1], TLB.block[1]);
        $display("block 10: tag: %2d, valid: %b, dirty: %b, reference: %b, PPN: %1d", TLB.tag[2], TLB.valid[2], TLB.dirty[2], TLB.reference[2], TLB.block[2]);
        $display("block 11: tag: %2d, valid: %b, dirty: %b, reference: %b, PPN: %1d", TLB.tag[3], TLB.valid[3], TLB.dirty[3], TLB.reference[3], TLB.block[3]);
        $display("contents in cache: ");
        $display("block 00: tag: %b, valid: %b, dirty: %b, word0: %H, word1: %H, word2: %H, word3: %H", cache.tag[0], cache.valid[0], cache.dirty[0], cache.block[0][127:96], cache.block[0][95:64], cache.block[0][63:32], cache.block[0][31:0]);
        $display("block 01: tag: %b, valid: %b, dirty: %b, word0: %H, word1: %H, word2: %H, word3: %H", cache.tag[1], cache.valid[1], cache.dirty[1], cache.block[1][127:96], cache.block[1][95:64], cache.block[1][63:32], cache.block[1][31:0]);
        $display("block 10: tag: %b, valid: %b, dirty: %b, word0: %H, word1: %H, word2: %H, word3: %H", cache.tag[2], cache.valid[2], cache.dirty[2], cache.block[2][127:96], cache.block[2][95:64], cache.block[2][63:32], cache.block[2][31:0]);
        $display("block 11: tag: %b, valid: %b, dirty: %b, word0: %H, word1: %H, word2: %H, word3: %H", cache.tag[3], cache.valid[3], cache.dirty[3], cache.block[3][127:96], cache.block[3][95:64], cache.block[3][63:32], cache.block[3][31:0]);
    end
    
    initial begin
        clock = 0;
        #140 $stop;
    end
endmodule

module processor (
    input  hit_miss,
    input  clock,
    output read_write,
    output [13:0] address,
    output [31:0] write_data
);
    parameter  request_total = 14; 
    reg [4:0]  request_num;
    reg        read_write_test[request_total-1:0];
    reg [13:0]  address_test[request_total-1:0];
    reg [31:0] write_data_test[request_total-1:0]; 
    initial begin
        request_num = 0;                           
        read_write_test[0]  = 1; address_test[0]  = 14'b000100_100_0_1000; write_data_test[0]  = 1;       
        read_write_test[1]  = 1; address_test[1]  = 14'b000000_100_1_1100; write_data_test[1]  = 12'hdac; 
        read_write_test[2]  = 1; address_test[2]  = 14'b000001_100_1_1000; write_data_test[2]  = 12'hfac; 
        read_write_test[3]  = 1; address_test[3]  = 14'b000000_100_1_0101; write_data_test[3]  = 8'hac;   
        read_write_test[4]  = 0; address_test[4]  = 14'b000111_100_1_0101; write_data_test[4]  = 0;       
        read_write_test[5]  = 0; address_test[5]  = 14'b001000_110_1_0101; write_data_test[5]  = 0;       
        read_write_test[6]  = 0; address_test[6]  = 14'b000001_110_1_0100; write_data_test[6]  = 0;       
        read_write_test[7]  = 1; address_test[7]  = 14'b000111_100_1_0111; write_data_test[7]  = 8'h48; 
        read_write_test[8]  = 0; address_test[8]  = 14'b000000_100_1_1000; write_data_test[8]  = 0;       
        read_write_test[9]  = 0; address_test[9]  = 14'b001010_100_1_0100; write_data_test[9]  = 0;       
        read_write_test[10] = 0; address_test[10] = 14'b000000_110_1_0100; write_data_test[10] = 0;       
        read_write_test[11] = 0; address_test[11] = 14'b000100_100_0_1000; write_data_test[11] = 0;       
        read_write_test[12] = 0; address_test[12] = 14'b000010_110_1_0100; write_data_test[12] = 0;       
        read_write_test[13] = 0; address_test[13] = 14'b000111_100_1_1100; write_data_test[13] = 0;       
    end
    always @(posedge clock) begin
        if (request_num < request_total-1) request_num = request_num + 1;
    end
    assign address      = address_test[request_num];
    assign read_write   = read_write_test[request_num];
    assign write_data   = write_data_test[request_num]; 
endmodule
