`timescale 1ns / 1ps

module tb_vl6180x_post;
  logic clk = 0;
  logic reset_n;
  logic start;
  logic [7:0] range;
  logic range_valid;
  logic ready;
  logic init_done;
  logic sda_i;
  logic sda_o;
  logic scl_i;
  logic scl_o;

  always #5 clk = ~clk;

  assign sda_i = 1'b0;
  assign scl_i = ~scl_o;

  vl6180x dut (
      .clk(clk),
      // .clk_slow(clk),
      .reset_n(reset_n),
      .start(start),
      .range(range),
      .range_valid(range_valid),
      .ready(ready),
      .init_done(init_done),
      // .status_led(),
      // .status_led_slow(),
      .sda_i(sda_i),
      .sda_o(sda_o),
      .scl_i(scl_i),
      .scl_o(scl_o)
  );

  task reset_dut;
    $display("\n=== RESET ===");
    reset_n = 0;
    start   = 0;
    repeat (10) @(negedge clk);
    reset_n = 1;
    repeat (10) @(negedge clk);
    $display("Reset done");
  endtask

  task wait_range;
    wait (range_valid);
    @(negedge clk);
    $display("Range=%d", range);
    @(negedge clk);
  endtask

  initial begin
    $dumpfile("waveform.fst");
    $dumpvars(0, tb_vl6180x_post);

    $display("=== VL6180X POST-SYNTHESIS TESTBENCH ===");

    reset_dut;

    $display("\n=== TEST 1: Check ID ===");
    start = 1;
    @(negedge clk);
    start = 0;
    wait (init_done);
    $display("Init done=%b", init_done);

    $display("\n=== TEST 2: Measure ===");
    for (int i = 0; i < 5; i++) begin
      wait_range;
      $display("Measure %d: range=%d", i, range);
    end

    $display("\n=== All tests completed ===");
    #100;
    $finish;
  end

  initial begin
    #500000;
    $display("TIMEOUT state ready=%b", ready);
    $finish;
  end

endmodule
