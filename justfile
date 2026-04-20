YOSYS_BIN := require("yosys")
verilator_BIN := require("verilator")
surfer_BIN := require("surfer")
cargo_BIN := require("cargo")
uv_BIN := require("uv")
FDE_CLI := "../FDE-Source/output"
# FDE_CLI := "tools/bin"
HW_LIB := "fde/hw_lib"

export TOP := env("TOP", "vl6180x")
export FREQ := env("FREQ", "100")
export TESTBENCH := env("TESTBENCH", "tb_" + TOP)
export SRC_PATH := env("SRC_PATH", "src/" + TOP)
export BITSTREAM := env("BITSTREAM", "build/" + TOP + "/06-output.bit")
export PIN_MAP:= env("PIN_MAP", "build/" + TOP + "/" + TOP + "_cons.xml")

INPUT_FILE := TOP + ".sv"
TESTBENCH_FILE := TESTBENCH + ".sv"
YOSYS_DIR := "yosys-fde"
PIN_CONFIG := "VERICOMM_MAP.json"

default:
    @just --list

synth file=INPUT_FILE:
    #!/bin/bash
    set -e
    mkdir -p build/{{TOP}}

    {{YOSYS_BIN}} -p "

    plugin -i yosys-slang/build/slang.so

    # read_verilog -sv -Isrc -top {{TOP}} {{SRC_PATH}}/*.sv 
    read_slang -Isrc -top {{TOP}} {{SRC_PATH}}/*.sv 

    hierarchy -check -top {{TOP}}

    proc; flatten -noscopeinfo;

    tribuf
    # tribuf -logic 

    # opt_clean
    memory -nomap
    memory_libmap -lib {{YOSYS_DIR}}/brams.txt; opt;
    techmap -map {{YOSYS_DIR}}/brams_map.v; opt;
    memory_map
    opt

    opt -fast
    opt -full

    fsm; opt;

    techmap -map {{YOSYS_DIR}}/techmap.v; opt
    simplemap

    dfflegalize  -cell \$_DFF_N_ 01 -cell \$_DFF_P_ 01 -cell \$_DFFE_PP_ 01 -cell \$_DFFE_PN_ 01 -cell \$_DFF_PN0_ r -cell \$_DFF_PN1_ r -cell \$_DFF_PP0_ r -cell \$_DFF_PP1_ r -cell \$_DFF_NN0_ r -cell \$_DFF_NN1_ r -cell \$_DFF_NP0_ r -cell \$_DFF_NP1_ r

    techmap -D NO_LUT -map {{YOSYS_DIR}}/cells_map.v; opt

    wreduce; clean

    dffinit -ff DFFNHQ Q INIT -ff DFFHQ Q INIT -ff EDFFHQ Q INIT -ff DFFRHQ Q INIT -ff DFFSHQ Q INIT -ff DFFNRHQ Q INIT -ff DFFNSHQ Q INIT

    wreduce; clean
    check
    
    abc9 -lut 4; opt
    wreduce; clean

    maccmap -unmap
    techmap
    simplemap; opt

    wreduce clean

    abc9 -lut 4; opt

    wreduce clean

    techmap -map {{YOSYS_DIR}}/cells_map.v; opt

    opt; check;

    iopadmap -bits -toutpad OBUFT T:I:O -tinoutpad IOBUF T:O:I:IO 
    # iopadmap -bits -outpad OBUF I:O -inpad IBUF O:I -toutpad OBUFT T:I:O -tinoutpad IOBUF T:O:I:IO 

    stat
    portlist

    # show

    write_edif build/{{TOP}}/{{file_stem(file)}}.edf
    write_verilog -noexpr build/{{TOP}}/{{file_stem(file)}}_post.v
    "

impl file=INPUT_FILE: 
    just pins 
    # FIXME
    {{cargo_BIN}} run --release --bin fde --manifest-path ../fde-rs/Cargo.toml -- impl  --input build/{{TOP}}/{{TOP}}.edf  --constraints build/{{TOP}}/{{TOP}}_cons.xml  --resource-root fde/hw_lib  --out-dir build/{{TOP}}

impl_old file=INPUT_FILE:
    just pins 
    {{FDE_CLI}}/map \
        -i build/{{TOP}}/{{TOP}}.edf \
        -o build/{{TOP}}/{{TOP}}_map.xml \
        -c fde/hw_lib/dc_cell.xml \
        -y \
        -e
    {{FDE_CLI}}/pack \
        -c fdp3 \
        -n build/{{TOP}}/{{TOP}}_map.xml \
        -l fde/hw_lib/fdp3_cell.xml \
        -r fde/hw_lib/fdp3_dcplib.xml \
        -o build/{{TOP}}/{{TOP}}_pack.xml \
        -g fde/hw_lib/fdp3_config.xml \
        -e
    {{FDE_CLI}}/place \
        -i build/{{TOP}}/{{TOP}}_pack.xml \
        -o build/{{TOP}}/{{TOP}}_place.xml \
        -a fde/hw_lib/fdp3p7_arch.xml \
        -c build/{{TOP}}/{{TOP}}_cons.xml \
        -l high
    {{FDE_CLI}}/route \
        -n build/{{TOP}}/{{TOP}}_place.xml \
        -a fde/hw_lib/fdp3p7_arch.xml \
        -c build/{{TOP}}/{{TOP}}_cons.xml \
        -o build/{{TOP}}/{{TOP}}_route.xml
    {{FDE_CLI}}/bitgen \
        -n build/{{TOP}}/{{TOP}}_route.xml \
        -a fde/hw_lib/fdp3p7_arch.xml \
        -c fde/hw_lib/fdp3p7_cil.xml \
        -b build/{{TOP}}/{{TOP}}.bit


pins file=INPUT_FILE:
    cd tools/verilog_parser && {{uv_BIN}} run parser.py ../../{{SRC_PATH}}/{{file}} -m ../../{{PIN_CONFIG}} -M "{{TOP}}" -o ../../build/{{TOP}}/{{TOP}}_cons.xml
    cat build/{{TOP}}/{{TOP}}_cons.xml

verilator file=INPUT_FILE additional_verilog="":
    mkdir -p build/{{TOP}}
    
    {{verilator_BIN}} --cc {{TESTBENCH_FILE}} {{additional_verilog}} \
        -Isrc \
        -I{{SRC_PATH}} \
        -I{{SRC_PATH}}/tb \
        --timing \
        --trace \
        --trace-fst \
        --trace-structs \
        --trace-underscore \
        --top-module tb_{{TOP}} \
        --Mdir build/{{TOP}} \
        --build \
        --binary \
        -Wno-fatal \
        -j 0 \
        -CFLAGS -O0

execute file=INPUT_FILE:
    cd build/{{TOP}} && ./Vtb_{{TOP}} --trace waveform.fst

sim file=INPUT_FILE:
    just verilator {{file}} {{YOSYS_DIR}}/fdesimlib.v
    just execute {{file}} 

post_sim file=INPUT_FILE:
    mkdir -p build/{{TOP}}
    {{verilator_BIN}} --cc {{SRC_PATH}}/tb_{{TOP}}_post.sv \
        build/{{TOP}}/{{TOP}}_post.v \
        {{YOSYS_DIR}}/fdesimlib.v \
        -Isrc \
        -I{{SRC_PATH}} \
        --timing \
        --trace \
        --trace-fst \
        --trace-structs \
        --trace-underscore \
        --top-module tb_{{TOP}}_post \
        --Mdir build/{{TOP}} \
        --build \
        --binary \
        -Wno-fatal \
        -j 0 \
        -CFLAGS -O0
    cd build/{{TOP}} && ./Vtb_{{TOP}}_post --trace waveform.fst

view_routes file=INPUT_FILE:
    {{FDE_CLI}}/FDE -a ./fde/hw_lib/fdp3p7_arch.xml -d build/{{TOP}}/05-timed.xml

view_wave:
    {{surfer_BIN}} build/{{TOP}}/waveform.fst

upload: 
    {{cargo_BIN}} run --bin sw_interface

upload_old: 
    BITSTREAM="build/{{TOP}}/{{TOP}}.bit" {{cargo_BIN}} run --bin sw_interface

clean:
    cargo clean
    rm -rf build/*
