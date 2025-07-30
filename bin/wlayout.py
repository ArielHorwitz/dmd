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
ARGUMENTS_SEPARATOR = "#>> END OF ARGUMENTS"
EXAMPLE_CONFIG_TOML = f"""
# wlayout example config file

[[argument]]
name = "dir-path"
default = "."

[[argument]]
name = "title"
default = "wlayout"

[[argument]]
name = "terminal-monitor"
default = "eDP-1"

{ARGUMENTS_SEPARATOR}

# [[command]]
# All fields are optional
# command = ["list", "of", "strings"]
# enabled = bool
# order = number
# focus_window = bool
# wait_focus_seconds = number
# monitor = "string"
# fullscreen = bool
# wait_complete = bool
# pause_seconds = number

[[command]]
# Directory contents
command = [
    "alacritty", "--hold",
    "--title", "$title$",
    "--command", "bash", "-c", "ls -la $dir-path$"
]
monitor = "$terminal-monitor$"
focus_window = true

[[command]]
command = ["bash", "-c", "sleep 1"]
focus_window = false
wait_complete = true

[[command]]
# Editor
command = ["lite-xl", "$dir-path$"]
focus_window = true
monitor = "eDP-1"
fullscreen = true
pause_seconds = 0.5

[[command]]
command = ["notify-send", "Layout complete"]
""".strip()
DEFAULT_WAIT_FOCUS_SECONDS = 5


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


def focus_pid_window(process, verbose, max_wait_seconds=5):
    pid = process.pid
    sleep_time_seconds = 0.05
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
    command = command_details.get("command")
    monitor = command_details.get("monitor")
    fullscreen = command_details.get("fullscreen")
    focus_window = command_details.get("focus_window")
    wait_focus_seconds = command_details.get(
        "wait_focus_seconds",
        DEFAULT_WAIT_FOCUS_SECONDS,
    )
    pause_seconds = command_details.get("pause_seconds")
    wait_complete = command_details.get("wait_complete")
    if verbose:
        print(command)
    if monitor:
        subprocess.run(
            ["hyprctl", "dispatch", "focusmonitor", monitor],
            capture_output=True,
            check=True,
        )
    if command:
        process = subprocess.Popen(command)
        pid = process.pid
        if verbose:
            print(f"PID: {pid}")
        else:
            print(pid)
        if focus_window:
            try:
                focus_pid_window(process, verbose, wait_focus_seconds)
            except Exception as e:
                print(f"Error focusing window: {e!r}")
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
    if command and wait_complete:
        process.wait()
    if pause_seconds:
        time.sleep(pause_seconds)


def resolve_user_arguments(arg_spec, user_args, verbose):
    arg_spec = tomllib.loads(arg_spec)
    args = {
        a["name"]: a.get("default")
        for a in arg_spec.get("argument", [])
    }
    if not args:
        if verbose:
            print("No arguments found")
        return args
    if verbose:
        print(f"Defaults: {args}")
    current_arg_name = None
    for uarg in user_args:
        if uarg.startswith("--") and current_arg_name is None:
            current_arg_name = uarg.removeprefix("--")
            if verbose:
                print(f"Parsing argument {current_arg_name!r}")
            if current_arg_name not in args:
                raise ValueError(f"Unknown argument name {current_arg_name!r}")
            continue
        elif current_arg_name and current_arg_name is not None:
            args[current_arg_name] = uarg
            if verbose:
                print(f"Value of {current_arg_name!r}: {uarg!r}")
            current_arg_name = None
            continue
        else:
            raise ValueError(f"Unknown argument given {uarg!r}")
    for name, value in args.items():
        if value is None:
            raise ValueError(f"Missing value for argument without default {name!r}")
    return args


def main():
    config_home = os.getenv("XDG_CONFIG_HOME", str(Path.home() / ".config"))
    parser = argparse.ArgumentParser(TITLE, description=DESCRIPTION)
    parser.add_argument(
        "-c",
        "--config-name",
        help=f"Config file name (shortcut for --config-file {config_home}/{TITLE}/<NAME>.toml)",
    )
    parser.add_argument(
        "-C",
        "--config-file",
        help="Config file path",
    )
    parser.add_argument(
        "--example",
        action="store_true",
        help="Print an example config and exit",
    )
    parser.add_argument(
        "--debug",
        choices=["args", "config", "parsed", "execution"],
        help="Print detailed info for debugging",
    )
    args, user_args = parser.parse_known_args()
    verbose = args.debug is not None
    if args.example:
        print(EXAMPLE_CONFIG_TOML)
        exit()
    if verbose:
        print(f"User arguments: {user_args}")
    if args.config_name == "EXAMPLE":
        config_name = "<EXAMPLE>"
        config_text = EXAMPLE_CONFIG_TOML
    elif args.config_name:
        config_path = Path(config_home) / TITLE / f"{args.config_name}.toml"
        config_name = str(config_path)
        if verbose:
            print(f"Reading config from {config_path}")
        config_text = config_path.read_text()
    elif args.config_file:
        config_name = str(args.config_file)
        if verbose:
            print(f"Reading config from {args.config_file}")
        config_text = Path(args.config_file).read_text()
    else:
        config_name = "<stdin>"
        if verbose:
            print("Reading config from stdin")
        config_text = sys.stdin.read()

    if ARGUMENTS_SEPARATOR in config_text:
        arg_spec, config_text = config_text.split(ARGUMENTS_SEPARATOR, 1)
        resolved_user_args = resolve_user_arguments(arg_spec, user_args, verbose)
        if args.debug == "args":
            print(resolved_user_args)
            exit()
        for uname, uvalue in resolved_user_args.items():
            config_text = config_text.replace(f"${uname}$", uvalue)
    else:
        if verbose:
            print("No argument separator found")

    if args.debug == "config":
        print(config_text)
        exit()
    config = tomllib.loads(config_text)
    if args.debug == "parsed":
        print(config["command"])
        exit()
    if verbose:
        print(f"Config: {config_name}")
    sorted_commands = sorted(
        enumerate(config["command"]),
        key=lambda i_w: i_w[1].get("order", 100 + i_w[0]),
    )
    commands = [w for (i, w) in sorted_commands]
    for command_details in commands:
        run_command(command_details, verbose)


if __name__ == "__main__":
    main()
