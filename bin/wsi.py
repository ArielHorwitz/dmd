#! /bin/python

from dataclasses import dataclass, field
from time import sleep
from typing import Optional, Callable
import argparse
import json
import os
import random
import subprocess
import sys
from pathlib import Path
if sys.version_info >= (3, 12):
    import tomllib
else:
    import tomli as tomllib

ROWS = 3
COLUMNS = 4

NOTIFY_SEND = (
    "notify-send",
    "-u",
    "low",
    "-h",
    'string:synchronous:"wsi"',
)
WORKSPACE_EMPTY = ""
WORKSPACE_OCCUPIED = ""
WORKSPACE_VISIBLE = ""
WORKSPACE_FOCUS = ""
USER = os.getenv("USER")
CONFIG_DIR = Path(f"/home/{USER}/.config/wsi")
CONFIG_FILE = Path(f"{CONFIG_DIR}/config.toml")
DEFAULT_CONFIG_TOML = f"""
rows = 2
columns = 3
display_priorities = [
    "DP-1",
    "DP-2",
    "DP-3",
    "HDMI-1",
    "HDMI-2",
    "HDMI-3",
    "eDP-1",
]
notification_timeout = 1000
icon = "/usr/share/icons/dmd/monitor.svg"
""".strip()
HELP_TEXT = f"""Manage i3 workspaces.

Pass row and column to switch or move to a workspace.
Pass neither to print workspaces.
Reads configuration from {CONFIG_FILE}"""


class ParseError(Exception):
    pass


@dataclass(frozen=True, order=True)
class Workspace:
    name: str
    display: str = field(default="")
    visible: bool = field(default=False)
    focused: bool = field(default=False)
    is_gridable: bool = field(default=False)

    @classmethod
    def from_json(cls, json_data: str) -> "Self":
        name = json_data["name"]
        display = json_data["output"]
        visible = json_data["visible"]
        focused = json_data["focused"]
        is_gridable = True
        try:
            row, col = name.split('.')
            int(row)
            int(col)
        except (TypeError, ValueError):
            is_gridable = False
        return cls(name, display, visible, focused, is_gridable)

    @classmethod
    def from_coords(cls, row: int, col: int) -> "Self":
        return cls(f"{row}.{col}", is_gridable=True)


@dataclass(frozen=True)
class State:
    displays: tuple[str, ...]
    workspaces: dict[str, Workspace]
    ungridable_workspaces: tuple[str, ...]
    focused_display: str
    focused_workspace: str

    @classmethod
    def get(cls, verbose: bool) -> "Self":
        home = os.getenv("HOME")
        raw_displays = json.loads(
            subprocess.run(
                ("i3-msg", "-t", "get_outputs"),
                check=True,
                capture_output=True,
            ).stdout.decode()
        )
        displays = tuple(
            d["name"]
            for d in sorted(raw_displays, key=lambda d: d["rect"]["x"])
            if d.get("name") != "xroot-0" and d.get("active") == True
        )
        if verbose:
            print(f"Displays: {', '.join(displays)}")

        json_workspaces = json.loads(
            subprocess.run(
                ("i3-msg", "-t", "get_workspaces"),
                check=True,
                capture_output=True,
            ).stdout.decode()
        )
        focused_display: Optional[str] = None
        workspaces: dict[str, Workspace] = dict()
        focused_workspace: Optional[str] = None
        ungridable_workspaces: list[str] = list()
        for json_ws in json_workspaces:
            ws = Workspace.from_json(json_ws)
            if verbose:
                print(ws)
            if ws.focused:
                focused_workspace = ws.name
                focused_display = ws.display
            assert ws.name not in workspaces
            workspaces[ws.name] = ws
            if not ws.is_gridable:
                ungridable_workspaces.append(ws.name)
        if focused_display is None:
            raise ParseError("No display focused")
        if focused_workspace is None:
            raise ParseError("No workspace focused")
        return cls(
            displays,
            workspaces,
            tuple(ungridable_workspaces),
            focused_display,
            focused_workspace,
        )


def print_layout(
    rows: int,
    columns: int,
    notification: bool,
    notification_timeout: int,
    icon_file: str,
    verbose: bool,
):
    state = State.get(verbose)
    displays_repr = " " + " ".join(f"{d:<15}" for d in state.displays)
    visible_workspaces = {d: "---" for d in state.displays}
    for ws in state.workspaces.values():
        if ws.visible and ws.display in visible_workspaces.keys():
            visible_workspaces[ws.display] = ws.name
    visible_workspaces_repr = " ".join(f"{visible_workspaces[d]:<15}" for d in state.displays)
    layout_reprs = [
        " " + visible_workspaces_repr
    ]
    row_reprs = []
    focused_ws_repr = "unknown"
    for row in range(rows):
        col_reprs = []
        for col in range(columns):
            name = Workspace.from_coords(row, col).name
            ws_repr = WORKSPACE_EMPTY
            if (ws := state.workspaces.get(name)) is not None:
                ws_repr = WORKSPACE_OCCUPIED
                if ws.visible:
                    if ws.focused:
                        ws_repr = WORKSPACE_FOCUS
                        focused_ws_repr = name
                    else:
                        ws_repr = WORKSPACE_VISIBLE
            col_reprs.append(ws_repr)
        row_reprs.append(" ".join(col_reprs))
    layout_reprs.append("\n".join(row_reprs))
    if len(state.ungridable_workspaces) > 0:
        layout_reprs.append("\nOther workspaces:")
        layout_reprs.append(", ".join(state.ungridable_workspaces))
    layout_repr = "\n".join(layout_reprs)

    print(f"Focused workspace: {focused_ws_repr}, Visible workspaces: {visible_workspaces_repr}")
    if verbose:
        print(displays_repr)
        print(layout_repr)
    if notification:
        subprocess.run(
            (*NOTIFY_SEND, "-t", str(notification_timeout), "-i", icon_file, displays_repr, layout_repr),
            check=True,
        )


