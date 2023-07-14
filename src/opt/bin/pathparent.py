#!/usr/bin/python
# Get the parent directory of a file path.

import argparse
import sys
from pathlib import Path

DESCRIPTION = """Get the parent directory of a given path.

If basepath is given and filepath is relative, concatenate the paths.

Use --resolve to resolve symlinks and expand the path as an absolute path.

Use --confirm-exists to ensure the resulting path exists.
"""

# Parse args
parser = argparse.ArgumentParser(description="")
parser.add_argument("FILEPATH", help="File path")
parser.add_argument("BASEPATH", nargs="?", help="Absolute base path")
parser.add_argument(
    "-r",
    "--resolve",
    action="store_true",
    help="Resolve links and expand absolute",
)
parser.add_argument(
    "-e",
    "--confirm-exists",
    action="store_true",
    help="Fail if result does not exist",
)
args = parser.parse_args()

# Naive result
result = Path(args.FILEPATH).parent

# Add base if result is relative
if not result.is_absolute() and args.BASEPATH is not None:
    base = Path(args.BASEPATH)
    result = base / result
    if not result.is_relative_to(base):
        print(
            f"Filepath '{result}' is not relative to basepath '{base}'",
            file=sys.stderr,
        )
        quit(1)

# Resolve and expand
if args.resolve:
    result = result.resolve()

# Confirm exists
if args.confirm_exists and not result.exists():
    print(f"Resulting path does not exist: {result}", file=sys.stderr)
    quit(1)

print(result)

