`timescale 1ns/1ps

module test_reg_file;

  // DUT I/O
  reg         clock;
  reg  [4:0]  reg_1, reg_2;
  reg         reg_write;
  reg  [4:0]  write_reg;
  reg  [31:0] write_data;
  wire [31:0] data_1, data_2;

  // Instantiate DUT
  reg_file dut (
    .clock(clock),
    .reg_1(reg_1),
    .reg_2(reg_2),
    .reg_write(reg_write),
    .write_reg(write_reg),
    .write_data(write_data),
    .data_1(data_1),
    .data_2(data_2)
  );

  // 10 ns clock
  initial clock = 1'b0;
  always #5 clock = ~clock;

  // Reference model
  reg [31:0] ref_regs [0:31];

  // Vars
  integer i, k;
  integer widx, r1, r2;
  reg [31:0] wdata_rand;

  // --- Helpers ---
  task write_and_update;
    input [4:0] a;
    input [31:0] d;
    begin
      @(negedge clock);
      reg_write  = 1'b1;
      write_reg  = a;
      write_data = d;
      @(posedge clock);              // write occurs here
      if (a != 5'd0) ref_regs[a] = d;
      @(negedge clock);
      reg_write  = 1'b0;
    end
  endtask

  task check_case;
    input [8*64-1:0] label;  // up to 64 chars
    input [4:0] rA;
    input [4:0] rB;
    reg [31:0] e1, e2;
    begin
      reg_1 = rA; reg_2 = rB;
      #1; // settle
      e1 = (rA == 5'd0) ? 32'd0 : ref_regs[rA];
      e2 = (rB == 5'd0) ? 32'd0 : ref_regs[rB];

      if (data_1 !== e1 || data_2 !== e2) begin
        $display("[%0t] %0s | R:r%0d=%h r%0d=%h EXP:%h %h FAIL",
                 $time, label, rA, data_1, rB, data_2, e1, e2);
        $finish;
      end else begin
        $display("[%0t] %0s | R:r%0d=%h r%0d=%h PASS",
                 $time, label, rA, data_1, rB, data_2);
      end
    end
  endtask

  task test_random_once;
    input [4:0] waddr;
    input [31:0] wdata;
    input [4:0] rA;
    input [4:0] rB;
    reg [31:0] e1, e2;
    begin
      write_and_update(waddr, wdata);
      reg_1 = rA; reg_2 = rB; #1;
      e1 = (rA == 5'd0) ? 32'd0 : ref_regs[rA];
      e2 = (rB == 5'd0) ? 32'd0 : ref_regs[rB];

      if (data_1 !== e1 || data_2 !== e2) begin
        $display("[%0t] RAND W:r%0d<=%h | R:r%0d=%h r%0d=%h EXP:%h %h FAIL",
                 $time, waddr, wdata, rA, data_1, rB, data_2, e1, e2);
        $finish;
      end else begin
        $display("[%0t] RAND W:r%0d<=%h | R:r%0d=%h r%0d=%h PASS",
                 $time, waddr, wdata, rA, data_1, rB, data_2);
      end
    end
  endtask
  // ----------------

  initial begin
    // Optional VCD (ignored by Vivado but harmless)
    $dumpfile("reg_file_tb.vcd");
    $dumpvars(0, test_reg_file);

    // Init
    reg_write=0; write_reg=0; write_data=0; reg_1=0; reg_2=0;
    for (i=0;i<32;i=i+1) ref_regs[i]=32'd0;
    repeat(2) @(posedge clock);

    // --- Edge/specific cases ---
    check_case("x0 must read 0 (both ports)", 5'd0, 5'd0);

    write_and_update(5'd0, 32'hDEAD_BEEF);
    check_case("write x0 ignored; read x0,x0", 5'd0, 5'd0);

    write_and_update(5'd5, 32'hA5A5_0001);
    check_case("write x5=0xA5A50001; read", 5'd5, 5'd0);

    check_case("both read ports same reg x5", 5'd5, 5'd5);

    write_and_update(5'd31, 32'hFACE_CAFE);
    check_case("write x31=0xFACECAFE; read", 5'd31, 5'd5);

    write_and_update(5'd10, 32'h1111_2222);
    check_case("read-after-write next cycle", 5'd10, 5'd31);

    // --- Minimal random (2x) ---
    widx = ($random & 5'h1F); if (widx == 0) widx = 1;
    wdata_rand = $random;
    r1 = ($random & 5'h1F);
    r2 = ($random & 5'h1F);
    test_random_once(widx[4:0], wdata_rand, r1[4:0], r2[4:0]);

    widx = ($random & 5'h1F); if (widx == 0) widx = 31;
    wdata_rand = $random;
    r1 = ($random & 5'h1F);
    r2 = ($random & 5'h1F);
    test_random_once(widx[4:0], wdata_rand, r1[4:0], r2[4:0]);

    $display("[%0t] SUMMARY | All tests PASSED", $time);
    $finish;
  end

endmodule
