#!/usr/bin/env python3
import argparse
import json
import re
import sys
from pathlib import Path
from sv_simpleparser import parser as svp


PIN_ATTR_RE = re.compile(r'\(\*\s*(\w+)\s*=\s*["\']([^"\']*)["\']\s*\*\)')
CLK_NAMES = {"clk", "clock", "clk_in", "clock_in", "clk_i", "clock_i"}


def parse_port_dim(dim_str):
    if not dim_str:
        return 1
    match = re.search(r"\[(\d+):(\d+)\]", dim_str)
    if match:
        return int(match.group(1)) - int(match.group(2)) + 1
    return 1


def extract_attributes_from_file(filepath, port_names):
    with open(filepath, "r") as f:
        content = f.read()

    module_match = re.search(r"module\s+\w+\s*\((.*?)\);", content, re.DOTALL)
    if not module_match:
        return {name: {} for name in port_names}

    port_decl = module_match.group(1)
    lines = port_decl.split("\n")

    port_attrs = {name: {} for name in port_names}
    pending = {}

    for line in lines:
        for match in PIN_ATTR_RE.finditer(line):
            pending[match.group(1)] = match.group(2)
        for name in port_names:
            if name in line and pending:
                port_attrs[name] = pending
                pending = {}

    return port_attrs


def unescape_sv_name(name):
    if name and name.startswith("\\") and not name.startswith("\\\\"):
        return name[1:]
    return name


def extract_module_names_and_ports(filepath):
    with open(filepath, "r") as f:
        content = f.read()

    modules = {}
    module_pattern = re.compile(r"module\s+(\\.+?|\w+)\s*\(", re.DOTALL)

    for m in module_pattern.finditer(content):
        full_name = m.group(1)
        name = unescape_sv_name(full_name)

        start = m.end()
        port_end = content.find(");", start)
        port_decl = content[start:port_end]

        ports = []

        lines = port_decl.split(",")
        for line in lines:
            line = re.sub(r"\(\*.*?\*\)", "", line).strip()
            if not line or ("input" not in line and "output" not in line):
                continue
            width = 1
            wm = re.search(r"\[(\d+):(\d+)\]", line)
            if wm:
                width = int(wm.group(1)) - int(wm.group(2)) + 1

            tokens = line.split()
            port_name = tokens[-1] if tokens else None
            direction = "input" if line.startswith("input") else "output"
            if port_name:
                ports.append(
                    {"name": port_name, "direction": direction, "width": width}
                )

        if ports:
            modules[name] = ports

    return modules


def parse_pins_from_file(filepath):
    raw_modules = extract_module_names_and_ports(filepath)

    attrs_map = {}
    for port_name in set(p["name"] for ports in raw_modules.values() for p in ports):
        attrs_map[port_name] = {}

    modules = {}
    for name, ports in raw_modules.items():
        parsed_ports = []
        for port in ports:
            attrs = attrs_map.get(port["name"], {})
            parsed_ports.append(
                {
                    "name": port["name"],
                    "direction": port["direction"],
                    "assigned_pin": attrs.get("pin"),
                    "width": port["width"],
                }
            )
        modules[name] = parsed_ports

    return modules


def load_pin_map(map_path):
    with open(map_path) as f:
        data = json.load(f)

    if "input" in data and "output" in data:
        return data

    for board in data.values():
        if isinstance(board, dict) and "pins" in board:
            pins = board["pins"]
            input_pins = {}
            output_pins = {}
            for p, info in pins.items():
                if info.get("type") == "input":
                    input_pins[p] = info
                elif info.get("type") == "output":
                    output_pins[p] = info
            return {"input": input_pins, "output": output_pins}

    return {"input": {}, "output": {}}


