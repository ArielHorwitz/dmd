#! /bin/python

import argparse
import json
import os
import signal
import socket
import subprocess
import sys
import time
from pathlib import Path

import tomllib

DEFAULT_CONFIG = Path.home() / ".config" / "dmd" / "locations.toml"
DEFAULT_STATE_FILE = Path.home() / ".local" / "state" / "dmd" / "location"
DEFAULT_KEY = "__default__"
APP_NAME = "monitor-watchdog"


def load_config(config_path: Path) -> dict:
    return tomllib.loads(config_path.read_text())


def get_monitor_descriptions() -> list[str]:
    result = subprocess.run(
        ["hyprctl", "monitors", "-j"],
        capture_output=True,
        text=True,
    )
    monitors = json.loads(result.stdout)
    return [m["description"] for m in monitors]


def detect_location(config: dict) -> str:
    descriptions = get_monitor_descriptions()
    for name, location in config.items():
        if name == DEFAULT_KEY:
            continue
        for pattern in location.get("monitors", []):
            if any(pattern in desc for desc in descriptions):
                return name
    return ""


def write_location(config: dict, state_file: Path):
    detected = detect_location(config)
    current = state_file.read_text().strip() if state_file.is_file() else ""
    if detected == current:
        return
    print(f"Location changed: '{current}' -> '{detected}'")
    state_file.parent.mkdir(parents=True, exist_ok=True)
    state_file.write_text(detected)
    subprocess.run(
        [
            "notify-send",
            "-h",
            f"string:synchronous:{APP_NAME}",
            "Monitor Watchdog",
            f"Location: {detected or '(none)'}",
        ]
    )


def acquire_pidfile(pidfile: Path):
    if pidfile.is_file():
        old_pid = int(pidfile.read_text().strip())
        try:
            os.kill(old_pid, signal.SIGTERM)
            print(f"Killing existing {APP_NAME} (pid {old_pid})")
            time.sleep(0.5)
        except ProcessLookupError:
            pass
    pidfile.write_text(str(os.getpid()))


def listen_hyprland(config: dict, state_file: Path):
    instance_sig = os.environ["HYPRLAND_INSTANCE_SIGNATURE"]
    runtime_dir = os.environ["XDG_RUNTIME_DIR"]
    socket_path = f"{runtime_dir}/hypr/{instance_sig}/.socket2.sock"
    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    sock.connect(socket_path)
    buffer = ""
    while True:
        data = sock.recv(4096).decode()
        if not data:
            break
        buffer += data
        while "\n" in buffer:
            line, buffer = buffer.split("\n", 1)
            if line.startswith("monitoradded>>") or line.startswith("monitorremoved>>"):
                time.sleep(1)
                write_location(config, state_file)


def main():
    parser = argparse.ArgumentParser(
        prog=APP_NAME,
        description="Watch for monitor changes to detect location",
    )
    parser.add_argument(
        "-c",
        "--config",
        type=Path,
        default=DEFAULT_CONFIG,
        help="Path to locations config file",
    )
    parser.add_argument(
        "-s",
        "--state-file",
        type=Path,
        default=DEFAULT_STATE_FILE,
        help="Path to write location state",
    )
    args = parser.parse_args()

    if not args.config.is_file():
        print(f"Config file not found: {args.config}", file=sys.stderr)
        raise SystemExit(1)

    pidfile = Path(f"/tmp/{APP_NAME}.pid")
    acquire_pidfile(pidfile)
    try:
        config = load_config(args.config)
        location = detect_location(config)
        print(f"Started (location: {location or '(none)'})")
        subprocess.run(
            [
                "notify-send",
                "-h",
                f"string:synchronous:{APP_NAME}",
                "Monitor Watchdog started",
                f"Location: {location or '(none)'}",
            ]
        )
        args.state_file.parent.mkdir(parents=True, exist_ok=True)
        args.state_file.write_text(location)
        listen_hyprland(config, args.state_file)
    finally:
        pidfile.unlink(missing_ok=True)


if __name__ == "__main__":
    main()
