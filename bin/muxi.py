#! /bin/python

from dataclasses import dataclass, field
from typing import Optional, Callable
import argparse
import json
import os
import random
import subprocess
import sys

WORKSPACE_DEBUG_KEYS = ("name", "output", "visible", "focused")

ROWS = 3
COLUMNS = 4

NOTIFY_TIMEOUT = 1000
NOTIFY_SEND = (
    "notify-send",
    "-u", "low",
    "-t", str(NOTIFY_TIMEOUT),
    "-h",
    'string:synchronous:"muxidesktops"',
)
OUTPUT_SPLIT = " "
OUTPUT_EMPTY = "▁"
OUTPUT_OCCUPIED = "◇"
OUTPUT_VISIBLE = "◆"
OUTPUT_FOCUS = "∇"

class ParseError(BaseException):
    pass

@dataclass(frozen=True, order=True)
class Workspace:
    row: int
    col: int
    out: int = field(default=0)
    display: str = field(default="")
    visible: bool = field(default=False)
    focused: bool = field(default=False)

    def __post_init__(self):
        if not 0 <= self.row < ROWS:
            raise ParseError(f"Invalid index {self.row=} {ROWS=}")
        if not 0 <= self.col < COLUMNS:
            raise ParseError(f"Invalid index {self.col=} {COLUMNS=}")

    def from_json(json_data: str, /, **kwargs) -> "Self":
        try:
            name = json_data["name"]
            display = json_data["output"]
            visible = json_data["visible"]
            focused = json_data["focused"]
            row, col, out = name
            row = int(row)
            col = int(col)
            out = int(out)
            return Workspace(row, col, out, display, visible, focused)
        except BaseException as e:
            raise ParseError(f"JSON parse error: {repr(e)} [ {json_data=} ]") from e

    @property
    def name(self) -> str:
        return f"{self.desktop}{self.out}"

    @property
    def desktop(self) -> str:
        return f"{self.row}{self.col}"

@dataclass(frozen=True)
class State:
    displays: tuple[str, ...]
    workspaces: dict[str, Workspace]
    focused_workspace: str
    focused_display: int
    invalid_workspaces: tuple[str, ...]

    @classmethod
    def get(cls) -> "Self":
        home = os.getenv('HOME')
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
        eprint(f"{displays=}")

        json_workspaces = json.loads(
            subprocess.run(
                ("i3-msg", "-t", "get_workspaces"),
                check=True,
                capture_output=True,
            ).stdout.decode()
        )
        workspaces: dict[str, Workspace] = dict()
        invalid_workspaces: list[str] = list()
        focused_workspace = Workspace(0, 0)
        focused_display = 0
        eprint(f">> Parsing workspaces: " + " ".join(f"{k.upper():<8}" for k in WORKSPACE_DEBUG_KEYS))
        for json_ws in json_workspaces:
            parsed_ws = None
            try:
                eprint(f">> Parsing workspace:  " + " ".join(f"{str(json_ws[k]):<8}" for k in WORKSPACE_DEBUG_KEYS))
                parsed_ws = Workspace.from_json(json_ws)
                if parsed_ws.focused:
                    focused_workspace = parsed_ws.name
                    focused_display = displays[parsed_ws.out]
                assert parsed_ws.name not in workspaces
            except BaseException as e:
                eprint(f"Invalid workspace '{json_ws['name']}': {repr(e)} [ {json_ws=} ]")
                if (name := json_ws.get("name")) is not None:
                    invalid_workspaces.append(name)
                continue
            workspaces[parsed_ws.name] = parsed_ws
        eprint(f'Focused workspace: [{focused_workspace}] output: [{focused_display}]')
        return cls(displays, workspaces, focused_workspace, focused_display, tuple(invalid_workspaces))

def main():
    parser = argparse.ArgumentParser("muxi", description="Manage desktop of workspaces.")
    parser.add_argument("row", type=int, nargs="?", help="Desktop row")
    parser.add_argument("col", type=int, nargs="?", help="Desktop column")
    parser.add_argument("-m", "--move", action="store_true", required=False, help="move focused container to the desktop")
    parser.add_argument("-c", "--collect", action="store_true", help="collect windows from unknown workspaces")
    parser.add_argument("-n", "--nonotification", action="store_true", help="disable notification showing layout")
    args = parser.parse_args()
    eprint("\n====================")
    eprint(f"{args=}")
    row = args.row
    col = args.col
    if (row is None) != (col is None):
        eprint(parser.format_usage())
        eprint("Must specify column with row.")
        exit(1)
    if (row is not None) and (col is not None):
        state = State.get()
        if args.move:
            move_to_desktop(state, row, col)
        else:
            switch_desktop(state, row, col)
    if args.collect:
        state = State.get()
        collect_lost_windows(state)
    state = State.get()
    print_layout(state, not args.nonotification)

