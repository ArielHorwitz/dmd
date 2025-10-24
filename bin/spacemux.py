#! /bin/python

import argparse
import json
import re
import os
import subprocess
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional

if sys.version_info >= (3, 12):
    import tomllib
else:
    import tomli as tomllib

TITLE = "spacemux"

WORKSPACE_EMPTY = ""  # ○
WORKSPACE_OCCUPIED = "●"
WORKSPACE_SPECIAL = "△"
WORKSPACE_OCCUPIED_SPECIAL = "▲"

USER = os.getenv("USER")
VARIABLE_DIR = Path(f"/home/{USER}/.local/share/spacemux")
LOCKED_MONITORS_FILE = VARIABLE_DIR / "locked_monitors"
DEFAULT_CONFIG_FILE = Path(f"/home/{USER}/.config/{TITLE}/config.toml")
DEFAULT_CONFIG_TOML = """
rows = 2
columns = 3
notification_timeout = 1000
icon = "/path/to/icon/image"
""".strip()
NOTIFY_SEND_ARGS = (
    "notify-send",
    "-u",
    "low",
    "-h",
    f'string:synchronous:"{TITLE}"',
)


def eprint(*args):
    print(*args, file=sys.stderr)


@dataclass
class GridState:
    regular: bool = False
    special: bool = False
    visible: bool = False


def print_layout(
    rows: int,
    columns: int,
    notification: bool,
    notification_timeout: int,
    icon_file: str,
):
    state = State.get()
    monitor_names = tuple(m.name for m in state.get_monitors_by_position())
    locked_monitors = tuple(m for m in get_locked_monitors(state) if m in monitor_names)
    visible_workspaces_repr = " ".join(
        f"{state.monitor_workspace(m.id).name:<15}" for m in state.get_monitors_by_position()
    )
    locked_monitors_repr = " ".join(f"{m:<15}" for m in locked_monitors)
    print(f" Focused workspace: {state.focused_workspace.name}")
    print(f"Visible workspaces: {visible_workspaces_repr}")
    print(f"   Locked monitors: {locked_monitors_repr}")

    displays_repr = " " + " ".join(
        f"{m:<15}" if m not in locked_monitors else f"🔒 {m:<13}" for m in monitor_names
    )
    layout_reprs = [" " + visible_workspaces_repr]
    row_reprs = []
    grid_states = {
        (c, r): GridState() for r in range(1, rows + 1) for c in range(1, columns + 1)
    }
    for window in state.windows.values():
        ws = state.workspaces[window.workspace_id]
        if ws.id in state.ungridable_workspaces:
            continue
        gs = grid_states[ws.coords]
        if ws.is_special:
            gs.special = True
        else:
            gs.regular = True
        if ws.is_visible:
            gs.visible = True
    focused_workspace = state.workspaces[state.focused_workspace_id]
    if focused_workspace.coords is not None:
        grid_states[focused_workspace.coords].visible = True
    for row in range(1, rows + 1):
        col_reprs = []
        for col in range(1, columns + 1):
            gs = grid_states[(col, row)]
            if gs.regular and gs.special:
                icon = WORKSPACE_OCCUPIED_SPECIAL
            elif gs.regular:
                icon = WORKSPACE_OCCUPIED
            elif gs.special:
                icon = WORKSPACE_SPECIAL
            else:
                icon = WORKSPACE_EMPTY
            if gs.visible:
                ws_repr = f"[{icon}]"
            else:
                ws_repr = f" {icon} "
            col_reprs.append(ws_repr)
        row_reprs.append("".join(col_reprs))
    layout_reprs.append("\n".join(row_reprs))
    if len(state.ungridable_workspaces) > 0:
        ungridables = (
            state.workspaces[wid].name for wid in state.ungridable_workspaces
        )
        layout_reprs.append("\nOther workspaces:")
        layout_reprs.append(", ".join(ungridables))
    layout_repr = "\n".join(layout_reprs)

    print(displays_repr)
    print(layout_repr)

    if notification:
        command_args = (
            *NOTIFY_SEND_ARGS,
            "-t",
            str(notification_timeout),
            "-i",
            icon_file,
            displays_repr,
            layout_repr,
        )
        subprocess.run(command_args, check=True)


@dataclass(frozen=True)
class Monitor:
    name: str
    enabled: bool
    focused: bool
    x: int
    y: int
    id: int = field(repr=False)
    workspace_id: int = field(repr=False)
    special_workspace_id: int = field(repr=False)
    raw_data: dict = field(repr=False)

    def get_display_props(self, state):
        props = {
            "id": self.id,
            "focused": self.focused,
            "enabled": self.enabled,
            "workspace": state.workspaces[self.workspace_id].name,
        }
        return self.name, props


