module i2c_vl6180x (
    input clk,
    (* pin = "P185"*) input clk_30mhz,
    input reset_n,

    input scl_i,
    output scl_o,
    input sda_i,
    output sda_o
);

  wire rw;

  i2c_m i2c (
      .clk(clk_30mhz),
      .reset_n(reset_n),

      .rw(rw),

      .scl_i(scl_i),
      .scl_o(scl_o),
      .sda_i(sda_i),
      .sda_o(sda_o)
  );

endmodule