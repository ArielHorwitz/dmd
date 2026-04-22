#!/usr/bin/env python3
import argparse
import os
import subprocess
import sys
from dataclasses import dataclass, field
from pathlib import Path

import tomllib


@dataclass
class Metadata:
    title: str | None = None
    prompt: str | None = None


@dataclass
class Entry:
    name: str
    description: str | None = None
    execute: str | None = None
    dispatch: str | None = None


@dataclass
class Menu:
    path: Path
    metadata: Metadata
    entries: list[Entry] = field(default_factory=list)


def die(msg: str) -> None:
    print(f"crowfish: {msg}", file=sys.stderr)
    try:
        subprocess.run(
            ["notify-send", "--urgency=critical", "crowfish", msg],
            check=False,
        )
    except FileNotFoundError:
        pass
    sys.exit(1)


def load_menu(path: Path) -> Menu:
    try:
        data = tomllib.loads(path.read_text())
    except FileNotFoundError:
        die(f"file not found: {path}")
    except PermissionError as e:
        die(f"cannot read {path}: {e}")
    except tomllib.TOMLDecodeError as e:
        die(f"invalid TOML in {path}: {e}")

    meta_raw = data.get("metadata", {})
    if not isinstance(meta_raw, dict):
        die(f"{path}: [metadata] must be a table")
    metadata = Metadata(
        title=meta_raw.get("title"),
        prompt=meta_raw.get("prompt"),
    )

    entries_raw = data.get("entry", [])
    if not isinstance(entries_raw, list):
        die(f"{path}: [[entry]] must be an array of tables")

    entries: list[Entry] = []
    for i, e in enumerate(entries_raw):
        if not isinstance(e, dict):
            die(f"{path}: entry {i} must be a table")
        name = e.get("name")
        if not isinstance(name, str) or not name:
            die(f"{path}: entry {i} missing required string 'name'")
        execute = e.get("execute")
        dispatch = e.get("dispatch")
        if (execute is None) == (dispatch is None):
            die(
                f"{path}: entry '{name}' must have exactly one of 'execute' or 'dispatch'"
            )
        entries.append(
            Entry(
                name=name,
                description=e.get("description"),
                execute=execute,
                dispatch=dispatch,
            )
        )

    if not entries:
        die(f"{path}: no entries")

    return Menu(path=path, metadata=metadata, entries=entries)


def run_menu(menu: Menu) -> Entry | None:
    name_width = max(len(e.name) for e in menu.entries)
    lines = []
    for e in menu.entries:
        second = e.description or e.execute or e.dispatch
        lines.append(f"{e.name:<{name_width}}  ¦  {second}")

    prompt = menu.metadata.prompt if menu.metadata.prompt is not None else "> "
    cmd = ["fuzzel", "--dmenu", "--index", "--only-match", "--prompt", prompt]
    if menu.metadata.title:
        cmd += ["--mesg", menu.metadata.title]

    try:
        result = subprocess.run(
            cmd,
            input="\n".join(lines),
            capture_output=True,
            text=True,
            check=False,
        )
    except FileNotFoundError:
        die("fuzzel not found in PATH")

    if result.returncode not in (0, 1):
        die(f"fuzzel exited {result.returncode}: {result.stderr.strip()}")

    out = result.stdout.strip()
    if not out:
        return None

    try:
        idx = int(out)
    except ValueError:
        die(f"fuzzel returned unexpected output: {out!r}")

    if not 0 <= idx < len(menu.entries):
        die(f"fuzzel returned out-of-range index: {idx}")

    return menu.entries[idx]


def dispatch_entry(menu: Menu, entry: Entry) -> None:
    if entry.execute is not None:
        os.execvp("bash", ["bash", "-c", entry.execute])
    if entry.dispatch is not None:
        new_path = (menu.path.parent / entry.dispatch).resolve()
        os.execv(sys.executable, [sys.executable, __file__, str(new_path)])


def main() -> None:
    parser = argparse.ArgumentParser(prog="crowfish")
    parser.add_argument(
        "file",
        type=Path,
        nargs="?",
        default=Path.home() / ".config" / "crowfish" / "crowfish.toml",
    )
    args = parser.parse_args()

    menu = load_menu(args.file.resolve())
    selected = run_menu(menu)
    if selected is None:
        return
    dispatch_entry(menu, selected)


if __name__ == "__main__":
    main()