@dataclass(frozen=True)
class WorkspaceGeometry:
    row: Optional[int]
    col: Optional[int]
    monitor: Optional[int] = None

    @property
    def coords(self):
        return (self.col, self.row)


@dataclass(frozen=True)
class Workspace:
    name: str
    windows: int
    id: int = field(repr=False)
    monitor_id: int = field(repr=False)
    is_visible: bool = field(repr=False)
    raw_data: dict = field(repr=False)

    @property
    def geometry(self):
        parts = self.name.removeprefix("special:").split(".")
        try:
            col = int(parts[0])
            row = int(parts[1])
            if self.is_special:
                return WorkspaceGeometry(row=row, col=col)
            monitor = int(parts[2])
            return WorkspaceGeometry(row=row, col=col, monitor=monitor)
        except (ValueError, IndexError):
            return None

    @property
    def coords(self):
        if self.geometry is None:
            return None
        return self.geometry.coords

    @property
    def is_special(self):
        return self.name.startswith("special:")

    def get_display_props(self, state):
        props = {
            "monitor": state.monitors[self.monitor_id].name,
            "windows": self.windows,
            "special": self.is_special,
            "geo": self.geometry,
            "id": self.id,
        }
        return self.name, props


@dataclass(frozen=True)
class Window:
    class_: str
    title: str
    focus_id: int
    workspace_id: int = field(repr=False)
    address: str = field(repr=False)
    raw_data: dict = field(repr=False)

    def get_display_props(self, state):
        props = {
            # "title": self.title,
            "workspace": state.workspaces[self.workspace_id].name,
            "focus_id": self.focus_id,
            "address": self.address,
        }
        return f"[[{self.class_}]] {self.title}", props


@dataclass(frozen=True)
class State:
    monitors: dict[int, Monitor]
    workspaces: dict[int, Workspace]
    windows: dict[str, Window]
    focused_workspace_id: int
    focused_window_address: str | None

    @classmethod
    def get(cls):
        monitors = {}
        for json_data in hypr_json("monitors"):
            m = Monitor(
                name=json_data["name"],
                enabled=not json_data["disabled"],
                focused=json_data["focused"],
                x=json_data["x"],
                y=json_data["y"],
                id=json_data["id"],
                workspace_id=json_data["activeWorkspace"]["id"],
                special_workspace_id=json_data["specialWorkspace"]["id"],
                raw_data=json_data,
            )
            monitors[m.id] = m
        workspaces = {}
        for json_data in hypr_json("workspaces"):
            id = json_data["id"]
            monitor_id = json_data["monitorID"]
            is_visible = monitors[monitor_id].workspace_id == id
            w = Workspace(
                name=json_data["name"],
                windows=json_data["windows"],
                id=id,
                monitor_id=monitor_id,
                is_visible=is_visible,
                raw_data=json_data,
            )
            workspaces[w.id] = w
        windows = {}
        for json_data in hypr_json("clients"):
            w = Window(
                class_=json_data["class"],
                title=json_data["title"],
                focus_id=json_data["focusHistoryID"],
                workspace_id=json_data["workspace"]["id"],
                address=json_data["address"],
                raw_data=json_data,
            )
            windows[w.address] = w
        active_workspace = hypr_json("activeworkspace")
        active_window = hypr_json("activewindow")
        return cls(
            monitors=monitors,
            workspaces=workspaces,
            windows=windows,
            focused_workspace_id=active_workspace["id"],
            focused_window_address=active_window.get("address"),
        )

    def monitor_workspace(self, monitor_id):
        return self.workspaces[self.monitors[monitor_id].workspace_id]

    def is_gridable_workspace(self, wid):
        ws = self.workspaces[wid]
        if ws.geometry is None:
            return False
        if ws.is_special:
            return True
        return (
            ws.geometry.monitor is not None
            and ws.geometry.monitor < len(self.monitors)
        )

    @property
    def ungridable_workspaces(self):
        return [
            ws.id
            for ws in self.workspaces.values()
            if not self.is_gridable_workspace(ws.id)
        ]

    @property
    def focused_monitor(self):
        for monitor in self.monitors.values():
            if monitor.focused:
                return monitor
        raise RuntimeError("No focused monitor found")

    @property
    def focused_workspace(self):
        return self.workspaces[self.focused_workspace_id]

    def get_monitors_by_position(self):
        return sorted(self.monitors.values(), key=lambda m: (m.x, m.y, m.id))


