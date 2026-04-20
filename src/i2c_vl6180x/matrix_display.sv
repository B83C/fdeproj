module matrix_display #(
    parameter BUFFER_SIZE = 32
) (
    input clk,
    input reset_n,

    input [7:0] data_in,
    input data_valid,

    output reg [31:0] column_heights
);

  localparam BUFFER_BITS = $clog2(BUFFER_SIZE);

  reg [7:0] ring_buffer [0:BUFFER_SIZE-1];
  reg [BUFFER_BITS-1:0] write_idx;

  reg [BUFFER_BITS-1:0] scan_idx;
  reg [4:0] row_idx;

  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      write_idx <= 0;
      for (int i = 0; i < BUFFER_SIZE; i++) begin
        ring_buffer[i] <= 8'h00;
      end
    end else begin
      if (data_valid) begin
        ring_buffer[write_idx] <= data_in;
        write_idx <= (write_idx + 1) % BUFFER_SIZE;
      end
    end
  end

  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      scan_idx <= 0;
      row_idx <= 0;
    end else begin
      scan_idx <= (scan_idx + 1) % BUFFER_SIZE;
      if (scan_idx == BUFFER_SIZE - 1) begin
        row_idx <= row_idx + 1;
      end
    end
  end

  wire [7:0] col_value;
  assign col_value = ring_buffer[(write_idx + scan_idx) % BUFFER_SIZE];

  wire [4:0] scaled_height;
  assign scaled_height = (col_value * 16) >> 8;

  always @(posedge clk) begin
    column_heights[scan_idx] <= (row_idx < scaled_height);
  end

endmodule