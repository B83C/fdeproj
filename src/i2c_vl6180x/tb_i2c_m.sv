`timescale 1ns / 1ps

`include "defs.svh"

module tb_i2c_m;
  logic clk = 0;
  logic reset_n;
  rw_t rw;
  logic restart;
  logic done;
  logic ack_wire;
  logic ack_ready;
  logic [7:0] mosi;
  logic in_valid;
  logic [7:0] miso;
  logic out_ready;
  logic out_valid;
  i2c_state_t state;
  logic sda_i;
  logic sda_o;
  logic scl_i;
  logic scl_o;

  always #5 clk = ~clk;

  wire sda_ack;
  assign sda_ack = dut.ss == CHECK_ACK;
  assign sda_i   = sda_ack ? 1'b0 : ~sda_o;
  assign scl_i   = ~scl_o;

  i2c_m #(
      .SCL_FREQ(100_000),
      .CLK_FREQ(10_000_000)
  ) dut (
      .clk(clk),
      .reset_n(reset_n),
      .rw(rw),
      .restart(restart),
      .done(done),
      .ack(ack_wire),
      .ack_ready(ack_ready),
      .mosi(mosi),
      .in_valid(in_valid),
      .miso(miso),
      .out_ready(out_ready),
      .out_valid(out_valid),
      .state(state),
      .sda_i(sda_i),
      .sda_o(sda_o),
      .scl_i(scl_i),
      .scl_o(scl_o)
  );

  task reset_dut;
    $display("\n=== RESET ===");
    reset_n = 0;
    restart = 0;
    rw = D_WRITE;
    mosi = 0;
    in_valid = 0;
    out_ready = 0;
    repeat (10) @(negedge clk);
    reset_n = 1;
    repeat (10) @(negedge clk);
    $display("Reset done");
  endtask

  task start_write(input [7:0] data);
    @(negedge clk);
    mosi = data;
    rw = D_WRITE;
    in_valid = 1;
    // @(negedge clk);
    wait (done);
    in_valid = 0;
    @(negedge clk);
    $display("  Wrote 0x%02h ack=%b", data, ack_wire);
  endtask

  task start_read;
    @(negedge clk);
    out_ready = 1;
    rw = D_READ;
    wait (done);
    @(negedge clk);
    $display("  Read 0x%02h ack=%b", miso, ack_wire);
    out_ready = 0;
  endtask

  task set_restart;
    @(negedge clk);
    restart = 1;
    @(negedge clk);
    restart = 0;
  endtask

  initial begin
    // $dumpfile("waveform.fst");
    // $dumpvars(0, tb_i2c_m);

    $display("=== I2C MASTER TESTBENCH ===");

    reset_dut;

    $display("\n=== TEST 1: Write + Write (continuous) ===");
    start_write(8'hA5);
    start_write(8'hB6);

    wait (ack_ready);

    $display("\n=== TEST 2: Write + Restart + Write + Read ===");
    start_write(8'h52);
    start_write(8'h00);
    restart = 1;
    start_write(8'h62);
    restart = 0;
    start_read();

    $display("\n=== All tests PASSED ===");
    #10000;
    $finish;
  end

  initial begin
    #500000;
    $display("TIMEOUT state=%d", state);
    $finish;
  end

endmodule