def print_layout(state: State, notification: bool):
    displays_repr = " " + " ".join(f"{d:<7}" for d in state.displays)
    visible_workspace_names = [d for d in state.displays]
    for ws in state.workspaces.values():
        if ws.visible:
            visible_workspace_names[state.displays.index(ws.display)] = ws.name
    layout_reprs = [" " + " ".join(f"{name:<7}" for name in visible_workspace_names) + "\n"]
    for row in range(ROWS):
        row_reprs = []
        for col in range(COLUMNS):
            col_reprs = []
            for output in range(len(state.displays)):
                name = f"{row}{col}{output}"
                output_repr = OUTPUT_EMPTY
                if (ws := state.workspaces.get(name)) is not None:
                    output_repr = OUTPUT_OCCUPIED
                    if ws.visible:
                        output_repr = OUTPUT_FOCUS if ws.focused else OUTPUT_VISIBLE
                col_reprs.append(output_repr)
            row_reprs.append("".join(col_reprs))
        layout_reprs.append(OUTPUT_SPLIT.join(row_reprs))
    if len(state.invalid_workspaces) > 0:
        layout_reprs.append("\nOther workspaces:")
        layout_reprs.append(", ".join(state.invalid_workspaces))
    layout_repr = "\n".join(layout_reprs)

    eprint(displays_repr)
    eprint(layout_repr)
    if notification:
        subprocess.run((*NOTIFY_SEND, displays_repr, layout_repr), check=True)

def switch_desktop(state: State, row: int, col: int):
    workspaces = [Workspace(row, col, i, display=d) for i, d in enumerate(state.displays)]
    i3_command = ""
    for ws in workspaces:
        i3_command += f"focus output {ws.display};workspace {ws.name};move to output {ws.display};focus output {ws.display};"
    i3_command += f"focus output {state.focused_display};"
    eprint(i3_command)
    run_i3_command(i3_command)

def move_to_desktop(state: State, row: int, col: int):
    ws = Workspace(row=row, col=col)
    for ws_ in state.workspaces.values():
        if ws_.focused:
            ws = Workspace(row, col, min(ws_.out, len(state.displays) - 1))
            break
    run_i3_command(f"move to workspace {ws.name}")

def collect_lost_windows(state: State):
    container_ids = get_root_container_ids(state)
    if len(container_ids) == 0:
        return
    i3_command = ""
    for container_id in container_ids:
        i3_command += f'[con_id={container_id}] move container to workspace {state.focused_workspace};'
    run_i3_command(i3_command)

def get_root_container_ids(state: State):
    root_node = json.loads(
        subprocess.run(
            ("i3-msg", "-t", "get_tree"),
            capture_output=True,
            check=True,
        ).stdout.decode()
    )
    container_ids = []
    for output in root_node['nodes']:
        assert output['type'] == 'output'
        if output['name'] == '__i3':
            continue
        for con in output['nodes']:
            if con['type'] != 'con':
                continue
            for workspace in con['nodes']:
                assert workspace['type'] == 'workspace'
                if workspace['name'] not in state.invalid_workspaces:
                    continue
                for node in workspace['nodes']:
                    assert node['type'] == 'con'
                    container_ids.append(node['id'])
    return container_ids

def run_i3_command(command: str):
    eprint("\n".join(command.split(";")))
    result = subprocess.run(("i3-msg", command), capture_output=True)
    eprint(f'{result.returncode=}')
    eprint(f'stdout: {result.stdout.decode()}')
    eprint(f'stderr: {result.stderr.decode()}')
    result.check_returncode()

def eprint(message: str):
    user = os.getenv('USER')
    with open(f"/tmp/logs-{user}/muxi.log", "a") as f:
        f.write(f"{message}\n")
    print(str(message), file=sys.stderr)

if __name__ == "__main__":
    main()