def auto_assign_pins(ports, pin_map, clock_pin="P77"):
    input_pins = pin_map.get("input", {})
    output_pins = pin_map.get("output", {})

    input_pin_order = list(input_pins.keys())
    output_pin_order = list(output_pins.keys())

    input_idx = 0
    output_idx = 0
    used_pins = set()

    assigned = []
    for port in ports:
        name = port["name"]
        direction = port["direction"]
        assigned_pin = port.get("assigned_pin")
        width = port.get("width", 1)

        if assigned_pin:
            if width > 1:
                pin_base = assigned_pin.rstrip("0123456789")
                pin_num_start = re.search(r"(\d+)$", assigned_pin)
                if pin_num_start:
                    start_num = int(pin_num_start.group(1))
                    for i in range(width):
                        assigned.append(
                            {
                                "name": name,
                                "pin": f"{pin_base}{start_num + i}",
                                "auto": False,
                                "index": i,
                                "width": width,
                            }
                        )
                        used_pins.add(f"{pin_base}{start_num + i}")
                else:
                    for i in range(width):
                        assigned.append(
                            {
                                "name": name,
                                "pin": f"{assigned_pin}_{i}",
                                "auto": False,
                                "index": i,
                                "width": width,
                            }
                        )
                        used_pins.add(f"{assigned_pin}_{i}")
            else:
                assigned.append(
                    {
                        "name": name,
                        "pin": assigned_pin,
                        "auto": False,
                        "index": 0,
                        "width": width,
                    }
                )
                used_pins.add(assigned_pin)
            continue

        is_clock = name.lower() in CLK_NAMES

        if is_clock and direction == "input":
            assigned.append(
                {
                    "name": name,
                    "pin": clock_pin,
                    "auto": True,
                    "index": 0,
                    "width": width,
                }
            )
            used_pins.add(clock_pin)
        elif direction == "input":
            for i in range(width):
                while input_idx < len(input_pin_order):
                    pin = input_pin_order[input_idx]
                    input_idx += 1
                    if pin not in used_pins:
                        assigned.append(
                            {
                                "name": name,
                                "pin": pin,
                                "auto": True,
                                "index": i,
                                "width": width,
                            }
                        )
                        used_pins.add(pin)
                        break
                else:
                    break
        else:
            for i in range(width):
                while output_idx < len(output_pin_order):
                    pin = output_pin_order[output_idx]
                    output_idx += 1
                    if pin not in used_pins:
                        assigned.append(
                            {
                                "name": name,
                                "pin": pin,
                                "auto": True,
                                "index": i,
                                "width": width,
                            }
                        )
                        used_pins.add(pin)
                        break
                else:
                    break

    return assigned


def generate_xml(module_name, assigned_pins):
    lines = [f'<design name="{module_name}">']
    for port in assigned_pins:
        name = port["name"]
        pin = port["pin"]
        index = port.get("index", 0)
        width = port.get("width", 1)
        if width > 1:
            lines.append(f'  <port name="{name}[{index}]" position="{pin}"/>')
        else:
            lines.append(f'  <port name="{name}" position="{pin}"/>')
    lines.append("</design>")
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(
        description="Generate pin constraint XML from Verilog files"
    )
    parser.add_argument("verilog_file", help="Verilog/SystemVerilog source file")
    parser.add_argument(
        "-m", "--map", default="VERICOMM_MAP.json", help="Pin mapping JSON"
    )
    parser.add_argument("-o", "--output", help="Output XML file (default: stdout)")
    parser.add_argument("-c", "--clock", default="P77", help="Clock pin (default: P77)")
    parser.add_argument(
        "-M", "--module", help="Module name (default: first module found)"
    )
    parser.add_argument(
        "-l", "--list", action="store_true", help="List available modules and exit"
    )

    args = parser.parse_args()

    modules = parse_pins_from_file(args.verilog_file)

    if args.list:
        print("Available modules:")
        for name in modules:
            print(f"  {name}")
        sys.exit(0)

    if not modules:
        print(f"Error: No modules found in {args.verilog_file}", file=sys.stderr)
        sys.exit(1)

    pin_map = load_pin_map(args.map)

    module_name = args.module
    if not module_name:
        module_name = list(modules.keys())[0]

    ports = modules.get(module_name, [])
    if not ports:
        print(f"Error: Module {module_name} not found", file=sys.stderr)
        sys.exit(1)

    assigned = auto_assign_pins(ports, pin_map, clock_pin=args.clock)
    xml = generate_xml(module_name, assigned)

    if args.output:
        with open(args.output, "w") as f:
            f.write(xml)
        print(f"Wrote constraints to {args.output}")
    else:
        print(xml)


if __name__ == "__main__":
    main()
