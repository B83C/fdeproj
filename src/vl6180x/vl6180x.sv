`timescale 1ns / 1ps
`include "defs.svh"

module vl6180x #(
    parameter CLK_FREQ  = 30_000_000,
    parameter POLL_FREQ = 1000
) (
    (* pin = "P185" *) input clk,
    input reset_n,

    input start,

    output reg errored_pc,
    output [7:0] range,
    output range_valid,


    output ready,
    output init_done,

    (* led = "D0" *)   output reg start_status,
    // (* led = "D1" *)   output reg debug_restart,
    (* led = "D2" *)   output reg errored,
    // (* led = "D3" *)   output reg debug_rw,
    // (* led = "D4" *)   output reg debug_state_0,
    // (* led = "D5" *)   output reg debug_state_1,
    // (* led = "D6" *)   output reg debug_state_2,
    // (* led = "D7" *)   output reg debug_state_3,
    (* pin = "P146" *) output reg debug_in_valid,
    // (* led = "D1" *) output reg status_led_slow,

    (* pin = "P125" *) input  sda_i,
    (* pin = "P123" *) output sda_o,
    (* pin = "P122" *) input  scl_i,
    (* pin = "P121" *) output scl_o
);

  localparam DELAY_COUNTER_MAX = CLK_FREQ / POLL_FREQ;
  localparam DELAY_COUNTER_WIDTH = $clog2(DELAY_COUNTER_MAX);
  logic [DELAY_COUNTER_WIDTH - 1:0] delay_counter = 0;

  localparam [7:0] I2C_ADDR = 8'h29 << 1;
  localparam INIT_SEQ_LEN = 44;

  typedef enum logic [3:0] {
    ST_IDLE,
    ST_READ_DEVICE_REG,
    ST_READ_DEVICE_ID,
    ST_INIT_LOOP,
    ST_MEASURE_REQ,
    ST_POLL_STATUS_REG,
    ST_POLL_STATUS,
    ST_READ_RANGE_REG,
    ST_READ_RANGE
  } state_t;

  state_t state, next_state;

  reg [3:0] tx_count;

  reg [7:0] mosi;
  wire [7:0] miso;
  wire done;
  wire ack;
  wire in_valid;
  reg out_ready;
  wire out_valid;
  wire ack_ready;
  wire i2c_state_t i2c_state;

  wire restart, halt;

  reg [7:0] device_id;
  reg [7:0] poll_status;
  reg [7:0] range_r;

  reg [15:0] poll_delay_counter;

  reg init_done_r;
  reg [5:0] init_idx;

  reg [15:0] reg_addr;
  reg [7:0] reg_data;
  reg [23:0] rom_data_r;
  // reg [5:0] rom_addr_q;

  rw_t rw;

  i2c_m #(
      .SCL_FREQ(100_000),
      .CLK_FREQ(CLK_FREQ)
  ) i2c_inst (
      .clk(clk),
      .reset_n(reset_n),
      .rw(rw),
      .restart(restart),
      .halt(halt),
      .done(done),
      .ack(ack),
      .mosi(mosi),
      .in_valid(in_valid),
      .miso(miso),
      .out_ready(out_ready),
      .ack_ready(ack_ready),
      .out_valid(out_valid),
      .state(i2c_state),
      .sda_i(sda_i),
      .sda_o(sda_o),
      .scl_i(scl_i),
      .scl_o(scl_o)
  );

  assign start_status = start;
  // assign debug_restart = restart;
  assign debug_rw = rw;
  assign debug_init_done = init_done;

  (* ram_style = "block", read_latency = 1 *)
  logic [23:0] init_rom[44];

  always @(posedge clk) begin
    rom_data_r <= init_rom[init_idx];
  end

  initial begin
    init_rom[0]  = 24'h020701;
    init_rom[1]  = 24'h020801;
    init_rom[2]  = 24'h013301;
    init_rom[3]  = 24'h009600;
    init_rom[4]  = 24'h0097FD;
    init_rom[5]  = 24'h00e300;
    init_rom[6]  = 24'h00e404;
    init_rom[7]  = 24'h00e502;
    init_rom[8]  = 24'h00e601;
    init_rom[9]  = 24'h00e703;
    init_rom[10] = 24'h00f502;
    init_rom[11] = 24'h00d905;
    init_rom[12] = 24'h00dbCE;
    init_rom[13] = 24'h00dc03;
    init_rom[14] = 24'h00ddF8;
    init_rom[15] = 24'h009f00;
    init_rom[16] = 24'h00a33c;
    init_rom[17] = 24'h00b700;
    init_rom[18] = 24'h00bb3c;
    init_rom[19] = 24'h00b209;
    init_rom[20] = 24'h00ca09;
    init_rom[21] = 24'h019801;
    init_rom[22] = 24'h01b017;
    init_rom[23] = 24'h01ad00;
    init_rom[24] = 24'h00ff05;
    init_rom[25] = 24'h010005;
    init_rom[26] = 24'h019905;
    init_rom[27] = 24'h010907;
    init_rom[28] = 24'h010a30;
    init_rom[29] = 24'h003f46;
    init_rom[30] = 24'h01a61b;
    init_rom[31] = 24'h01ac3e;
    init_rom[32] = 24'h01a71f;
    init_rom[33] = 24'h010301;
    init_rom[34] = 24'h003000;
    init_rom[35] = 24'h001b0a;
    init_rom[36] = 24'h003e0a;
    init_rom[37] = 24'h013104;
    init_rom[38] = 24'h001110;
    init_rom[39] = 24'h001424;
    init_rom[40] = 24'h0031FF;
    init_rom[41] = 24'h00d201;
    init_rom[42] = 24'h00f201;
    init_rom[43] = 24'h001110;
  end

  // Currently only for these states
  assign rw = (state == ST_POLL_STATUS || state == ST_READ_RANGE || state == ST_READ_DEVICE_ID ) ? D_READ : D_WRITE;

  // Tells the i2c module to restart  any ongoing transaction before initiaitng the current request

  assign in_valid = (rw == D_WRITE && state != ST_IDLE);
  assign restart = (tx_count == 0);
  assign halt = (delay_counter != 0);

  always_ff @(posedge clk) begin
    if (!reset_n) begin
      state <= ST_IDLE;
      tx_count <= 0;
      init_idx <= 0;
      init_done_r <= 0;
      device_id <= 0;
      poll_status <= 0;
      range_r <= 0;
      poll_delay_counter <= 0;
      delay_counter <= 0;
      mosi <= I2C_ADDR | D_WRITE;

      // restart <= 0;
      out_ready <= 0;
      // rom_addr_q <= 0;

    end else begin
      // if (ack_ready && !ack && state != ST_IDLE) begin
      //   // in_valid  <= 0;
      //   out_ready <= 0;
      //   tx_count  <= 0;
      //   // restart   <= 0;
      //   // state <= ST_IDLE;
      //   case (state)
      //     ST_POLL_STATUS, ST_READ_RANGE: begin
      //       state <= ST_MEASURE_REQ;
      //     end
      //     ST_READ_DEVICE_ID: begin
      //       state <= ST_READ_DEVICE_REG;
      //     end
      //     default: begin
      //       state <= ST_IDLE;
      //     end
      //   endcase
      //   mosi <= I2C_ADDR | D_WRITE;
      //   errored <= 1;
      //   errored_pc <= 1;
      // end else begin
      if (state == IDLE && start) begin
        tx_count <= 0;
        mosi <= I2C_ADDR | D_WRITE;
        // in_valid <= 1;
        // restart <= 0;
        delay_counter <= 0;
        state <= ST_READ_DEVICE_REG;
        errored <= 0;
        errored_pc <= 0;

      end
      // case (state)
      //   ST_IDLE: begin
      //     if (start) begin
      //       tx_count <= 0;
      //       mosi <= I2C_ADDR | D_WRITE;
      //       // in_valid <= 1;
      //       // restart <= 0;
      //       state <= ST_READ_DEVICE_REG;
      //       errored <= 0;
      //       errored_pc <= 0;
      //     end
      //   end
      //   // ST_POLL_STATUS: begin
      //   //   if (tx_count == 2) begin
      //   //     delay_counter <= delay_counter - 1;
      //   //     if (delay_counter == 0) begin
      //   //       delay_counter <= 0;
      //   //       state <= ST_MEASURE_REQ;
      //   //       tx_count <= 0;
      //   //     end
      //   //   end
      //   // end
      //   // ST_READ_RANGE: begin
      //   //   if (tx_count == 2) begin
      //   //     delay_counter <= delay_counter - 1;
      //   //     if (delay_counter == 0) begin
      //   //       delay_counter <= 0;
      //   //       state <= ST_MEASURE_REQ;
      //   //       tx_count <= 0;
      //   //     end
      //   //   end
      //   // end
      // endcase

      if (delay_counter != 0) begin
        delay_counter <= delay_counter - 1;
        if (delay_counter == 1) begin
        end
      end else if (done) begin
        tx_count <= tx_count + 1;
        // if (tx_count == 0) begin
        //   // restart <= 0;
        // end
        case (state)
          ST_READ_DEVICE_REG: begin
            case (tx_count)
              0: mosi <= 8'h00;
              1: mosi <= 8'h16;
              2: begin
                mosi <= I2C_ADDR | D_READ;
                out_ready <= 1;
                // in_valid <= 0;
                state <= ST_READ_DEVICE_ID;
                // restart <= 1;
                tx_count <= 0;
              end
              default: begin
                tx_count <= 0;
              end
            endcase
          end

          ST_READ_DEVICE_ID: begin
            case (tx_count)
              0: begin
                // tx_count <= 1;
              end
              1: begin
                // device_id <= miso;
                mosi <= I2C_ADDR | D_WRITE;
                // in_valid <= 1;
                out_ready <= 0;
                // restart <= 1;
                tx_count <= 0;
                init_idx <= 0;
                delay_counter <= DELAY_COUNTER_MAX / 5;
                if (miso[0] == 1'b1) begin
                  state <= ST_INIT_LOOP;
                  // rom_addr_q <= 0;
                end else begin
                  state <= ST_MEASURE_REQ;
                  init_done_r <= 1;
                end
              end
              default: begin
                tx_count <= 0;
              end
            endcase
          end

          ST_INIT_LOOP: begin
            case (tx_count)
              0: mosi <= rom_data_r[23:16];
              1: mosi <= rom_data_r[15:8];
              2: mosi <= rom_data_r[7:0];
              3: begin
                mosi <= I2C_ADDR | D_WRITE;
                out_ready <= 0;
                // in_valid <= 1;
                // restart <= 1;
                delay_counter <= DELAY_COUNTER_MAX / 5;
                if (init_idx < INIT_SEQ_LEN - 1) begin
                  init_idx <= init_idx + 1;
                end else begin
                  init_idx <= 0;
                  state <= ST_MEASURE_REQ;
                end
                tx_count <= 0;
              end
              default: begin
                tx_count <= 0;
              end
            endcase
          end

          ST_MEASURE_REQ: begin
            case (tx_count)
              0: mosi <= 8'h00;
              1: mosi <= 8'h18;
              2: mosi <= 8'h01;
              3: begin
                mosi <= I2C_ADDR | D_WRITE;
                out_ready <= 0;
                // restart <= 1;
                // in_valid <= 1;
                state <= ST_POLL_STATUS_REG;
                delay_counter <= DELAY_COUNTER_MAX / 5;
                tx_count <= 0;
              end
              default: begin
                tx_count <= 0;
              end
            endcase
          end

          ST_POLL_STATUS_REG: begin
            case (tx_count)
              0: mosi <= 8'h00;
              1: mosi <= 8'h4f;
              2: begin
                // in_valid <= 0;
                mosi <= I2C_ADDR | D_READ;
                out_ready <= 1;
                // restart <= 1;
                state <= ST_POLL_STATUS;
                tx_count <= 0;
              end
              default: begin
                tx_count <= 0;
              end
            endcase
          end

          ST_POLL_STATUS: begin
            case (tx_count)
              0: begin
              end
              1: begin
                mosi <= I2C_ADDR | D_WRITE;
                out_ready <= 0;
                tx_count <= 0;
                delay_counter <= DELAY_COUNTER_MAX / 5;
                if (miso[2]) begin
                  state <= ST_READ_RANGE_REG;
                end else begin
                  delay_counter <= DELAY_COUNTER_MAX;
                  state <= ST_POLL_STATUS_REG;
                end
              end
              default: begin
                tx_count <= 0;
              end
            endcase
          end

          ST_READ_RANGE_REG: begin
            case (tx_count)
              0: mosi <= 8'h00;
              1: mosi <= 8'h62;
              2: begin
                // in_valid <= 0;
                mosi <= I2C_ADDR | D_READ;
                out_ready <= 1;
                // restart <= 1;
                state <= ST_READ_RANGE;
                tx_count <= 0;
              end
              default: begin
                tx_count <= 0;
              end
            endcase
          end

          ST_READ_RANGE: begin
            case (tx_count)
              0: begin
              end
              1: begin
                // in_valid <= 1;
                range_r <= miso;
                mosi <= I2C_ADDR | D_WRITE;
                out_ready <= 0;
                delay_counter <= DELAY_COUNTER_MAX;
                state <= ST_MEASURE_REQ;
                tx_count <= 0;
              end
              default: begin
                tx_count <= 0;
              end
            endcase
          end
          default: begin
          end
        endcase
        // end
      end
    end
  end

  assign ready = (state == ST_IDLE);
  assign init_done = init_done_r;
  assign range = range_r;
  assign range_valid = (state == ST_READ_RANGE) && done && tx_count == 4;

  always @(posedge clk) begin
    // debug_state_0  <= miso[0];
    // debug_state_1  <= miso[1];
    // debug_state_2  <= miso[2];
    // debug_state_3  <= miso[3];
    debug_in_valid <= halt;
  end
  // assign debug_state_0 = miso[0];
  // assign debug_state_1 = miso[1];
  // assign debug_state_2 = miso[2];
  // assign debug_state_3 = done;
  // assign debug_in_valid = in_valid;

endmodule
