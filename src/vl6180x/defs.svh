`ifndef DEFS_H
`define DEFS_H

typedef enum logic [2:0] {
  IDLE,
  START,
  WRITE,
  READ,
  PRE_ACK,
  CHECK_ACK,
  SEND_ACK,
  STOP
} i2c_state_t;

typedef enum logic {
  D_WRITE = 0,
  D_READ
} rw_t;

`endif
