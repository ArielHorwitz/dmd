#!/usr/bin/env python3
import argparse
import json
import math
import os
import subprocess
import sys
import time
from dataclasses import dataclass, field
from pathlib import Path

import tomllib


@dataclass
class Metadata:
    title: str | None = None
    prompt: str | None = None
    sort_method: str = "recent"


@dataclass
class Entry:
    description: str | None = None
    execute: str | None = None
    dispatch: str | None = None
    icon: str | None = None


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


def hits_path() -> Path:
    base = os.environ.get("XDG_CACHE_HOME")
    if base:
        return Path(base) / "crowfish" / "hits.json"
    return Path.home() / ".cache" / "crowfish" / "hits.json"


def load_hits() -> dict:
    path = hits_path()
    try:
        file_text = path.read_text()
    except FileNotFoundError:
        return {}
    except PermissionError as exc:
        die(f"cannot read {path}: {exc}")
    try:
        data = json.loads(file_text)
    except json.JSONDecodeError as exc:
        die(f"invalid JSON in {path}: {exc}")
    if not isinstance(data, dict):
        die(f"{path}: root must be a JSON object")
    hits_by_menu_path: dict[str, dict] = {}
    for menu_path_key, entries_object in data.items():
        if not isinstance(menu_path_key, str):
            die(f"{path}: menu keys must be strings")
        if not isinstance(entries_object, dict):
            die(f"{path}: menu {menu_path_key!r} value must be an object")
        cache_entries: dict[str, dict] = {}
        for entry_key, entry_object in entries_object.items():
            if not isinstance(entry_key, str):
                die(f"{path}: entry keys must be strings")
            if not isinstance(entry_object, dict):
                die(f"{path}: entry {entry_key!r} must be an object")
            if set(entry_object.keys()) != {"count", "last"}:
                die(f"{path}: entry {entry_key!r} must have only count and last")
            hit_count = entry_object["count"]
            last_hit_raw = entry_object["last"]
            if isinstance(hit_count, bool) or not isinstance(hit_count, int) or hit_count < 0:
                die(f"{path}: entry {entry_key!r} count must be a non-negative integer")
            if isinstance(last_hit_raw, bool) or not isinstance(last_hit_raw, (int, float)):
                die(f"{path}: entry {entry_key!r} last must be a number")
            last_hit_timestamp = float(last_hit_raw)
            if not math.isfinite(last_hit_timestamp) or last_hit_timestamp <= 0:
                die(f"{path}: entry {entry_key!r} last must be a finite timestamp > 0")
            cache_entries[entry_key] = {
                "count": hit_count,
                "last": last_hit_timestamp,
            }
        hits_by_menu_path[menu_path_key] = cache_entries
    return hits_by_menu_path


def save_hits(hits: dict) -> None:
    path = hits_path()
    path.parent.mkdir(parents=True, exist_ok=True)
    temp_path = path.with_suffix(".json.tmp")
    try:
        temp_path.write_text(json.dumps(hits, ensure_ascii=False) + "\n")
        os.replace(temp_path, path)
    except OSError as exc:
        die(f"cannot write {path}: {exc}")


def entry_cache_key(entry: Entry) -> str:
    description_part = entry.description or ""
    execute_part = entry.execute or ""
    dispatch_part = entry.dispatch or ""
    return f"{description_part}\x1f{execute_part}\x1f{dispatch_part}"


def record_hit(menu: Menu, entry: Entry, hits: dict) -> None:
    resolved_menu_path = str(menu.path.resolve())
    cache_key = entry_cache_key(entry)
    menu_cache = hits.setdefault(resolved_menu_path, {})
    now = time.time()
    previous_record = menu_cache.get(cache_key)
    if previous_record is None:
        menu_cache[cache_key] = {"count": 1, "last": now}
    else:
        menu_cache[cache_key] = {
            "count": previous_record["count"] + 1,
            "last": now,
        }
    save_hits(hits)


