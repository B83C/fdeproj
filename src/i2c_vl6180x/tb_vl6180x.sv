`timescale 1ns / 1ps

`include "defs.svh"

module tb_vl6180x;
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

  // reg sda_ack = 0;

  wire sda_ack;

  assign sda_ack = dut.i2c_inst.ss == CHECK_ACK;

  // always @(posedge clk) begin
  //   if (dut.i2c_inst.ss == CHECK_ACK) begin
  //     sda_ack <= 1;
  //   end else begin
  //     sda_ack <= 0;
  //   end
  // end
  assign sda_i   = sda_ack ? 1'b0 : ~sda_o;
  assign scl_i   = ~scl_o;

  vl6180x #(
      .CLK_FREQ(30_000_000)
  ) dut (
      .clk(clk),
      .reset_n(reset_n),
      .start(start),
      .range(range),
      .range_valid(range_valid),
      .ready(ready),
      .init_done(init_done),
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
    $dumpvars(0, tb_vl6180x);

    $display("=== VL6180X TESTBENCH ===");

    reset_dut;

    start = 1;

    $display("\n=== TEST 1: Check ID ===");
    // @(negedge clk);
    // start = 0;
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
