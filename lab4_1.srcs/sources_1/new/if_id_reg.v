module if_id_reg(
  input        IF_Flush,
  input        IF_ID_write,
  input        clock,
  input  [31:0] if_pc,
  input  [31:0] if_inst,
  output reg [31:0] id_pc,
  output reg [31:0] id_inst
);
  initial begin
    id_pc   = 32'd0;
    id_inst = 32'd0;
  end

  always @(posedge clock) begin
    if (IF_Flush) begin
      id_pc   <= 32'd0;
      id_inst <= 32'd0;
    end else if (IF_ID_write) begin
      id_pc   <= if_pc;
      id_inst <= if_inst;
    end
    // else 保持
  end
endmodule