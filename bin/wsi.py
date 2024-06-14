#! /bin/python

from dataclasses import dataclass, field
from typing import Optional, Callable
import argparse
import json
import os
import random
import subprocess
import sys
import tomllib
from pathlib import Path

ROWS = 3
COLUMNS = 4

NOTIFY_TIMEOUT = 1000
NOTIFY_SEND = (
    "notify-send",
    "-u",
    "low",
    "-t",
    str(NOTIFY_TIMEOUT),
    "-h",
    'string:synchronous:"wsi"',
)
WORKSPACE_EMPTY = "▁"
WORKSPACE_OCCUPIED = "◆"
WORKSPACE_VISIBLE = "◇"
WORKSPACE_FOCUS = "∇"
USER = os.getenv("USER")
CONFIG_DIR = Path(f"/home/{USER}/.config/wsi")
CONFIG_FILE = Path(f"{CONFIG_DIR}/config.toml")
DEFAULT_CONFIG_TOML = f"""
rows = 2
columns = 3
display = "eDP-1"
icon = "{CONFIG_DIR}/icon.png"
""".strip()
HELP_TEXT = f"""Manage i3 workspaces.

Pass row and column to switch or move to a workspace.
Pass neither to print workspaces.
Reads configuration from {CONFIG_FILE}"""


class ParseError(BaseException):
    pass


@dataclass(frozen=True, order=True)
class Workspace:
    row: int
    col: int
    display: str
    visible: bool = field(default=False)
    focused: bool = field(default=False)

    def from_json(json_data: str, /, **kwargs) -> "Self":
        try:
            name = json_data["name"]
            display = json_data["output"]
            visible = json_data["visible"]
            focused = json_data["focused"]
            row, col, display = name.split(".")
            row = int(row)
            col = int(col)
            return Workspace(row, col, display, visible, focused)
        except BaseException as e:
            raise ParseError(f"JSON parse error: {repr(e)} [ {json_data=} ]") from e

    @property
    def name(self) -> str:
        return f"{self.row}.{self.col}.{self.display}"


@dataclass(frozen=True)
class State:
    display_names: tuple[str, ...]
    focused_display: str
    workspaces: dict[str, Workspace]
    focused_workspace: str
    invalid_workspaces: tuple[str, ...]

    def assert_display_exists(self, display_name: str):
        if display_name not in self.display_names:
            print(
                f"Unknnown display: {display_name} [must be one of: {', '.join(self.display_names)}]",
                file=sys.stderr,
            )
            exit(1)

    def display_index(self, display_name: str) -> int:
        self.assert_display_exists(display_name)
        return self.display_names.index(display_name)

    @classmethod
    def get(cls) -> "Self":
        home = os.getenv("HOME")
        raw_displays = json.loads(
            subprocess.run(
                ("i3-msg", "-t", "get_outputs"),
                check=True,
                capture_output=True,
            ).stdout.decode()
        )
        display_names = tuple(
            d["name"]
            for d in sorted(raw_displays, key=lambda d: d["rect"]["x"])
            if d.get("name") != "xroot-0" and d.get("active") == True
        )
        print(f"Displays: {', '.join(display_names)}")

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
        invalid_workspaces: list[str] = list()
        for json_ws in json_workspaces:
            if json_ws["focused"]:
                focused_workspace = json_ws["name"]
                focused_display = json_ws["output"]
            parsed_ws = None
            try:
                parsed_ws = Workspace.from_json(json_ws)
                print(parsed_ws)
                assert parsed_ws.name not in workspaces
                workspaces[parsed_ws.name] = parsed_ws
            except BaseException as e:
                print(f"Invalid workspace: {e}")
                if (name := json_ws.get("name")) is not None:
                    invalid_workspaces.append(name)
                continue
        if focused_display is None:
            raise ParseError("No display focused")
        if focused_workspace is None:
            raise ParseError("No workspace focused")
        return cls(
            display_names=display_names,
            focused_display=focused_display,
            workspaces=workspaces,
            focused_workspace=focused_workspace,
            invalid_workspaces=tuple(invalid_workspaces),
        )