def print_list(data_name, raw):
    state = State.get()
    if data_name == "monitors":
        items = sorted(state.monitors.values(), key=lambda m: m.id)
    elif data_name == "workspaces":
        items = sorted(state.workspaces.values(), key=lambda m: m.name)
    elif data_name == "windows":
        items = sorted(
            state.windows.values(),
            key=lambda w: (state.workspaces[w.workspace_id].name, w.focus_id),
        )
    else:
        raise RuntimeError(f"Unknown data type {data_name!r}")
    if raw:
        for item in items:
            print(item.raw_data)
    else:
        item_reprs = []
        for item in items:
            name, props = item.get_display_props(state)
            lines = [name, *(f"    {k}: {v}" for k, v in props.items())]
            item_reprs.append("\n".join(lines))
        print("\n\n".join(item_reprs))


def switch_cell(cell_name, workspace=False):
    if workspace:
        hypr_dispatch(f"focusworkspaceoncurrentmonitor name:{cell_name}")
        return
    state = State.get()
    focused_monitor = state.focused_monitor
    locked_monitors = get_locked_monitors(state)
    unlocked_monitors = [
        m for m in state.get_monitors_by_position()
        if m.name not in locked_monitors
    ]
    if not unlocked_monitors:
        return
    row, col = cell_name.split(".")
    target_coords = (int(row), int(col))
    existing_workspaces = [
        ws for ws in state.workspaces.values()
        if ws.geometry is not None
        and ws.geometry.coords == target_coords
        and ws.geometry.monitor is not None
    ]
    existing_workspaces.sort(key=lambda ws: ws.geometry.monitor)

    current_ws = state.monitor_workspace(unlocked_monitors[0].id)
    on_target_cell = (
        current_ws.geometry is not None
        and current_ws.geometry.coords == target_coords
    )

    eprint(f"{on_target_cell=}")
    eprint(f"{existing_workspaces=}")
    if on_target_cell and len(existing_workspaces) > len(unlocked_monitors):
        first_index = existing_workspaces.index(current_ws)
        next_index = (first_index + 1) % len(existing_workspaces)
        existing_workspaces = existing_workspaces[next_index:] + existing_workspaces[:next_index]
        eprint(f"{existing_workspaces=}")

    targets = set(ws.geometry.monitor for ws in existing_workspaces[:len(unlocked_monitors)])
    eprint(f"{targets=}")
    for i in range(len(unlocked_monitors)):
        if len(targets) >= len(unlocked_monitors):
            break
        targets.add(i)
    targets = sorted(targets)
    eprint(f"{targets=}")

    commands = []
    for monitor, index in zip(unlocked_monitors, targets):
        commands.append(f"focusmonitor {state.monitors[monitor.id].name}")
        commands.append(f"focusworkspaceoncurrentmonitor name:{cell_name}.{index}")
    commands.append(f"focusmonitor {focused_monitor.name}")
    eprint(f"{targets=}")
    eprint(f"{commands=}")
    hypr_dispatch(*commands, batch_commands=True)


def move_window(cell_name, workspace=False):
    if workspace:
        hypr_dispatch(f"movetoworkspacesilent name:{cell_name}")
        return
    current_ws = State.get().focused_workspace
    if current_ws.geometry is not None and current_ws.geometry.monitor is not None:
        monitor_index = current_ws.geometry.monitor
        target_workspace_name = f"{cell_name}.{monitor_index}"
    else:
        target_workspace_name = f"{cell_name}.0"
    hypr_dispatch(f"movetoworkspacesilent name:{target_workspace_name}")


def move_workspace(cell_name, workspace=False, swap=False):
    state = State.get()
    source_ws = state.focused_workspace
    if not workspace:
        target_workspace_name = f"{cell_name}.0"
    else:
        target_workspace_name = cell_name
    target_ws = [
        ws for ws in state.workspaces.values()
        if ws.name == target_workspace_name
    ]
    if target_ws and not swap:
        raise ValueError(f"Workspace {target_workspace_name} already exists (use --swap)")

    hypr_dispatch(f"renameworkspace {source_ws.id} {target_workspace_name}")
    if swap:
        for ws in target_ws:
            hypr_dispatch(f"renameworkspace {ws.id} {source_ws.name}")