def _sort_displays(display_name: str, display_priorities: list[str]) -> int:
    if display_name in display_priorities:
        return display_priorities.index(display_name)
    return len(display_priorities) + 1


def switch_workspace(row: int, col: int, display_priorities: list[str], verbose: bool):
    state = State.get(verbose)
    refocus_display = state.focused_display
    main_display, *other_displays = sorted(
        state.displays,
        key=lambda name: _sort_displays(name, display_priorities)
    )
    root_containers = get_root_container_ids(state.workspaces.keys())
    for i, display_name in enumerate(other_displays):
        set_workspace_display(display_name, str(i + 1), verbose)
    main_workspace = Workspace.from_coords(row, col)
    set_workspace_display(main_display, main_workspace.name, verbose)
    run_i3_command(f"focus output {refocus_display}", verbose)


def set_workspace_display(display: str, workspace_name: str, verbose: bool):
    commands = [
        f"focus output {display}",
        f"workspace {workspace_name}",
        f"move workspace to output {display}",
        f"focus output {display}",
    ]
    run_i3_command(";".join(commands), verbose)


def move_to_workspace(workspace_name: str, verbose: bool):
    run_i3_command(f"move to workspace {workspace_name}", verbose)


def collect_lost_windows(verbose: bool):
    state = State.get(verbose)
    container_ids = get_root_container_ids(state.ungridable_workspaces)
    if len(container_ids) == 0:
        return
    i3_commands = [
        f"[con_id={container_id}] move container to workspace {state.focused_workspace}"
        for container_id in container_ids
    ]
    run_i3_command(";".join(i3_commands), verbose)


def get_root_container_ids(workspace_names: list[str]):
    root_node = json.loads(
        subprocess.run(
            ("i3-msg", "-t", "get_tree"),
            capture_output=True,
            check=True,
        ).stdout.decode()
    )
    container_ids = []
    for output in root_node["nodes"]:
        assert output["type"] == "output"
        if output["name"] == "__i3":
            continue
        for con in output["nodes"]:
            if con["type"] != "con":
                continue
            for workspace in con["nodes"]:
                assert workspace["type"] == "workspace"
                if workspace["name"] not in workspace_names:
                    continue
                for node in workspace["nodes"]:
                    assert node["type"] == "con"
                    container_ids.append(node["id"])
    return container_ids


def run_i3_command(command: str, verbose: bool):
    if verbose:
        print("Running i3 command:")
        print("\n".join(f"> {c.strip()}" for c in command.split(";")))
    result = subprocess.run(("i3-msg", command), capture_output=True)
    if verbose:
        print(f"{result.returncode=}")
        print(f"stdout: {result.stdout.decode()}")
        print(f"stderr: {result.stderr.decode()}")
    result.check_returncode()


def create_missing_config():
    os.makedirs(CONFIG_DIR, exist_ok=True)
    if not CONFIG_FILE.exists():
        CONFIG_FILE.write_text(DEFAULT_CONFIG_TOML)


def main():
    parser = argparse.ArgumentParser("wsi", description=HELP_TEXT)
    parser.add_argument("row", type=int, nargs="?", help="desktop row")
    parser.add_argument("column", type=int, nargs="?", help="desktop column")
    parser_command = parser.add_mutually_exclusive_group()
    parser_command.add_argument(
        "-m",
        "--move",
        action="store_true",
        required=False,
        help="move focused container to the workspace",
    )
    parser_command.add_argument(
        "-c",
        "--collect",
        action="store_true",
        help="collect windows from unknown workspaces to the current workspace",
    )
    parser.add_argument(
        "-n",
        "--nonotification",
        action="store_true",
        help="disable notification",
    )
    parser.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        help="be verbose",
    )
    args = parser.parse_args()
    config = tomllib.loads(CONFIG_FILE.read_text())
    rows = config["rows"]
    columns = config["columns"]
    notification_timeout = config["notification_timeout"]
    icon = config["icon"]

    row = args.row
    col = args.column
    if (row is None) != (col is None):
        print(parser.format_usage())
        print("Cannot specify row without column.", file=sys.stderr)
        exit(1)
    if args.collect:
        collect_lost_windows(args.verbose)
    elif (row is not None) and (col is not None):
        if args.move:
            workspace = Workspace.from_coords(row, col)
            move_to_workspace(workspace.name, args.verbose)
        else:
            display_priorities = config["display_priorities"]
            switch_workspace(row, col, display_priorities, args.verbose)
    print_layout(
        rows=rows,
        columns=columns,
        notification=not args.nonotification,
        notification_timeout=notification_timeout,
        icon_file=icon,
        verbose=args.verbose,
    )


if __name__ == "__main__":
    create_missing_config()
    main()