def print_layout(rows: int, columns: int, notification: bool, icon_path=str):
    state = State.get()
    displays_repr = " " + " ".join(f"{d:<7}" for d in state.display_names)
    visible_workspaces = {d: "---" for d in state.display_names}
    for ws in state.workspaces.values():
        if ws.visible and ws.display in visible_workspaces:
            visible_workspaces[ws.display] = ws.name
    layout_reprs = [
        " " + " ".join(f"{visible_workspaces[d]:<7}" for d in state.display_names)
    ]
    for display in state.display_names:
        row_reprs = []
        for row in range(rows):
            col_reprs = []
            for col in range(columns):
                name = Workspace(row, col, display).name
                ws_repr = WORKSPACE_EMPTY
                if (ws := state.workspaces.get(name)) is not None:
                    ws_repr = WORKSPACE_OCCUPIED
                    if ws.visible:
                        ws_repr = WORKSPACE_FOCUS if ws.focused else WORKSPACE_VISIBLE
                col_reprs.append(ws_repr)
            row_reprs.append(" ".join(col_reprs))
    layout_reprs.append("\n".join(row_reprs))
    if len(state.invalid_workspaces) > 0:
        layout_reprs.append("\nOther workspaces:")
        layout_reprs.append(", ".join(state.invalid_workspaces))
    layout_repr = "\n".join(layout_reprs)

    print(displays_repr)
    print(layout_repr)
    if notification:
        subprocess.run((*NOTIFY_SEND, "-i", icon_path, displays_repr, layout_repr), check=True)


def switch_workspace(display: str, row: int, col: int):
    workspace = Workspace(row, col, display)
    run_i3_command(
        ";".join(
            [
                f"focus output {display}",
                f"workspace {workspace.name}",
                f"move to output {display}",
                f"focus output {display}",
            ]
        )
    )


def move_to_workspace(display: str, row: int, col: int):
    state = State.get()
    workspace = Workspace(row, col, display)
    run_i3_command(f"move to workspace {workspace.name}")


def collect_lost_windows():
    state = State.get()
    container_ids = get_root_container_ids(state)
    if len(container_ids) == 0:
        return
    i3_commands = [
        f"[con_id={container_id}] move container to workspace {state.focused_workspace}"
        for container_id in container_ids
    ]
    run_i3_command(";".join(i3_commands))


def get_root_container_ids(state: State):
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
                if workspace["name"] not in state.invalid_workspaces:
                    continue
                for node in workspace["nodes"]:
                    assert node["type"] == "con"
                    container_ids.append(node["id"])
    return container_ids


def run_i3_command(command: str):
    print("running i3 command...")
    print("\n".join(c.strip() for c in command.split(";")))
    result = subprocess.run(("i3-msg", command), capture_output=True)
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
    parser.add_argument(
        "-d",
        "--display",
        help="display to manage (overrides config)",
    )
    parser.add_argument(
        "-n",
        "--nonotification",
        action="store_true",
        help="disable notification",
    )
    parser_command.add_argument(
        "-c",
        "--collect",
        action="store_true",
        help="collect windows from unknown workspaces to the current workspace",
    )
    args = parser.parse_args()
    config = tomllib.loads(CONFIG_FILE.read_text())
    rows = config["rows"]
    columns = config["columns"]
    display_name = config["display"] if args.display is None else args.display
    icon_path = config["icon"]

    row = args.row
    col = args.column
    if (row is None) != (col is None):
        print(parser.format_usage())
        print("Cannot specify row without column.", file=sys.stderr)
        exit(1)
    if args.collect:
        collect_lost_windows()
    elif (row is not None) and (col is not None):
        if args.move:
            move_to_workspace(display_name, row, col)
        else:
            switch_workspace(display_name, row, col)
    print_layout(
        rows=rows,
        columns=columns,
        notification=not args.nonotification,
        icon_path=icon_path,
    )


if __name__ == "__main__":
    create_missing_config()
    main()
