`include "tb_common.sv"

module tb_namedisplay;

  tb_common #(
      .TOP_MODULE("namedisplay"),
      .CLOCK_HALF_PERIOD(5)
  ) tb ();

  wire        clk = tb.clk;
  wire        rst_n = tb.rst_n;

  logic       valid;
  logic [7:0] console_char;

  namedisplay uut (
      .clk         (clk),
      .rst_n       (rst_n),
      .valid       (valid),
      .console_char(console_char)
  );

  initial begin
    repeat (100) @(posedge clk);
    tb.done = 1;
    $finish;
  end

  always @(posedge clk) begin
    if (valid) begin
      $write("%c", console_char);
      if (console_char == 8'h00 || console_char == 8'h20) $write(".");
    end
  end

endmodule
