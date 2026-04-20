module blinky (
    input clk,
    (* pin = "P185" *) input clk_30mhz,
    (* led = "D0" *) output reg led
);

  localparam DIV_BITS = 15;
  localparam DIV_THRESHOLD = (1 << DIV_BITS) - 1;

  logic [DIV_BITS-1:0] counter;

  always_ff @(posedge clk_30mhz) begin
    if (counter >= DIV_THRESHOLD) begin
      counter <= 0;
      led <= ~led;
    end else begin
      counter <= counter + 1;
    end
  end

endmodule
