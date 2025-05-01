#! /bin/python

import argparse
import json
import subprocess
import os
import sys
import time
from pathlib import Path

if sys.version_info >= (3, 12):
    import tomllib
else:
    import tomli as tomllib

TITLE = "wlayout"
DESCRIPTION = "Spawn commands and configure their layout in hyprland. Uses config provided by stdin or by arguments."
EXAMPLE_CONFIG_TOML = """
# wlayout example config file

[[arguments.required]]
placeholder = "$dir_path$"

[[arguments.optional]]
placeholder = "$title$"
default = "Default title"

[[arguments.optional]]
placeholder = "$terminal_monitor$"
default = "eDP-1"

# [[command]]
# Only the command is required, everything else is optional
# command = ["list", "of", "strings"]
# enabled = bool
# order = number
# focus_window = bool
# monitor = "string"
# fullscreen = bool
# wait_complete = bool
# pause_seconds = number

[[command]]
# Directory contents
command = [
    "alacritty", "--hold",
    "--title", "$title$",
    "--command", "bash", "-c", "ls -la $dir_path$"
]
monitor = "$terminal_monitor$"
focus_window = true

[[command]]
command = ["bash", "-c", "sleep 1"]
focus_window = false
wait_complete = true

[[command]]
# Editor
command = ["lite-xl", "$dir_path$"]
focus_window = true
monitor = "eDP-1"
fullscreen = true
pause_seconds = 0.5

[[command]]
command = ["notify-send", "Layout complete"]
""".strip()


def get_hyprland_json(*args):
    result = subprocess.run(
        ["hyprctl", "-j", *args],
        capture_output=True,
        check=True,
    )
    if result.stderr:
        raise RuntimeError(result.stderr.decode())
    return json.loads(result.stdout.decode())


def focus_window(pid, verbose):
    result = subprocess.run(
        ["hyprctl", "focuswindow", f"pid:{pid}"],
        capture_output=True,
        check=True,
    )
    if result.stderr:
        raise RuntimeError(result.stderr.decode())
    if verbose:
        print(f"Focused {pid}: {result.stdout.decode()}")


def get_window_details(pid=None):
    clients = get_hyprland_json("clients")
    if pid is None:
        ws = get_hyprland_json("activeworkspace")
        return [c for c in clients if c["workspace"]["id"] == ws["id"]]
    for client in clients:
        if client["pid"] == pid:
            return client
    return None


def focus_pid_window(process, verbose):
    pid = process.pid
    sleep_time_seconds = 0.05
    max_wait_seconds = 2
    max_iterations = int(max_wait_seconds / sleep_time_seconds)
    for _ in range(max_iterations):
        time.sleep(sleep_time_seconds)
        return_code = process.poll()
        if return_code is not None:
            raise RuntimeError(
                f"Process closed without a window. Return code: {return_code}"
            )
        if get_hyprland_json("activewindow").get("pid") == pid:
            return
        if get_window_details(pid) is not None:
            focus_window(pid, verbose)
    raise RuntimeError(f"Timed out waiting for window for PID {pid}")


def run_command(command_details, verbose):
    if not command_details.get("enabled", True):
        return
    command = command_details["command"]
    monitor = command_details.get("monitor")
    fullscreen = command_details.get("fullscreen")
    focus_window = command_details.get("focus_window")
    pause_seconds = command_details.get("pause_seconds")
    wait_complete = command_details.get("wait_complete")
    if verbose:
        print(command)
    process = subprocess.Popen(command)
    pid = process.pid
    if verbose:
        print(f"PID: {pid}")
    else:
        print(pid)
    if focus_window:
        focus_pid_window(process, verbose)
    if monitor:
        subprocess.run(
            ["hyprctl", "dispatch", "movewindow", f"mon:{monitor}"],
            capture_output=True,
            check=True,
        )
    if fullscreen:
        subprocess.run(
            ["hyprctl", "dispatch", "fullscreen", "2"],
            capture_output=True,
            check=True,
        )
    if wait_complete:
        process.wait()
    if pause_seconds:
        time.sleep(pause_seconds)


def replace_argument_placeholders(text, config, args):
    config_required = config.get("required", [])
    for required_index, arg in enumerate(config_required):
        placeholder = arg["placeholder"]
        if placeholder in text and len(args) <= required_index:
            raise ValueError(f"Missing argument for {placeholder}")
        text = text.replace(placeholder, args[required_index])
    config_optional = config.get("optional", [])
    for optional_index, arg in enumerate(config_optional):
        index = required_index + 1 + optional_index
        placeholder = arg["placeholder"]
        default = arg.get("default", placeholder)
        value = args[index] if len(args) > index else default
        text = text.replace(placeholder, value)
    return text


def main():
    parser = argparse.ArgumentParser(TITLE, description=DESCRIPTION)
    config_home = os.getenv("XDG_CONFIG_HOME", str(Path.home() / ".config"))
    parser.add_argument(
        "arguments",
        metavar="<PLACEHOLDERS>",
        nargs="*",
        help="Arguments for the config (used in placeholders)",
    )
    parser.add_argument(
        "-c",
        "--config-name",
        help=f"Config file name (in {config_home}/{TITLE})",
    )
    parser.add_argument(
        "-C",
        "--config-file",
        help="Config file path",
    )
    parser.add_argument(
        "--example",
        action="store_true",
        help="Print an example config",
    )
    parser.add_argument(
        "--debug-config",
        action="store_true",
        help="Print config after resolving placeholders",
    )
    parser.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        help="Print detailed information",
    )
    args = parser.parse_args()
    if args.example:
        print(EXAMPLE_CONFIG_TOML)
        exit()
    if args.config_name:
        config_path = Path(config_home) / TITLE / f"{args.config_name}.toml"
        config_name = str(config_path)
        if args.verbose:
            print(f"Reading config from {config_path}")
        config_text = config_path.read_text()
    elif args.config_file:
        config_name = str(args.config_file)
        if args.verbose:
            print(f"Reading config from {args.config_file}")
        config_text = Path(args.config_file).read_text()
    else:
        config_name = "<stdin>"
        if args.verbose:
            print("Reading config from stdin")
        config_text = sys.stdin.read()
    args_config = tomllib.loads(config_text).get("arguments")
    if args_config:
        config_text = replace_argument_placeholders(
            config_text,
            args_config,
            args.arguments,
        )
    if args.debug_config:
        print(config_text)
        exit()
    config = tomllib.loads(config_text)
    if args.verbose:
        print(f"Config: {config_name}")
    sorted_commands = sorted(
        enumerate(config["command"]),
        key=lambda i_w: i_w[1].get("order", 100 + i_w[0]),
    )
    commands = [w for (i, w) in sorted_commands]
    for command_details in commands:
        run_command(command_details, args.verbose)


if __name__ == "__main__":
    main()
