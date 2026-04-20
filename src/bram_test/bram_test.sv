module bram_test (
    input wire clk,
    input wire rst,
    input wire start,
    output reg done,
    output reg [3:0] result
);

  wire [3:0] bram_rdata;
  reg [3:0] bram_wdata;
  reg [6:0] bram_addr;
  reg bram_we;

  (* ram_style = "block" *)
  reg [3:0] mem[0:127];

  initial begin
    mem[0] = 4'hA;
    mem[1] = 4'hB;
    mem[2] = 4'hC;
    mem[3] = 4'hD;
    mem[4] = 4'hE;
  end

  always @(posedge clk) begin
    if (bram_we) mem[bram_addr] <= bram_wdata;
  end

  reg [3:0] mem_read_data;
  always @(posedge clk) begin
    mem_read_data <= mem[bram_addr];
  end
  assign bram_rdata = mem_read_data;

  reg [2:0] state;
  localparam IDLE = 0, READ_INIT = 1, WRITE = 2, WRITE_DONE = 3, READ_NEW = 4, DONE = 5;

  always @(posedge clk) begin
    if (rst) begin
      state <= IDLE;
      bram_we <= 0;
      bram_addr <= 0;
      bram_wdata <= 0;
      done <= 0;
      result <= 0;
    end else begin
      case (state)
        IDLE: begin
          if (start) begin
            state <= READ_INIT;
            bram_addr <= 0;
          end
        end
        READ_INIT: begin
          result <= bram_rdata;
          bram_we <= 1;
          bram_wdata <= 4'h5;
          state <= WRITE;
        end
        WRITE: begin
          bram_we <= 0;
          state   <= WRITE_DONE;
        end
        WRITE_DONE: begin
          state <= READ_NEW;
        end
        READ_NEW: begin
          result <= bram_rdata;
          done   <= 1;
          state  <= DONE;
        end
      endcase
    end
  end

endmodule
