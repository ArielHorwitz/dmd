#! /bin/python

import argparse
import json
import subprocess
import sys
import time
import tomllib
from pathlib import Path

DEFAULT_CONFIG = Path.home() / ".config" / "dmd" / "locations.toml"
DEFAULT_STATE_FILE = Path.home() / ".local" / "state" / "dmd" / "location"
DEFAULT_KEY = "__default__"


def load_config(config_path: Path) -> dict:
    return tomllib.loads(config_path.read_text())


def read_location(state_file: Path) -> str:
    if state_file.is_file():
        return state_file.read_text().strip()
    return ""


def get_icon(config: dict, location: str) -> str:
    key = location if location in config else DEFAULT_KEY
    return config.get(key, {}).get("icon", config.get(DEFAULT_KEY, {}).get("icon", "?"))


def format_waybar(icon: str, location: str) -> str:
    css_class = location or "none"
    tooltip = location or "none"
    return json.dumps({"text": f"{icon} ", "class": css_class, "tooltip": tooltip})


def main():
    parser = argparse.ArgumentParser(
        prog="location-status",
        description="Show current detected location",
    )
    parser.add_argument(
        "-c", "--config",
        type=Path,
        default=DEFAULT_CONFIG,
        help="Path to locations config file",
    )
    parser.add_argument(
        "-s", "--state-file",
        type=Path,
        default=DEFAULT_STATE_FILE,
        help="Path to location state file",
    )
    parser.add_argument("-n", "--notify", action="store_true", help="Send a notification")
    parser.add_argument("-j", "--json", action="store_true", help="Output waybar JSON")
    parser.add_argument("-w", "--watch", type=float, help="Continuously print on interval in seconds")
    args = parser.parse_args()

    config = load_config(args.config)

    def print_location():
        location = read_location(args.state_file)
        icon = get_icon(config, location)
        if args.json:
            print(format_waybar(icon, location), flush=True)
        else:
            print(f"{icon} {location or '(none)'}")

    if args.watch is not None:
        while True:
            print_location()
            time.sleep(args.watch)
        return

    location = read_location(args.state_file)
    if args.notify:
        subprocess.run([
            "notify-send",
            "-h", "string:synchronous:location-status",
            "Location",
            location or "(none)",
        ])
    print_location()


if __name__ == "__main__":
    main()
