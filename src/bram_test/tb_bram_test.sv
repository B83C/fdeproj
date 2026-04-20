`include "tb_common.sv"
`include "ufde_bram_sim.v"

module tb_bram_test;

  tb_common #(
      .TOP_MODULE("bram_test"),
      .CLOCK_HALF_PERIOD(5)
  ) tb ();

  wire clk = tb.clk;
  wire rst = ~tb.rst_n;

  logic start;
  logic done;
  logic [3:0] result;

  bram_test uut (
      .clk   (clk),
      .rst   (rst),
      .start (start),
      .done  (done),
      .result(result)
  );

  initial begin
    tb.rst_n = 0;
    start = 0;
    #20;
    tb.rst_n = 1;
    #20;

    // Read values from initialized BRAM (addresses 0-4 should be A,B,C,D,E)
    $display("BRAM initial values:");
    $display("  mem[0] = %h (expected: A)", uut.mem[0]);
    $display("  mem[1] = %h (expected: B)", uut.mem[1]);
    $display("  mem[2] = %h (expected: C)", uut.mem[2]);
    $display("  mem[3] = %h (expected: D)", uut.mem[3]);
    $display("  mem[4] = %h (expected: E)", uut.mem[4]);

    start = 1;

    wait (done == 1);

    $display("Result (after writes) = %d", result);
    #1;
    $display("Result (after writes) = %d", result);
    #1;
    $display("Result (after writes) = %d", result);
    #1;
    $display("Result (after writes) = %d", result);
    #1;

    tb.done = 1;
    $finish;
  end

endmodule
