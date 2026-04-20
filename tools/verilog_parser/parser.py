#!/usr/bin/env python3
import argparse
import json
import re
import sys
from pathlib import Path


PIN_ATTR_RE = re.compile(r'\(\*\s*(\w+)\s*=\s*["\']([^"\']*)["\']\s*\*\)')
CLK_NAMES = {"clk", "clock", "clk_in", "clock_in", "clk_i", "clock_i"}
REGION_PINS = {"j7", "j8", "led", "switch", "button"}


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

    port_attrs = {name: {} for name in port_names}

    for match in re.finditer(r'\(\*\s*(?:pin|ioa)\s*=\s*"([^"]+)"\s*\*\)', port_decl):
        pin_value = match.group(1)
        after_attr = port_decl[match.end() :]
        for name in port_names:
            if name in after_attr:
                port_attrs[name] = {"pin": pin_value}
                break

    return port_attrs


def unescape_sv_name(name):
    if name and name.startswith("\\") and not name.startswith("\\\\"):
        return name[1:]
    return name


def extract_module_names_and_ports(filepath):
    with open(filepath, "r") as f:
        content = f.read()

    content = re.sub(r"//.*?$", "", content, flags=re.MULTILINE)
    content = re.sub(r"/\*.*?\*/", "", content, flags=re.DOTALL)

    modules = {}
    module_pattern = re.compile(r"module\s+(\.?|\w+)\s*(?:#\([^)]*\))?\s*\(", re.DOTALL)

    for m in module_pattern.finditer(content):
        full_name = m.group(1)
        name = unescape_sv_name(full_name)

        start = m.end()
        port_end = content.find(");", start)
        port_decl = content[start:port_end]

        port_attrs = {}
        for match in re.finditer(
            r'\(\*\s*(?:pin|ioa|region|led|switch|button)\s*=\s*"([^"]+)"\s*\*\)',
            port_decl,
        ):
            full_match = match.group(0)
            attr_val = match.group(1)
            match_end_pos = match.end()
            after = port_decl[match_end_pos:]
            for word in re.finditer(r"\b([a-zA-Z_]\w*)\b", after):
                w = word.group(1)
                if w not in ("input", "output", "inout", "reg", "logic", "wire", "tri"):
                    if w not in port_attrs:
                        port_attrs[w] = {}
                    if "pin" in full_match:
                        port_attrs[w]["pin"] = attr_val
                    elif "region" in full_match:
                        port_attrs[w]["region"] = attr_val
                    elif (
                        "led" in full_match
                        or "switch" in full_match
                        or "button" in full_match
                    ):
                        region_name = re.search(
                            r"(led|switch|button)", full_match
                        ).group(1)
                        port_attrs[w]["region"] = attr_val
                        port_attrs[w]["region_type"] = region_name
                    break
        port_decl_clean = re.sub(
            r'\(\*\s*(?:pin|ioa|region|led|switch|button)\s*=\s*"[^"]+"\s*\*\)',
            "",
            port_decl,
        )

        lines = port_decl_clean.split(",")

        ports = []
        for line in lines:
            line = line.strip()
            if not line or (
                "input" not in line and "output" not in line and "inout" not in line
            ):
                continue
            width = 1
            wm = re.search(r"\[(\d+):(\d+)\]", line)
            if wm:
                width = int(wm.group(1)) - int(wm.group(2)) + 1

            tokens = line.split()
            port_name = tokens[-1] if tokens else None
            if line.startswith("input"):
                direction = "input"
            elif line.startswith("output") or line.startswith("output reg"):
                direction = "output"
            elif line.startswith("inout"):
                direction = "inout"
            else:
                continue
            if port_name:
                port_entry = {"name": port_name, "direction": direction, "width": width}
                if port_name in port_attrs:
                    if "pin" in port_attrs[port_name]:
                        port_entry["assigned_pin"] = port_attrs[port_name]["pin"]
                    if "region" in port_attrs[port_name]:
                        port_entry["assigned_region"] = port_attrs[port_name]["region"]
                    if "region_type" in port_attrs[port_name]:
                        port_entry["assigned_region_type"] = port_attrs[port_name][
                            "region_type"
                        ]
                ports.append(port_entry)

        if ports:
            modules[name] = ports

    return modules


