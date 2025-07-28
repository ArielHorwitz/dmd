#! /bin/python

import argparse
import json
import re
import os
import subprocess
import sys
from dataclasses import dataclass, field
from functools import cached_property
from pathlib import Path

if sys.version_info >= (3, 12):
    import tomllib
else:
    import tomli as tomllib

TITLE = "spacemux"
WORKSPACE_EMPTY = ""
WORKSPACE_OCCUPIED = ""
WORKSPACE_VISIBLE = ""
WORKSPACE_FOCUS = ""
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


def print_layout(
    rows: int,
    columns: int,
    notification: bool,
    notification_timeout: int,
    icon_file: str,
    verbose: bool,
):
    state = State.get()
    monitor_names = tuple(m.name for m in state.monitors.values())
    locked_monitors = tuple(m for m in get_locked_monitors(state) if m in monitor_names)
    visible_workspaces_repr = " ".join(
        f"{state.monitor_workspace(mid).name:<15}" for mid in state.monitors
    )
    locked_monitors_repr = " ".join(f"{m:<15}" for m in locked_monitors)
    print(f" Focused workspace: {state.focused_workspace.name}")
    print(f"Visible workspaces: {visible_workspaces_repr}")
    print(f"   Locked monitors: {locked_monitors_repr}")

    if not (verbose or notification):
        return

    displays_repr = " " + " ".join(
        f"{m:<15}" if m not in locked_monitors else f"🔒 {m:<13}" for m in monitor_names
    )
    layout_reprs = [" " + visible_workspaces_repr]
    row_reprs = []
    for row in range(1, rows + 1):
        col_reprs = []
        for col in range(1, columns + 1):
            ws_repr = WORKSPACE_EMPTY
            if (ws := state.workspace_from_grid(col, row)) is not None:
                ws_repr = WORKSPACE_OCCUPIED
                if state.workspace_is_focused(ws.id):
                    ws_repr = WORKSPACE_FOCUS
                elif state.workspace_is_visible(ws.id):
                    ws_repr = WORKSPACE_VISIBLE
            col_reprs.append(ws_repr)
        row_reprs.append(" ".join(col_reprs))
    layout_reprs.append("\n".join(row_reprs))
    if len(state.ungridable_workspaces) > 0:
        ungridables = (
            state.workspaces[wid].name for wid in state.ungridable_workspaces
        )
        layout_reprs.append("\nOther workspaces:")
        layout_reprs.append(", ".join(ungridables))
    layout_repr = "\n".join(layout_reprs)

    if verbose:
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
    id: int = field(repr=False)
    workspace_id: int = field(repr=False)
    special_workspace_id: int = field(repr=False)
    raw_data: dict = field(repr=False)

    @classmethod
    def from_hypr_json(cls, json_data):
        return cls(
            name=json_data["name"],
            enabled=not json_data["disabled"],
            focused=json_data["focused"],
            id=json_data["id"],
            workspace_id=json_data["activeWorkspace"]["id"],
            special_workspace_id=json_data["specialWorkspace"]["id"],
            raw_data=json_data,
        )


@dataclass(frozen=True)
class Workspace:
    name: str
    windows: int
    id: int = field(repr=False)
    monitor_id: int = field(repr=False)
    raw_data: dict = field(repr=False)

    @classmethod
    def from_hypr_json(cls, json_data):
        return cls(
            name=json_data["name"],
            windows=json_data["windows"],
            id=json_data["id"],
            monitor_id=json_data["monitorID"],
            raw_data=json_data,
        )

    def is_gridable(self, monitor_count: int = 999):
        try:
            parts = self.name.removeprefix("special:").split(".")
            row = parts[0]
            col = parts[1]
            int(row)
            int(col)
            if self.is_special:
                return True
            monitor = parts[2]
            monitor = int(monitor)
        except (ValueError, IndexError):
            return False
        return monitor < monitor_count

    @cached_property
    def is_special(self):
        return self.name.startswith("special:")

    @cached_property
    def grid_coords(self):
        try:
            col, row, monitor = self.name.split(".")
            return int(col), int(row)
        except ValueError:
            return None


@dataclass(frozen=True)
class Window:
    class_: str
    title: str
    focus_id: int
    workspace_id: int = field(repr=False)
    address: str = field(repr=False)
    raw_data: dict = field(repr=False)

    @classmethod
    def from_hypr_json(cls, json_data):
        return cls(
            class_=json_data["class"],
            title=json_data["title"],
            focus_id=json_data["focusHistoryID"],
            workspace_id=json_data["workspace"]["id"],
            address=json_data["address"],
            raw_data=json_data,
        )


