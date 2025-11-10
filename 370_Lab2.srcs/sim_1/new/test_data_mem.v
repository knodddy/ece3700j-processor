`timescale 1ns/1ps

module test_data_mem;

  // ---- DUT I/O ----
  reg         clock;
  reg  [31:0] addr;
  reg  [31:0] write_data;
  reg         mem_write;
  reg         mem_read;
  wire [31:0] data;

  // Instantiate DUT (default MAX_MEM_SIZE=1023)
  data_mem dut (
    .clock(clock),
    .addr(addr),
    .write_data(write_data),
    .mem_write(mem_write),
    .mem_read(mem_read),
    .data(data)
  );

  // ---- Clock ----
  initial clock = 1'b0;
  always #5 clock = ~clock;   // 10 ns period

  // ---- Reference model (byte-addressed) ----
  localparam REF_MAX = 1023;
  reg [7:0] ref_mem [0:REF_MAX];

  integer i;

  // Fetch a 32-bit word from the reference bytes (little-endian)
  function [31:0] ref_read_word;
    input integer base;
    begin
      ref_read_word = {ref_mem[base+3], ref_mem[base+2], ref_mem[base+1], ref_mem[base+0]};
    end
  endfunction

  // Write a 32-bit word into the reference bytes (little-endian)
  task ref_write_word;
    input integer base;
    input [31:0] w;
    begin
      ref_mem[base+0] = w[7:0];
      ref_mem[base+1] = w[15:8];
      ref_mem[base+2] = w[23:16];
      ref_mem[base+3] = w[31:24];
    end
  endtask

  // Synchronous write to DUT + update scoreboard (1 posedge)
  task do_write;
    input [31:0] a;
    input [31:0] w;
    begin
      @(negedge clock);
      addr       = a;
      write_data = w;
      mem_write  = 1'b1;
      mem_read   = 1'b0;
      @(posedge clock);                 // DUT writes here
      ref_write_word(a, w);             // mirror write in scoreboard
      @(negedge clock);
      mem_write  = 1'b0;
    end
  endtask

  // Combinational read from DUT; compare with expected; one-line print
  task do_read_check;
    input [8*64-1:0] label;
    input [31:0] a;
    input [31:0] exp;
    begin
      addr      = a;
      mem_read  = 1'b1;
      mem_write = 1'b0;
      #1;  // settle
      if (data !== exp) begin
        $display("[%0t] %0s | A:%h W:%h R:%h EXP:%h FAIL",
                 $time, label, a, 32'hXXXXXXXX, data, exp);
        $finish;
      end else begin
        $display("[%0t] %0s | A:%h W:%h R:%h EXP:%h PASS",
                 $time, label, a, 32'hXXXXXXXX, data, exp);
      end
      #9;
      mem_read = 1'b0;
    end
  endtask

  // Write then read; single-line summary including written value
  task write_read_case;
    input [8*64-1:0] label;
    input [31:0] a;
    input [31:0] w;
    reg   [31:0] exp_word;
    begin
      do_write(a, w);
      exp_word = ref_read_word(a);
      addr     = a;
      mem_read = 1'b1;
      #1;
      if (data !== exp_word) begin
        $display("[%0t] %0s | A:%h W:%h R:%h EXP:%h FAIL",
                 $time, label, a, w, data, exp_word);
        $finish;
      end else begin
        $display("[%0t] %0s | A:%h W:%h R:%h EXP:%h PASS",
                 $time, label, a, w, data, exp_word);
      end
      #9;
      mem_read = 1'b0;
    end
  endtask

  // ---- Test sequence ----
  integer raddr;
  reg [31:0] wrand;

  initial begin
    // Optional VCD
    $dumpfile("data_mem_tb.vcd");
    $dumpvars(0, test_data_mem);

    // Init TB drives
    addr = 32'h0; write_data = 32'h0; mem_write = 1'b0; mem_read = 1'b0;

    // Init reference bytes to zero (match DUT init)
    for (i = 0; i <= REF_MAX; i = i + 1) ref_mem[i] = 8'd0;

    // Let reset/initials breathe
    repeat (2) @(posedge clock);

    // 1) Read disabled gating (should be zero even if memory has data)
    addr = 32'h10; mem_read = 1'b0; #1;
    if (data !== 32'h0000_0000) begin
      $display("[%0t] read disabled returns 0 | A:%h W:%h R:%h EXP:%h FAIL",
               $time, addr, 32'hXXXXXXXX, data, 32'h0000_0000);
      $finish;
    end else begin
      $display("[%0t] read disabled returns 0 | A:%h W:%h R:%h EXP:%h PASS",
               $time, addr, 32'hXXXXXXXX, data, 32'h0000_0000);
    end
    #9;

    // 2) Aligned write+read @0
    write_read_case("WRITE+READ aligned @0", 32'd0, 32'hAABB_CCDD);

    // 3) Misaligned write+read @1
    write_read_case("WRITE+READ misaligned @1", 32'd1, 32'h1122_3344);

    // 4) Overwrite overlap: write @2 then read @1 (overlaps previous)
    do_write(32'd2, 32'hDEAD_BEEF);
    // Expect from scoreboard at A=1 after overlapping write
    do_read_check("OVERWRITE overlap: read @1 after write @2",
                  32'd1, ref_read_word(32'd1));

    // 5) Random #1
    raddr = $random % (REF_MAX - 3); if (raddr < 0) raddr = -raddr;
    wrand = $random;
    write_read_case("RANDOM #1", raddr[31:0], wrand);

    // 6) Random #2
    raddr = $random % (REF_MAX - 3); if (raddr < 0) raddr = -raddr;
    wrand = $random;
    write_read_case("RANDOM #2", raddr[31:0], wrand);

    $display("[%0t] SUMMARY | All tests PASSED", $time);
    $finish;
  end

endmodule