def parse_pins_from_file(filepath):
    raw_modules = extract_module_names_and_ports(filepath)

    modules = {}
    for name, ports in raw_modules.items():
        parsed_ports = []
        for port in ports:
            parsed_ports.append(
                {
                    "name": port["name"],
                    "direction": port["direction"],
                    "assigned_pin": port.get("assigned_pin"),
                    "assigned_region": port.get("assigned_region"),
                    "assigned_region_type": port.get("assigned_region_type"),
                    "width": port["width"],
                }
            )
        modules[name] = parsed_ports

    return modules


def load_pin_map(map_path):
    with open(map_path) as f:
        data = json.load(f)

    if "input" in data and "output" in data:
        if "inout" not in data:
            data["inout"] = {}
        return data

    for board in data.values():
        if isinstance(board, dict) and "pins" in board:
            pins = board["pins"]
            input_pins = {}
            output_pins = {}
            inout_pins = {}
            for p, info in pins.items():
                if info.get("type") == "input":
                    input_pins[p] = info
                elif info.get("type") == "output":
                    output_pins[p] = info
                elif info.get("type") == "inout":
                    inout_pins[p] = info
            return {"input": input_pins, "output": output_pins, "inout": inout_pins}

    return {"input": {}, "output": {}, "inout": {}}


def auto_assign_pins(ports, pin_map, clock_pin="P77", region_pins=None):
    if region_pins is None:
        region_pins = {"j7", "j8", "led", "switch", "button"}

    input_pins = pin_map.get("input", {})
    output_pins = pin_map.get("output", {})
    inout_pins = pin_map.get("inout", {})

    input_pin_order = list(input_pins.keys())
    output_pin_order = list(output_pins.keys())

    input_idx = 0
    output_idx = 0

    assigned = []
    region_indices = {region: 0 for region in region_pins}
    used_pins = set()

    for port in ports:
        name = port["name"]
        direction = port["direction"]
        assigned_pin = port.get("assigned_pin")
        assigned_region = port.get("assigned_region")
        assigned_region_type = port.get("assigned_region_type")
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
                                "direction": direction,
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
                                "direction": direction,
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
                        "direction": direction,
                        "auto": False,
                        "index": 0,
                        "width": width,
                    }
                )
                used_pins.add(assigned_pin)
            continue

        is_clock = name.lower() in CLK_NAMES

        if direction == "inout":
            assigned_pin = port.get("assigned_pin")
            if not assigned_pin:
                print(
                    f"Error: inout port '{name}' requires explicit pin assignment",
                    file=sys.stderr,
                )
                sys.exit(1)
            pin_list = [p.strip() for p in assigned_pin.split(",")]
            pin_list = [p if p.startswith("P") else f"P{p}" for p in pin_list]
            if len(pin_list) < width:
                print(
                    f"Error: inout port '{name}' needs {width} pins, got {len(pin_list)}",
                    file=sys.stderr,
                )
                sys.exit(1)
            assigned.append(
                {
                    "name": name,
                    "pin": assigned_pin,
                    "direction": direction,
                    "auto": False,
                    "index": 0,
                    "width": width,
                }
            )
            for p in pin_list:
                used_pins.add(p)
            continue
        elif is_clock and direction == "input":
            assigned.append(
                {
                    "name": name,
                    "pin": clock_pin,
                    "direction": direction,
                    "auto": True,
                    "index": 0,
                    "width": width,
                }
            )
            used_pins.add(clock_pin)
        elif assigned_region_type in ("led", "switch", "button"):
            region_items = pin_map.get(assigned_region_type, {})
            if assigned_region in region_items:
                pin = region_items[assigned_region]
                assigned.append(
                    {
                        "name": name,
                        "pin": pin,
                        "direction": direction,
                        "auto": False,
                        "index": 0,
                        "width": width,
                    }
                )
                used_pins.add(pin)
        elif assigned_region and assigned_region in pin_map:
            region_map = pin_map[assigned_region]
            region_pins_list = sorted(region_map.keys(), key=lambda x: region_map[x])
            for i in range(width):
                while region_indices[assigned_region] < len(region_pins_list):
                    pin = region_pins_list[region_indices[assigned_region]]
                    region_indices[assigned_region] += 1
                    if pin not in used_pins:
                        assigned.append(
                            {
                                "name": name,
                                "pin": pin,
                                "direction": direction,
                                "auto": True,
                                "index": i,
                                "width": width,
                            }
                        )
                        used_pins.add(pin)
                        break
                else:
                    break
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
                                "direction": direction,
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
                                "direction": direction,
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


