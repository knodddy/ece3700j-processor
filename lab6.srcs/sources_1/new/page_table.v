`timescale 1ns / 1ps

module page_table (
    // from TLB on eviction
    input        dirty_write_back,
    input        reference_write_back,
    input        write_back,
    input  [5:0] virtual_page_tag,   // VPN of entry being written back

    // to TLB on lookup
    output reg [31:0] physical_page_tag, // {valid, 29'b0, ppn}
    output reg        dirty_fetched,
    output reg        reference_fetched,
    output reg        page_fault,
    input      [5:0]  request_page_tag   // VPN being requested
);

    // per-VPN state
    reg        valid     [0:63];
    reg [1:0]  ppn       [0:63];
    reg        dirty     [0:63];
    reg        reference [0:63];

    integer i;

    initial begin
        // default: all invalid, clean, not referenced
        for (i = 0; i < 64; i = i + 1) begin
            valid[i]     = 1'b0;
            ppn[i]       = 2'b00;
            dirty[i]     = 1'b0;
            reference[i] = 1'b0;
        end

        // original mapping you gave (valid + PPN), dirty/reference = 0
        valid[0] = 1'b1;  ppn[0]  = 2'd1;
        valid[1] = 1'b1;  ppn[1]  = 2'd3;
        valid[2] = 1'b0;  ppn[2]  = 2'd2; // invalid -> page fault
        valid[3] = 1'b1;  ppn[3]  = 2'd3;
        valid[4] = 1'b1;  ppn[4]  = 2'd2;
        // 5,6 remain invalid
        valid[7] = 1'b1;  ppn[7]  = 2'd1;
        valid[8] = 1'b1;  ppn[8]  = 2'd1;
        // 9 invalid
        valid[10] = 1'b1; ppn[10] = 2'd1;
    end

    // combinational lookup side: TLB asks for request_page_tag
    always @(*) begin
        physical_page_tag  = {valid[request_page_tag], 29'b0, ppn[request_page_tag]};
        dirty_fetched      = dirty[request_page_tag];
        reference_fetched  = reference[request_page_tag];
        page_fault         = ~valid[request_page_tag];
    end

    // write-back from TLB on eviction
    always @(*) begin
        if (write_back) begin
            dirty[virtual_page_tag]     = dirty_write_back;
            reference[virtual_page_tag] = reference_write_back;
        end
    end

endmodule
