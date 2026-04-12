# String Display Demo

This is a demo project that outputs a string from FDE FPGA to the programming tool via a FIFO interface.

## Prerequisites

- yosys
- verilator
- surfer
- cargo

## Pin Configuration

`VERICOMM_MAP.json` defines the pin assignments for automatic pin assignment. It maps directly to the pin position index in the FIFO (the interface between the FPGA and the tool). Each pin's index in the JSON corresponds to its position in the FIFO:

- Input pins are indexed starting from 0
- Output pins are indexed starting from 1 (index 0 is reserved for the clock)
- P77 is assumed to be the clock pin

## Building

Run `just impl` to synthesize the code and implement it

## Simulating

Run `just sim` to run verilator. Then, `just view` to display it in surfer 

## Running
Run `just upload` to program the FPGA and start reading the output string.
