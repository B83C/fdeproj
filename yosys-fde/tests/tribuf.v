module top (
    input  wire a,
    input  wire en,
    output wire y
);
  // This should infer a tri-state buffer
  assign y = en ? a : 1'bz;
endmodule
