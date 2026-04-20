module tribuf (
    input clk,
    input en,
    (* pin = "147,145"*) inout [1:0] x,
    output [1:0] y,
    output test
);
  reg [7:0] drv;
  always @(posedge clk) drv <= drv + 1'b1;

  assign x = en ? 2'(drv) : 2'bZZ;
  assign y = x;
  assign test = en;

endmodule
