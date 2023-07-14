#!/usr/bin/python
# Get the parent directory of a file path.

import argparse
import sys
from pathlib import Path

parser = argparse.ArgumentParser()
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
    help="Fail if final result does not exist",
)
args = parser.parse_args()
path = Path(args.FILEPATH)
if args.BASEPATH is None:
    base = Path("/")
else:
    base = Path(args.BASEPATH)
parent = (base / path).parent
if not parent.is_relative_to(base):
    print(
        f"Filepath '{path}' is not relative to basepath '{base}'",
        file=sys.stderr,
    )
    quit(1)
if args.resolve:
    parent = parent.resolve()
if args.confirm_exists and not parent.exists():
    print(f"Result does not exist: {parent}", file=sys.stderr)
    quit(1)
print(parent)

