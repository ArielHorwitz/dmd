#! /bin/python

import argparse
import json
import subprocess
import sys


def hypr_json(*args):
    result = subprocess.run(
        ["hyprctl", "-j", *args],
        capture_output=True,
        check=True,
    )
    if result.stderr:
        raise RuntimeError(result.stderr.decode())
    return json.loads(result.stdout.decode())


def close_window(address):
    result = subprocess.run(
        [
            "hyprctl",
            "dispatch",
            f"hl.dsp.window.close({{ window = 'address:{address}' }})",
        ],
        capture_output=True,
        check=True,
    )
    if result.stderr:
        raise RuntimeError(result.stderr.decode())


def get_cell_workspace_names(special=False):
    command = ["spacemux", "cell", "list"]
    if special:
        command.append("--special")
    result = subprocess.run(command, capture_output=True, check=True)
    return result.stdout.decode().splitlines()


def main():
    parser = argparse.ArgumentParser(
        "wsclose",
        description="Close all windows in the current workspace",
    )
    parser.add_argument(
        "-v",
        "--visible",
        action="store_true",
        help="Include all workspaces in the focused cell",
    )
    parser.add_argument(
        "-s",
        "--special",
        action="store_true",
        help="Include the special workspace of the focused cell",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print windows that would be closed without closing them",
    )
    args = parser.parse_args()

    if args.visible or args.special:
        workspace_names = get_cell_workspace_names(special=args.special)
        if not args.visible:
            active_ws = hypr_json("activeworkspace")
            workspace_names = [
                n
                for n in workspace_names
                if n == active_ws["name"] or n.startswith("special:")
            ]
    else:
        active_ws = hypr_json("activeworkspace")
        workspace_names = [active_ws["name"]]

    clients = hypr_json("clients")
    targets = sorted(
        (c for c in clients if c["workspace"]["name"] in workspace_names),
        key=lambda c: (c["workspace"]["name"], c["class"], c["title"]),
    )

    if not targets:
        return

    for client in targets:
        address = client["address"]
        label = f"[{client['class']}] {client['title']}"
        if args.dry_run:
            print(f"Would close: {label} ({address})")
        else:
            print(f"Closing: {label}", file=sys.stderr)
            close_window(address)


if __name__ == "__main__":
    main()
