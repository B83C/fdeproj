`timescale 1ns / 1ps
`include "defs.svh"

module i2c_m #(
    parameter SCL_FREQ = 400_000,
    parameter CLK_FREQ = 30_000_000
    // parameter CLK_FREQ = 30_000_000
) (
    input clk,
    input reset_n,

    input halt,
    rw_t rw,
    input restart,
    // input continuous,

    output reg done,

    output reg ack_ready,
    output reg ack,

    input [7:0] mosi,
    input in_valid,
    // output reg in_ready,

    output reg [7:0] miso,
    input out_ready,
    output reg out_valid,

    output i2c_state_t state,
    input sda_i,
    output sda_o,
    input scl_i,
    output scl_o
);

  `include "defs.svh"

i2c_state_t ss;

  reg scl_hm, scl_lm;

  // reg [7:0] internal_mosi;

  localparam COUNTER_HALF = CLK_FREQ / (2 * SCL_FREQ);
  localparam COUNTER_QUAD = COUNTER_HALF / 2;
  localparam COUNTER_WIDTH = $clog2(COUNTER_HALF);
  localparam COUNTER_QUAD_WIDTH = $clog2(COUNTER_QUAD);
  // TODO
  reg [COUNTER_WIDTH - 1:0] counter = 0;


  logic [2:0] ind_r, ind_nr;
  logic sda_r = 1;
  logic scl_r = 1;
  wire  middle;

  assign sda_o = ~sda_r;
  assign scl_o = ~scl_r;
  wire sda_in = sda_i;
  wire scl_in = scl_i;

  assign middle = (counter == (COUNTER_QUAD[COUNTER_QUAD_WIDTH:0] - 1));
  //TODO need to change scl back to 1, cuz this will allow clock stretching 
  assign scl_hm = (scl_r == 1'b1) && middle && (scl_in === 1'b1);
  assign scl_lm = (scl_r == 1'b0) && middle;
  assign state  = ss;

  always_ff @(posedge clk) begin
    if (!reset_n) begin
      ss <= IDLE;
      scl_r <= 1;
      sda_r <= 1;
      counter <= 0;
      // in_ready <= 1;
    end else begin
      if (done) begin
        done <= 0;
      end
      // if (ack_ready) begin
      //   ack_ready <= 0;
      // end
      unique case (ss)
        IDLE: begin
          if (!halt && ((rw == D_WRITE && in_valid) || (rw == D_READ && out_ready))) begin
            ss <= START;
            sda_r <= 1'b1;
            scl_r <= 1;
            counter <= 0;
            // in_ready <= 1;
            out_valid <= 0;
            done <= 0;
          end
        end
        default: begin
          if (middle) begin
            unique case (ss)
              START: begin
                if (scl_hm) begin
                  // INIT
                  sda_r <= 1'b0;
                  ind_r <= 3'd7;

                  ack_ready <= 0;
                  ack <= 0;
                  // in_ready <= 0;
                  ss <= WRITE;
                end
              end

              WRITE: begin
                if (scl_lm) begin
                  sda_r <= mosi[ind_r];
                  ind_r <= ind_r - 1;  // Auto rotates back to 7
                  if (ind_r == 3'd0) begin
                    ind_r <= 7;  // Auto rotates back to 7
                    ss <= PRE_ACK;
                  end
                end
              end

              PRE_ACK: begin
                if (scl_lm) begin
                  sda_r <= 1'b1;
                  ss <= CHECK_ACK;
                  // in_ready <= 1;
                  done <= 1;
                end
              end

              // hm is hit first, then lm
              CHECK_ACK: begin
                if (scl_hm) begin
                  ack <= !sda_in;  // ack[0] == 1 means acknowledged
                  ack_ready <= 1;
                  if (!restart && !sda_in) begin
                    ind_r <= 3'd7;
                    // ack_ready <= 0;
                    // in_ready <= 0;
                    if (rw == D_READ && out_ready) begin
                      sda_r <= 1'b1;
                      out_valid <= 0;
                      ss <= READ;
                    end else if (rw == D_WRITE && in_valid) begin
                      ack_ready <= 0;
                      ack <= 0;
                      // in_ready <= 0;
                      // internal_mosi <= mosi;
                      ss <= WRITE;
                    end
                  end
                end else if (scl_lm) begin
                  sda_r <= 1'b0;
                  ss <= STOP;
                end
              end

              // enters from lm
              READ: begin
                if (scl_hm) begin
                  miso[ind_r] <= sda_in;
                  ind_r <= ind_r - 1;
                  if (ind_r == 3'd0) begin
                    ss <= SEND_ACK;
                    out_valid <= 1;
                    done <= 1;
                  end
                end else if (scl_lm) begin
                  sda_r <= 1;
                end
              end
              // first enters from hm, second round but assumes that sda is low
              // TODO check, maybe we need to read from sda instead of sda_r
              SEND_ACK: begin
                if (scl_lm) begin
                  // Send NACK if wishes to stop
                  if (restart || halt) begin
                    sda_r <= 1'b1;
                  end else begin
                    sda_r <= 1'b0;
                  end
                end else if (scl_hm) begin
                  out_valid <= 0;
                  if (!restart && !halt && rw == D_READ && out_ready) begin
                    sda_r <= 1'b1;
                    ack_ready <= 0;
                    ack <= 0;
                    ss <= READ;
                  end else if (!restart && !halt && rw == D_WRITE && in_valid) begin
                    ack_ready <= 0;
                    ack <= 0;
                    ss <= WRITE;
                  end else begin
                    ss <= STOP;
                  end
                end
              end

              STOP: begin
                if (scl_hm) begin
                  // Clean up
                  sda_r <= 1'b1;
                  ss <= IDLE;
                  // ack_ready <= 0;
                  // ack <= 0;  // ack[0] == 1 means acknowledged
                end
              end
            endcase
          end
          counter <= counter + 1;
          if (counter == COUNTER_HALF[COUNTER_WIDTH:0] - 1) begin
            scl_r   <= ~scl_r;
            counter <= 0;
          end
        end
      endcase

    end
  end

endmodule
