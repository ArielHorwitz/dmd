#!/usr/bin/env python3
import argparse
import json
import subprocess
import sys


def load_nodes():
    r = subprocess.run(
        ["daudio", "list", "--json"],
        check=False,
        capture_output=True,
        text=True,
    )
    if r.returncode != 0:
        print(r.stderr.strip() or r.stdout.strip() or "daudio list failed", file=sys.stderr)
        sys.exit(r.returncode or 1)
    out = []
    for line in r.stdout.splitlines():
        line = line.strip()
        if line:
            out.append(json.loads(line))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--sink", action="store_true")
    ap.add_argument("--source", action="store_true")
    args = ap.parse_args()
    if args.sink and args.source:
        print("use at most one of --sink / --source", file=sys.stderr)
        sys.exit(2)
    nodes = load_nodes()
    if args.sink:
        nodes = [n for n in nodes if not n["is_source"]]
    elif args.source:
        nodes = [n for n in nodes if n["is_source"]]
    if not nodes:
        print("no audio devices to show", file=sys.stderr)
        sys.exit(1)
    nodes.sort(
        key=lambda n: (
            not n["is_default"],
            (n["nick"] or "").lower(),
            (n["name"] or "").lower(),
        )
    )
    nick_w = max(len(n["nick"] or n["name"] or "?") for n in nodes)
    lines = []
    for n in nodes:
        nick = n["nick"] or n["name"] or "?"
        name = n["name"] or ""
        line = f"{nick:<{nick_w}}  ¦  {name}"
        if n["is_source"]:
            icon = "mic-on" if n["is_default"] else "mic-ready"
        else:
            icon = "audio-on" if n["is_default"] else "audio-ready"
        line += f"\0icon\x1f{icon}"
        lines.append(line)
    fuzzel = [
        "fuzzel",
        "--dmenu",
        "--index",
        "--only-match",
        "--mesg",
        "Select default audio device",
    ]
    r = subprocess.run(
        fuzzel,
        input="\n".join(lines),
        capture_output=True,
        text=True,
        check=False,
    )
    if r.returncode == 1:
        sys.exit(0)
    if r.returncode != 0:
        print(r.stderr.strip() or "fuzzel failed", file=sys.stderr)
        sys.exit(r.returncode or 1)
    out = r.stdout.strip()
    if not out:
        sys.exit(0)
    try:
        idx = int(out)
    except ValueError:
        print(f"unexpected fuzzel output: {out!r}", file=sys.stderr)
        sys.exit(1)
    if not 0 <= idx < len(nodes):
        print(f"out-of-range index: {idx}", file=sys.stderr)
        sys.exit(1)
    dev_id = nodes[idx]["id"]
    dr = subprocess.run(
        ["daudio", "device", "--id", str(dev_id), "-N"],
        check=False,
    )
    if dr.returncode != 0:
        sys.exit(dr.returncode or 1)


if __name__ == "__main__":
    main()
