YOSYS_BIN := require("yosys")
verilator_BIN := require("verilator")
surfer_BIN := require("surfer")
cargo_BIN := require("cargo")
FDE_CLI := "tools/bin"
# FDE_CLI := "/home/b83c/hw/ufde/FDE-Source/output"
HW_LIB := "hw_lib"

TOP := "string_display"

INPUT_FILE := "string_display.sv"
YOSYS_DIR := "yosys"
PIN_CONFIG := "VERICOMM_MAP.json"

default:
    @just --list

synth file=INPUT_FILE:
    #!/bin/bash
    set -e
  
    {{YOSYS_BIN}} -p "
    read_verilog -sv -lib {{YOSYS_DIR}}/fdesimlib.v
    read_verilog -sv src/{{file}}

    hierarchy -top {{TOP}}

    synth -run coarse; opt;
    proc; opt;
    memory; opt;

    techmap -map {{YOSYS_DIR}}/techmap.v; opt
    wreduce
    techmap -D NO_LUT -map {{YOSYS_DIR}}/cells_map.v; opt
    techmap -map {{YOSYS_DIR}}/techmap.v; opt

    dffunmap
    dfflibmap -liberty {{YOSYS_DIR}}/fde_dc.lib
    dffinit 
    # dffinit -ff DFFNHQ Q INIT -ff DFFHQ Q INIT -ff EDFFHQ Q INIT -ff DFFRHQ Q INIT -ff DFFSHQ Q INIT -ff DFFNRHQ Q INIT -ff DFFNSHQ Q INIT
    wreduce; clean

    check
    abc9 -lut 4 -liberty {{YOSYS_DIR}}/fde_dc.lib; opt
    wreduce; clean
    # Clean up yosys internal cells that weren't mapped
    # delete -force \sdff \sdffe
    # select -module top
    # opt
    techmap -map {{YOSYS_DIR}}/cells_map.v; opt
    techmap; opt

    stat
    write_edif build/{{file_stem(file)}}.edf
    "

map file=INPUT_FILE:
    #!/bin/bash
    {{FDE_CLI}}/map \
        -i build/{{file_stem(file)}}.edf \
        -o build/{{file_stem(file)}}_map.xml \
        -c {{HW_LIB}}/dc_cell.xml \
        -y \
        -e

pack file=INPUT_FILE:
    #!/bin/bash
    {{FDE_CLI}}/pack \
        -c fdp3 \
        -n build/{{file_stem(file)}}_map.xml \
        -l {{HW_LIB}}/fdp3_cell.xml \
        -r {{HW_LIB}}/fdp3_dcplib.xml \
        -o build/{{file_stem(file)}}_pack.xml \
        -g {{HW_LIB}}/fdp3_config.xml \
        -e

place file=INPUT_FILE:
    #!/bin/bash
    {{FDE_CLI}}/place \
        -i build/{{file_stem(file)}}_pack.xml \
        -o build/{{file_stem(file)}}_place.xml \
        -a {{HW_LIB}}/fdp3p7_arch.xml \
        -c build/{{file_stem(file)}}_cons.xml \
        -l high

route file=INPUT_FILE:
    #!/bin/bash
    {{FDE_CLI}}/route \
        -n build/{{file_stem(file)}}_place.xml \
        -a {{HW_LIB}}/fdp3p7_arch.xml \
        -c build/{{file_stem(file)}}_cons.xml \
        -o build/{{file_stem(file)}}_route.xml

bitgen file=INPUT_FILE:
    #!/bin/bash
    {{FDE_CLI}}/bitgen \
        -n build/{{file_stem(file)}}_route.xml \
        -a {{HW_LIB}}/fdp3p7_arch.xml \
        -c {{HW_LIB}}/fdp3p7_cil.xml \
        -b build/{{file_stem(file)}}.bit

impl file=INPUT_FILE: synth
    #!/bin/bash
    # just synth {{file}}
    just pins {{file}}
    just map {{file}}
    just pack {{file}}
    just place {{file}}
    just route {{file}}
    just bitgen {{file}}
    echo "Build complete: build/{{file_stem(file)}}.bit"

pins file=INPUT_FILE:
    cd tools/verilog_parser && uv run parser.py ../../src/{{file}} -m ../../{{PIN_CONFIG}} -M "{{TOP}}" -o ../../build/{{file_stem(file)}}_cons.xml

verilator file=INPUT_FILE:
    #!/bin/bash
    set -e
    INPUT_FILE="{{file}}"
    TB_FILE="tb_${INPUT_FILE}"
    VMODULE=$(basename "$INPUT_FILE" .sv)
    
    rm -rf build/obj_dir
    mkdir -p build
    cd build
    {{verilator_BIN}} --cc "$INPUT_FILE" "$TB_FILE" \
        -I../src \
        --timing \
        --trace \
        --trace-fst \
        --trace-structs \
        --trace-underscore \
        --build \
        --binary \
        -j 0 \
        -CFLAGS -O0

execute file=INPUT_FILE:
    #!/bin/bash
    set -e
    INPUT_FILE="{{file}}"
    VMODULE=$(basename "$INPUT_FILE" .sv)
    
    cd build/obj_dir && ./V"$VMODULE" --trace waveform.fst
    echo "Output FST: build/obj_dir/waveform.fst"

sim file=INPUT_FILE:
    just verilator {{file}} 
    just execute {{file}} 

view:
    {{surfer_BIN}} build/obj_dir/waveform.fst

upload: impl
    cd fde-prog && {{cargo_BIN}} run 

# clean:
# rm -rf build/*