def swap_monitors(monitor_a, monitor_b):
    state = State.get()
    workspaces_a = [
        ws for ws in state.workspaces.values()
        if ws.geometry is not None
        and ws.geometry.monitor == monitor_a
    ]
    workspaces_b = [
        ws for ws in state.workspaces.values()
        if ws.geometry is not None
        and ws.geometry.monitor == monitor_b
    ]
    for ws in workspaces_a:
        col, row = ws.geometry.coords
        new_name = f"{col}.{row}.{monitor_b}"
        hypr_dispatch(f"renameworkspace {ws.id} {new_name}")
    for ws in workspaces_b:
        col, row = ws.geometry.coords
        new_name = f"{col}.{row}.{monitor_a}"
        hypr_dispatch(f"renameworkspace {ws.id} {new_name}")


def toggle_special():
    state = State.get()
    x, y = state.focused_workspace.coords
    cell_name = f"{x}.{y}"
    hypr_dispatch(f"togglespecialworkspace {cell_name}")


def move_special():
    state = State.get()
    x, y = state.focused_workspace.coords
    cell_name = f"{x}.{y}"
    hypr_dispatch(f"movetoworkspacesilent special:{cell_name}")


def collect_windows(off_grid_only: bool = False):
    state = State.get()
    target_ws = state.focused_workspace
    eprint(f"Target: {target_ws}")
    ungridable = state.ungridable_workspaces
    if off_grid_only:
        eprint(f"Ungridable: {[state.workspaces[wid] for wid in ungridable]}")
    for window in state.windows.values():
        ws = state.workspaces[window.workspace_id]
        if off_grid_only and ws.id not in ungridable:
            eprint(f"Skipping: {window} {ws.id=}")
            continue
        eprint(f"Collecting: {window}")
        hypr_dispatch(
            f"movetoworkspacesilent name:{target_ws.name},address:{window.address}"
        )


def run_hypr_command(*args, batch_commands=False):
    if batch_commands:
        command = ("hyprctl", "--batch", ";".join(args))
    else:
        command = ("hyprctl", *args)
    result = subprocess.run(command, capture_output=True, check=True)
    if result.stderr:
        raise RuntimeError(f"command {command!r} failed: {result.stderr.decode()}")
    return result.stdout.decode()


def hypr_dispatch(*args, batch_commands=False):
    if batch_commands:
        command = (
            "hyprctl",
            "--batch",
            ";".join(f"dispatch {c}" for c in args),
        )
    else:
        command = ("hyprctl", "dispatch", *args)
    result = subprocess.run(command, capture_output=True, check=True)
    stderr = result.stderr.decode()
    stdout = result.stdout.decode()
    success = bool(re.fullmatch(r"\s*(?:ok\s*)*", stdout.strip()))
    if not success:
        stderr = f"stdout: '{stdout}' stderr: '{stderr}'"
    if stderr:
        raise RuntimeError(f"command {command!r} failed: {stderr}")
    return stdout


def hypr_json(*args):
    command = ("-j", *args)
    result = run_hypr_command(*command)
    try:
        data = json.loads(result)
    except json.decoder.JSONDecodeError as e:
        raise RuntimeError(f"decoding result of command {command!r} failed") from e
    return data


def create_missing_config(file_path):
    os.makedirs(file_path.parent, exist_ok=True)
    if not file_path.exists():
        file_path.write_text(DEFAULT_CONFIG_TOML)


def get_locked_monitors(state):
    VARIABLE_DIR.mkdir(parents=True, exist_ok=True)
    LOCKED_MONITORS_FILE.touch()
    locked_monitors = LOCKED_MONITORS_FILE.read_text()
    return tuple(m for m in locked_monitors.splitlines() if m)


def set_monitor_lock(*, lock=None, monitor=None):
    state = State.get()
    if monitor is None:
        monitor = state.focused_monitor.name
    locked_monitors = set(get_locked_monitors(state))
    if lock is None:
        lock = monitor not in locked_monitors
    if lock:
        locked_monitors.add(monitor)
    elif monitor in locked_monitors:
        locked_monitors.remove(monitor)
    LOCKED_MONITORS_FILE.write_text("\n".join(m for m in locked_monitors))


