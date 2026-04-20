# String Display Demo

This is a demo project that outputs a string from FDE FPGA to the programming tool via a FIFO interface.

## Prerequisites

- yosys
- yosys-slang
- verilator 
- surfer
- cargo
- uv

## Note
A side note on yosys-slang, you might need to compile it and install it manually if not provided by your distro. It is required to run fully compliant systemverilog parsing.

## Pin Configuration

`VERICOMM_MAP.json` defines the pin assignments for automatic pin assignment. It maps directly to the pin position index in the FIFO (the interface between the FPGA and the tool). Each pin's index in the JSON corresponds to its position in the FIFO:

- Input pins are indexed starting from 0
- Output pins are indexed starting from 1 (index 0 is reserved for the clock)
- P77 is assumed to be the clock pin, but P185 can be set for 30MHz default input clock

## Building

Run `TOP="namedisplay" just all` to synthesize the code for namedisplay, implement it and upload to the FDE board.

Run `TOP="vl6180x" just all` to synthesize the code for vl6180x, implement it and upload to the FDE board.

One can run `just synth`, `just impl_old` followed by `just upload_old` to execute `just all` atomically. Remember to set the TOP env.

## Why _old?

Because the project was intially intended to run with fde-rs with fixes for TBUF. But I gave up due to lack of time.

## Simulating

Run `TOP="vl6180x" just all` to run the simulation for vl6180x module in verilator.  Then, `just view` to display it in surfer.

## Running
Run `just upload` to program the FPGA and start reading the output string. Again, set the TOP env variable as required.

## Generating report
Run `just doc` to generate the slides and report for this project.