@dataclass(frozen=True)
class State:
    monitors: dict[int, Monitor]
    workspaces: dict[int, Workspace]
    windows: dict[str, Window]
    workspace_grid: dict[(int, int), int]
    ungridable_workspaces: tuple[int, ...]
    focused_workspace_id: int
    focused_window_address: str | None

    @classmethod
    def get(cls):
        monitors = {
            (monitor := Monitor.from_hypr_json(monitor_data)).id: monitor
            for monitor_data in hypr_json("monitors")
        }
        workspaces = {
            (ws := Workspace.from_hypr_json(ws_data)).id: ws
            for ws_data in hypr_json("workspaces")
        }
        windows = {
            (window := Window.from_hypr_json(client_data)).address: window
            for client_data in hypr_json("clients")
        }
        workspace_grid = {ws.grid_coords: ws.id for ws in workspaces.values()}
        ungridable_workspaces = tuple(
            ws.id for ws in workspaces.values() if not ws.is_gridable(len(monitors))
        )
        active_workspace = hypr_json("activeworkspace")
        active_window = hypr_json("activewindow")
        return cls(
            monitors=monitors,
            workspaces=workspaces,
            windows=windows,
            workspace_grid=workspace_grid,
            ungridable_workspaces=ungridable_workspaces,
            focused_workspace_id=active_workspace["id"],
            focused_window_address=active_window.get("address"),
        )

    def monitor_workspace(self, monitor_id):
        return self.workspaces[self.monitors[monitor_id].workspace_id]

    @property
    def focused_window(self):
        return self.windows.get(self.focused_window_address)

    @property
    def last_focused_window(self):
        for window in self.windows.values():
            if window.focus_id == 0:
                return window
        raise RuntimeError("No last focused window found")

    @property
    def focused_monitor(self):
        for monitor in self.monitors.values():
            if monitor.focused:
                return monitor
        raise RuntimeError("No focused monitor found")

    @property
    def focused_workspace(self):
        return self.workspaces[self.focused_workspace_id]

    def workspace_from_grid(self, col, row):
        return self.workspaces.get(self.workspace_grid.get((col, row)))

    def workspace_is_focused(self, wid):
        ws = self.workspaces[wid]
        monitor = self.monitors[ws.monitor_id]
        return monitor.focused and monitor.workspace_id == wid

    def workspace_is_visible(self, wid):
        ws = self.workspaces[wid]
        monitor = self.monitors[ws.monitor_id]
        return monitor.workspace_id == wid


def print_list(data_name, verbose):
    for item in getattr(State.get(), data_name).values():
        if verbose:
            print(item.raw_data)
        else:
            print(item)


def switch_workspace(workspace_name):
    state = State.get()
    focused_monitor = state.focused_monitor
    commands = []
    locked_monitors = get_locked_monitors(state)
    for i, monitor in enumerate(state.monitors.values()):
        if monitor.name in locked_monitors:
            continue
        commands.append(f"focusmonitor {monitor.name}")
        commands.append(f"focusworkspaceoncurrentmonitor name:{workspace_name}.{i}")
    commands.append(f"focusmonitor {focused_monitor.name}")
    hypr_dispatch(*commands, batch_commands=True)


def move_workspace(workspace_name):
    hypr_dispatch(f"movetoworkspacesilent name:{workspace_name}.0")


def toggle_special():
    state = State.get()
    x, y = state.focused_workspace.grid_coords
    workspace_name = f"{x}.{y}"
    hypr_dispatch(f"togglespecialworkspace {workspace_name}")


def move_special():
    state = State.get()
    x, y = state.focused_workspace.grid_coords
    workspace_name = f"{x}.{y}"
    hypr_dispatch(f"movetoworkspacesilent special:{workspace_name}")


def collect_windows(off_grid_only: bool = False):
    state = State.get()
    target_ws = state.focused_workspace
    eprint(f"Target: {target_ws}")
    for window in state.windows.values():
        ws = state.workspaces[window.workspace_id]
        if off_grid_only and ws.is_gridable(len(state.monitors)):
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
    parser.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        help="be verbose",
    )
    subparsers = parser.add_subparsers(dest="command")
    info_parser = subparsers.add_parser("info", help="Show info")
    info_parser.add_argument(
        "info_type",
        choices=["workspaces", "windows", "monitors"],
        help="Info type",
    )
    switch_parser = subparsers.add_parser("switch", help="Switch to workspace")
    switch_parser.add_argument("workspace", help="Workspace to switch to")
    move_parser = subparsers.add_parser("move", help="Move focused window to workspace")
    move_parser.add_argument("workspace", help="Workspace to move window to")
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
    special_parser.add_argument(
        "--move",
        action="store_true",
        help="Move the focused window to the special workspace instead of toggling",
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
    args = parser.parse_args()

    if args.command == "info":
        print_list(args.info_type, args.verbose)
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
        if args.move:
            move_special()
        else:
            toggle_special()
    elif args.command == "switch":
        switch_workspace(args.workspace)
    elif args.command == "move":
        move_workspace(args.workspace)
    elif args.command == "collect":
        if args.all:
            collect_windows()
        else:
            collect_windows(off_grid_only=True)

    create_missing_config(Path(args.config_file))
    config = tomllib.loads(args.config_file.read_text())
    rows = config["rows"]
    columns = config["columns"]
    notification_timeout = config["notification_timeout"]
    icon = config["icon"]
    print_layout(
        rows=rows,
        columns=columns,
        notification=not args.nonotification,
        notification_timeout=notification_timeout,
        icon_file=icon,
        verbose=args.verbose,
    )


if __name__ == "__main__":
    main()