def main():
    parser = argparse.ArgumentParser(TITLE, description="Manage workspaces")
    parser.add_argument(
        "-n",
        "--nonotification",
        action="store_true",
        help="disable notification",
    )
    parser.add_argument(
        "--config-file",
        default=DEFAULT_CONFIG_FILE,
        help="config file path",
    )
    subparsers = parser.add_subparsers(dest="command")
    info_parser = subparsers.add_parser("info", help="Show info")
    info_parser.add_argument(
        "info_type",
        choices=["workspaces", "windows", "monitors"],
        help="Info type",
    )
    info_parser.add_argument(
        "--raw",
        action="store_true",
        help="show raw data from hyprland",
    )
    switch_parser = subparsers.add_parser("switch", help="Switch to cell")
    switch_parser.add_argument("cell", help="Cell to switch to (e.g. 2.3)")
    switch_parser.add_argument(
        "--workspace",
        action="store_true",
        help="Treat argument as workspace name instead of cell coordinates",
    )
    move_parser = subparsers.add_parser("move", help="Move focused window to cell")
    move_parser.add_argument("cell", help="Cell to move window to (e.g. 2.3)")
    move_parser.add_argument(
        "--workspace",
        action="store_true",
        help="Treat argument as workspace name instead of cell coordinates",
    )
    move_workspace_parser = subparsers.add_parser("move-workspace", help="Move focused workspace to cell")
    move_workspace_parser.add_argument("cell", help="Cell to move workspace to (e.g. 2.3)")
    move_workspace_parser.add_argument(
        "--workspace",
        action="store_true",
        help="Treat argument as workspace name instead of cell coordinates",
    )
    move_workspace_parser.add_argument(
        "--swap",
        action="store_true",
        help="Swap with target if it exists",
    )
    lock_parser = subparsers.add_parser("lock", help="Set or toggle monitor lock state")
    lock_parser.add_argument(
        "lock",
        choices=["lock", "unlock", "toggle"],
        default="toggle",
        nargs="?",
        help="Set the lock state (defaults to toggle)",
    )
    lock_parser.add_argument(
        "--monitor",
        help="Monitor to set lock state (defaults to focused monitor)",
    )
    special_parser = subparsers.add_parser(
        "special",
        help="Manage the special workspace",
    )
    special_subparser = special_parser.add_subparsers(
        dest="subcommand",
        required=True,
    )
    special_subparser.add_parser(
        "toggle",
        help="Toggle the special workspace",
    )
    special_subparser.add_parser(
        "move",
        help="Move the focused window to the special workspace",
    )
    collect_parser = subparsers.add_parser(
        "collect",
        help="Collect windows from unknown workspaces to the current workspace",
    )
    collect_parser.add_argument(
        "--all",
        action="store_true",
        help="Collect from all workspaces",
    )
    swap_monitors_parser = subparsers.add_parser(
        "swap-monitors",
        help="Swap all workspaces between two monitor indices"
    )
    swap_monitors_parser.add_argument(
        "monitor_a",
        metavar="A",
        type=int,
        help="First monitor index"
    )
    swap_monitors_parser.add_argument(
        "monitor_b",
        metavar="B",
        type=int,
        help="Second monitor index"
    )
    show_parser = subparsers.add_parser("show", help="Show the current layout")
    show_parser.add_argument(
        "--notification-timeout",
        type=int,
        default=5000,
    )
    args = parser.parse_args()

    create_missing_config(Path(args.config_file))
    config = tomllib.loads(args.config_file.read_text())
    rows = config["rows"]
    columns = config["columns"]
    notification_timeout = config["notification_timeout"]
    icon = config["icon"]

    if args.command == "info":
        print_list(args.info_type, args.raw)
        exit()
    elif args.command == "lock":
        if args.lock == "lock":
            lock = True
        elif args.lock == "unlock":
            lock = False
        else:
            lock = None
        set_monitor_lock(lock=lock, monitor=args.monitor)
    elif args.command == "special":
        if args.subcommand == "toggle":
            toggle_special()
        elif args.subcommand == "move":
            move_special()
        else:
            raise ValueError(f"Unknown special subcommand: {args.special_subcommand}")
    elif args.command == "switch":
        switch_cell(args.cell, args.workspace)
    elif args.command == "move":
        move_window(args.cell, args.workspace)
    elif args.command == "move-workspace":
        move_workspace(args.cell, args.workspace, args.swap)
    elif args.command == "collect":
        if args.all:
            collect_windows()
        else:
            collect_windows(off_grid_only=True)
    elif args.command == "swap-monitors":
        swap_monitors(args.monitor_a, args.monitor_b)
    elif args.command == "show":
        notification_timeout = args.notification_timeout
    elif args.command is None:
        pass
    else:
        raise ValueError(f"Unknown command: {args.command}")

    print_layout(
        rows=rows,
        columns=columns,
        notification=not args.nonotification,
        notification_timeout=notification_timeout,
        icon_file=icon,
    )


if __name__ == "__main__":
    main()
