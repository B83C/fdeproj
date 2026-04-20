module test (
    input                          CLK,
    input      [2**(12 - 4) - 1:0] ADDR,
    input      [             15:0] DIN,
    output reg [             15:0] DOUT
);
  reg [15:0] mem[0:4096 / 16 - 1];
  always @(posedge CLK) begin
    mem[ADDR] <= DIN;
    DOUT <= mem[ADDR];
  end

  initial begin
    $sreadmemh)
  end

endmodule

