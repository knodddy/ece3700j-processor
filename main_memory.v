`timescale 1ns / 1ps

module main_memory(
    input        clk, 
    input        read_write_mem,     // write <- 1, read <- 0
    input [9:0]  address_mem,        // byte address
    input [31:0] write_data_mem,     // data from cache
    output reg [31:0] read_data_mem, // data to cache
    output reg       Done            // signals mem op complete
);
    parameter MEM_DELAY = 2;

    reg [7:0] mem [0:1023];
    integer i;

    reg [9:0]  addr_reg;
    reg [31:0] wdata_reg;
    reg        op_reg;    // 0 = read, 1 = write
    reg [1:0]  state;
    reg [3:0]  cnt;

    localparam IDLE  = 2'b00;
    localparam WAIT  = 2'b01;
    localparam RESP  = 2'b10;

    initial begin
        for (i = 0; i < 1024; i = i + 1)
            mem[i] = $random;
        Done = 0;
        read_data_mem = 0;
        state = IDLE;
        cnt   = 0;
    end

    always @(posedge clk) begin
        case (state)
            IDLE: begin
                Done <= 0;
                cnt  <= 0;
                // Very simple: treat any change as new request
                // (cache should only change signals when not busy)
                if (read_write_mem === 1'b0 || read_write_mem === 1'b1) begin
                    addr_reg  <= address_mem;
                    wdata_reg <= write_data_mem;
                    op_reg    <= read_write_mem;
                    state     <= WAIT;
                end
            end

            WAIT: begin
                cnt <= cnt + 1;
                if (cnt == MEM_DELAY) begin
                    if (op_reg == 1'b0) begin
                        // READ
                        read_word(addr_reg, read_data_mem);
                    end else begin
                        // WRITE
                        write_word(addr_reg, wdata_reg);
                    end
                    state <= RESP;
                end
            end

            RESP: begin
                Done  <= 1'b1;   // one-cycle pulse
                state <= IDLE;
            end
        endcase
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
            base       = {addr[9:2], 2'b00};
            mem[base]   = data[7:0];
            mem[base+1] = data[15:8];
            mem[base+2] = data[23:16];
            mem[base+3] = data[31:24];
        end
    endtask

endmodule