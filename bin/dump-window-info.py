#! /bin/python

import argparse
import json
import os
import socket
import subprocess
import sys
import tempfile
import time
from pathlib import Path
from typing import Optional

NOTIFICATION_ICON = "/usr/share/icons/dmd/monitor.svg"
LOADING_ICON = "/usr/share/icons/dmd/loading.svg"


def hypr_clients() -> list[dict]:
    result = subprocess.run(
        ["hyprctl", "-j", "clients"],
        capture_output=True,
        check=True,
    )
    return json.loads(result.stdout.decode())


def normalize_address(address: str) -> str:
    address = address.strip().lower()
    if not address.startswith("0x"):
        address = f"0x{address}"
    return address


def find_client(address: str) -> Optional[dict]:
    for client in hypr_clients():
        if normalize_address(client.get("address", "")) == address:
            return client
    return None


def synthesize_client(
    address: str, workspace: str, window_class: str, title: str
) -> dict:
    # Fallback for windows that vanished before we could query their full details.
    # The class/title from the open event stand in for the missing fields.
    return {
        "address": address,
        "class": window_class,
        "initialClass": window_class,
        "title": title,
        "initialTitle": title,
        "pid": None,
        "xwayland": None,
        "floating": None,
        "workspace": {"name": workspace},
        "synthesized": True,
    }


def watch(duration: float) -> list[dict]:
    try:
        instance_sig = os.environ["HYPRLAND_INSTANCE_SIGNATURE"]
        runtime_dir = os.environ["XDG_RUNTIME_DIR"]
    except KeyError as error:
        print(f"error: missing environment variable {error}", file=sys.stderr)
        raise SystemExit(1)

    socket_path = Path(runtime_dir).joinpath("hypr", instance_sig, ".socket2.sock")

    records: dict[str, dict] = {}
    for client in hypr_clients():
        client["watch"] = {
            "present_at_start": True,
            "opened_at": None,
            "closed_at": None,
        }
        records[normalize_address(client.get("address", ""))] = client

    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    sock.connect(str(socket_path))

    print(
        f"Watching {duration:.0f}s for windows opening and closing...", file=sys.stderr
    )

    start_time = time.monotonic()
    buffer = ""
    try:
        while True:
            remaining = duration - (time.monotonic() - start_time)
            if remaining <= 0:
                break
            sock.settimeout(remaining)
            try:
                data = sock.recv(4096).decode()
            except socket.timeout:
                break
            if not data:
                break
            buffer += data
            while "\n" in buffer:
                line, buffer = buffer.split("\n", 1)
                handle_event(line, records, start_time)
    finally:
        sock.close()

    return list(records.values())


def handle_event(line: str, records: dict[str, dict], start_time: float) -> None:
    event, _, payload = line.partition(">>")
    elapsed = time.monotonic() - start_time

    if event == "openwindow":
        address, workspace, window_class, title = (
            payload.split(",", 3) + ["", "", "", ""]
        )[:4]
        address = normalize_address(address)
        existing = records.get(address)
        client = find_client(address) or synthesize_client(
            address, workspace, window_class, title
        )
        client["watch"] = {
            "present_at_start": bool(
                existing and existing["watch"]["present_at_start"]
            ),
            "opened_at": elapsed,
            "closed_at": existing["watch"]["closed_at"] if existing else None,
        }
        records[address] = client
        print(
            f"  [+{elapsed:5.2f}s] OPEN   class={window_class!r} title={title!r}",
            file=sys.stderr,
        )
    elif event == "closewindow":
        address = normalize_address(payload)
        if address in records:
            records[address]["watch"]["closed_at"] = elapsed
        print(f"  [+{elapsed:5.2f}s] CLOSE  {address}", file=sys.stderr)


def notify_start(*, watched: bool, duration: float) -> None:
    if watched:
        body = f"Watching {duration:.0f}s for windows opening and closing..."
    else:
        body = "Capturing windows..."
    subprocess.run(
        [
            "notify-send",
            "-u",
            "low",
            "-i",
            LOADING_ICON,
            "-h",
            "string:synchronous:dump-window-info",
            "dump-window-info",
            body,
        ]
    )


def notify_end(clients: list[dict], *, watched: bool, output: Path) -> None:
    if watched:
        opened = sum(
            1 for client in clients if client["watch"]["opened_at"] is not None
        )
        closed = sum(
            1 for client in clients if client["watch"]["closed_at"] is not None
        )
        body = (
            f"{len(clients)} window(s), {opened} opened / {closed} closed during watch."
        )
    else:
        body = f"{len(clients)} window(s) captured."
    body += f"\nSaved to {output}"
    subprocess.run(
        [
            "notify-send",
            "-t",
            "8000",
            "-i",
            NOTIFICATION_ICON,
            "-h",
            "string:synchronous:dump-window-info",
            "dump-window-info",
            body,
        ]
    )


def main():
    parser = argparse.ArgumentParser(
        prog="dump-window-info",
        description=(
            "Dump all Hyprland windows as JSON (like hyprctl clients). With "
            "--watch, also include windows that open and close during the watch, "
            "each annotated with a 'watch' object."
        ),
    )
    parser.add_argument(
        "-w",
        "--watch",
        type=float,
        default=None,
        metavar="SECONDS",
        help="Also report windows opening and closing during SECONDS, after the snapshot",
    )
    parser.add_argument(
        "-o",
        "--output",
        type=Path,
        help="Redirect the file copy of the output to this path (default: temp file)",
    )
    parser.add_argument(
        "-n",
        "--notify",
        action="store_true",
        help="Show a desktop notification at start and end",
    )
    args = parser.parse_args()

    watched = args.watch is not None
    duration = args.watch if watched else 0.0
    output = args.output or Path(tempfile.gettempdir()).joinpath(
        "dump-window-info.json"
    )

    if args.notify:
        notify_start(watched=watched, duration=duration)

    clients = watch(duration) if watched else hypr_clients()
    report = json.dumps(clients, indent=2)

    # Always emit to both stdout and the file copy.
    print(report)
    output.write_text(report + "\n")
    print(f"\n(output also written to {output})", file=sys.stderr)

    if args.notify:
        notify_end(clients, watched=watched, output=output)


if __name__ == "__main__":
    main()
