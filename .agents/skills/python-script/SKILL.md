---
name: python-script
description: How to write python scripts for bin/. Use when creating a new Python script, modifying an existing one, adding arguments or features, or writing any CLI tool in Python for this repo.
---

# Writing python scripts

Scripts live in `bin/` and have their file extensions stripped at install time (`foo.py` becomes `foo` on PATH). Write all new scripts in `bin/` with a `.py` extension.

## Starting a new script

Start every script with:

```python
#! /bin/python

import argparse
```

## Constraints

Only use the standard library and builtins. No third-party packages — scripts must run without pip-installing anything. The system runs Arch Linux (rolling release), so the latest Python version is available. Run `python --version` to check.

## Argument parsing

Use `argparse` for all CLI interfaces:

```python
def main():
    parser = argparse.ArgumentParser(
        prog="script-name",
        description="What this script does",
    )
    parser.add_argument("target", help="Positional argument")
    parser.add_argument("-v", "--verbose", action="store_true", help="Verbose output")
    parser.add_argument("-n", "--count", type=int, default=1, help="Number of times")
    args = parser.parse_args()

    # args.target, args.verbose, args.count are now available


if __name__ == "__main__":
    main()
```

Wrap the main logic in a `main()` function and call it from `if __name__ == "__main__":`.

## Notifications and output

Desktop notifications use `notify-send` via subprocess:

```python
import subprocess

subprocess.run([
    "notify-send",
    "-u", "normal",
    "-i", "/usr/share/icons/dmd/monitor.svg",
    "Title",
    "Body message",
])
```

For terminal output, use `print()` directly. `printcolor` is available on PATH for colored output:

```python
subprocess.run(["printcolor", "-s", "ok", "Operation succeeded"])
subprocess.run(["printcolor", "-s", "error", "Something went wrong"])
```

## Complete example

A minimal but complete script showing all conventions together:

```python
#! /bin/python

import argparse
import subprocess
from pathlib import Path


def notify(title: str, body: str, urgency: str = "normal"):
    subprocess.run(["notify-send", "-u", urgency, title, body])


def main():
    parser = argparse.ArgumentParser(
        prog="file-summary",
        description="Summarize a file's properties",
    )
    parser.add_argument("file", help="File to summarize")
    parser.add_argument("-n", "--notify", action="store_true", help="Show notification")
    args = parser.parse_args()

    path = Path(args.file)
    if not path.exists():
        print(f"error: file not found: {path}", file=sys.stderr)
        raise SystemExit(1)

    size = path.stat().st_size
    message = f"{path.name}: {size} bytes"

    if args.notify:
        notify("file-summary", message)
    else:
        print(message)


if __name__ == "__main__":
    main()
```