def generate_xml(module_name, assigned_pins, pin_map):
    lines = [f'<design name="{module_name}">']
    input_pins = pin_map.get("input", {})
    input_pins = pin_map.get("input", {})
    output_pins = pin_map.get("output", {})
    inout_pins = pin_map.get("inout", {})
    region_pins = {}
    for region in ["j7", "j8", "led", "switch", "button"]:
        if region in pin_map:
            region_pins.update(pin_map[region])
    done_inout = set()
    for port in assigned_pins:
        name = port["name"]
        index = port.get("index", 0)
        width = port.get("width", 1)
        pin = port["pin"]
        direction = port.get("direction", "")
        is_auto = port.get("auto", True)
        key_inout = f"{name}:auto:{is_auto}"
        if not is_auto and "," in pin:
            if key_inout in done_inout:
                continue
            done_inout.add(key_inout)
            pin_list = [p.strip() for p in pin.split(",")]
            pin_list = [p if p.startswith("P") else f"P{p}" for p in pin_list]
            for i, p in enumerate(pin_list[:width]):
                lines.append(
                    f'  <port name="{name}[{i}]" position="{p}" absolute_position="" type="inout"/>'
                )
            continue
        if pin in input_pins:
            abs_pos = input_pins[pin]
            pin_type = "input"
            if width > 1:
                lines.append(
                    f'  <port name="{name}[{index}]" position="{pin}" absolute_position="{abs_pos}" type="{pin_type}"/>'
                )
            else:
                lines.append(
                    f'  <port name="{name}" position="{pin}" absolute_position="{abs_pos}" type="{pin_type}"/>'
                )
        elif pin in output_pins:
            abs_pos = output_pins[pin]
            pin_type = "output"
            if width > 1:
                lines.append(
                    f'  <port name="{name}[{index}]" position="{pin}" absolute_position="{abs_pos}" type="{pin_type}"/>'
                )
            else:
                lines.append(
                    f'  <port name="{name}" position="{pin}" absolute_position="{abs_pos}" type="{pin_type}"/>'
                )
        elif pin in inout_pins:
            abs_pos = inout_pins[pin]
            pin_type = "inout"
            if width > 1:
                lines.append(
                    f'  <port name="{name}[{index}]" position="{pin}" absolute_position="{abs_pos}" type="{pin_type}"/>'
                )
            else:
                lines.append(
                    f'  <port name="{name}" position="{pin}" absolute_position="{abs_pos}" type="{pin_type}"/>'
                )
        elif pin in region_pins:
            abs_pos = ""
            pin_type = direction
            if width > 1:
                lines.append(
                    f'  <port name="{name}[{index}]" position="{pin}" absolute_position="{abs_pos}" type="{pin_type}"/>'
                )
            else:
                lines.append(
                    f'  <port name="{name}" position="{pin}" absolute_position="{abs_pos}" type="{pin_type}"/>'
                )
        else:
            abs_pos = ""
            pin_type = ""
            if width > 1:
                lines.append(
                    f'  <port name="{name}[{index}]" position="{pin}" absolute_position="{abs_pos}" type="{pin_type}"/>'
                )
            else:
                lines.append(
                    f'  <port name="{name}" position="{pin}" absolute_position="{abs_pos}" type="{pin_type}"/>'
                )
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
    xml = generate_xml(module_name, assigned, pin_map)

    if args.output:
        with open(args.output, "w") as f:
            f.write(xml)
        print(f"Wrote constraints to {args.output}")
    else:
        print(xml)


if __name__ == "__main__":
    main()