def load_menu(path: Path) -> Menu:
    try:
        data = tomllib.loads(path.read_text())
    except FileNotFoundError:
        die(f"file not found: {path}")
    except PermissionError as exc:
        die(f"cannot read {path}: {exc}")
    except tomllib.TOMLDecodeError as exc:
        die(f"invalid TOML in {path}: {exc}")

    meta_raw = data.get("metadata", {})
    if not isinstance(meta_raw, dict):
        die(f"{path}: [metadata] must be a table")
    sort_method = meta_raw.get("sort_method", "recent")
    if not isinstance(sort_method, str):
        die(f"{path}: metadata.sort_method must be a string")
    if sort_method not in ("recent", "count", "manual"):
        die(f'{path}: metadata.sort_method must be "recent", "count", or "manual"')
    metadata = Metadata(
        title=meta_raw.get("title"),
        prompt=meta_raw.get("prompt"),
        sort_method=sort_method,
    )

    entries_raw = data.get("entry", [])
    if not isinstance(entries_raw, list):
        die(f"{path}: [[entry]] must be an array of tables")

    entries: list[Entry] = []
    for index, raw_entry in enumerate(entries_raw):
        if not isinstance(raw_entry, dict):
            die(f"{path}: entry {index} must be a table")
        execute = raw_entry.get("execute")
        dispatch = raw_entry.get("dispatch")
        if (execute is None) == (dispatch is None):
            die(
                f"{path}: entry {index} must have exactly one of 'execute' or 'dispatch'"
            )
        entries.append(
            Entry(
                description=raw_entry.get("description"),
                execute=execute,
                dispatch=dispatch,
                icon=raw_entry.get("icon"),
            )
        )

    if not entries:
        die(f"{path}: no entries")

    return Menu(path=path, metadata=metadata, entries=entries)


def run_menu(menu: Menu, hits: dict) -> Entry | None:
    indexed = list(enumerate(menu.entries))
    sort_method = menu.metadata.sort_method
    if sort_method == "recent":
        resolved_menu_path = str(menu.path.resolve())
        menu_hits = hits.get(resolved_menu_path, {})

        def sort_key_recent(
            indexed_entry: tuple[int, Entry],
        ) -> tuple[int, float, int]:
            original_index, entry = indexed_entry
            key = entry_cache_key(entry)
            cached = menu_hits.get(key)
            if cached is None:
                return (1, 0.0, original_index)
            return (0, -cached["last"], original_index)

        indexed.sort(key=sort_key_recent)
    elif sort_method == "count":
        resolved_menu_path = str(menu.path.resolve())
        menu_hits = hits.get(resolved_menu_path, {})

        def sort_key_count(indexed_entry: tuple[int, Entry]) -> tuple[int, int]:
            original_index, entry = indexed_entry
            key = entry_cache_key(entry)
            cached = menu_hits.get(key)
            hit_count = cached["count"] if cached is not None else 0
            return (-hit_count, original_index)

        indexed.sort(key=sort_key_count)
    display_entries = [entry for _, entry in indexed]

    desc_width = max(len(entry.description or "") for entry in display_entries)
    lines = []
    for entry in display_entries:
        desc = entry.description or ""
        entry_command = entry.execute or entry.dispatch
        line = f"{desc:<{desc_width}}  ¦  {entry_command}"
        if entry.icon:
            line += f"\0icon\x1f{entry.icon}"
        lines.append(line)

    prompt = menu.metadata.prompt if menu.metadata.prompt is not None else "> "
    fuzzel_argv = ["fuzzel", "--dmenu", "--index", "--only-match", "--prompt", prompt]
    if menu.metadata.title:
        fuzzel_argv += ["--mesg", menu.metadata.title]

    try:
        result = subprocess.run(
            fuzzel_argv,
            input="\n".join(lines),
            capture_output=True,
            text=True,
            check=False,
        )
    except FileNotFoundError:
        die("fuzzel not found in PATH")

    if result.returncode not in (0, 1):
        die(f"fuzzel exited {result.returncode}: {result.stderr.strip()}")

    fuzzel_stdout = result.stdout.strip()
    if not fuzzel_stdout:
        return None

    try:
        selected_index = int(fuzzel_stdout)
    except ValueError:
        die(f"fuzzel returned unexpected output: {fuzzel_stdout!r}")

    if not 0 <= selected_index < len(display_entries):
        die(f"fuzzel returned out-of-range index: {selected_index}")

    return display_entries[selected_index]


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
    hits = load_hits()
    selected = run_menu(menu, hits)
    if selected is None:
        return
    record_hit(menu, selected, hits)
    dispatch_entry(menu, selected)


if __name__ == "__main__":
    main()
