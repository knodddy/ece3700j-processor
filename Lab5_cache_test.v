`timescale 1ns / 1ps

module top( input clk);
    wire read_write_cache; /* 1 if write, 0 if read */
    wire hit_miss; /* 1 if hit, 0 if miss */
    wire [9:0]   address_cache;
    wire [31:0]  read_data_cache, write_data_cache;
    // interface between cache and main memory
    wire [31:0]  write_data_mem,read_data_mem;
    wire [9:0]   address_mem;
    wire read_write_mem, Done;
    // You may add the signal you need and modify some signals if necessary

    Cache Cache(read_write_cache, address_cache, write_data_cache, Done, read_data_mem, read_data_cache, hit_miss, read_write_mem, address_mem, write_data_mem);
    main_memory mem_db(clk, read_write_mem, address_mem, write_data_mem, read_data_mem, Done);
    // NOTE: added `clk` to main_memory instantiation since memory FSM is clocked
    CPU CPU_db(hit_miss, clk,read_data_cache,read_write_cache, address_cache, write_data_cache);
endmodule

module CacheTest;
    reg clock;

    parameter half_period = 5;
    integer t = 0;
    
    top test(clock);
    
    initial begin
        #0 clock = 1;
    end
    
    always #half_period begin
        clock = ~clock;
        t=t+1;
    end
    
    always @(posedge clock) begin
            $display("===============================================");
            $display("Clock cycle %d", t/2);
            $display("Read data = %H", test.read_data_cache);
            $display("hit_miss = %d", test.hit_miss);
            $display("read_write_cache = %d", test.read_write_cache);
            $display("Request number %d", test.request_num);
            $display("===============================================");
            
    end
    initial
        #200 $stop;

endmodule