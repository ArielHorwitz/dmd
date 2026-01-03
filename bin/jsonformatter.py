#! /bin/python

import argparse
import json
import sys
from pathlib import Path

parser = argparse.ArgumentParser(
    "indent-json",
    description="Format JSON with or without indentation.",
)
parser.add_argument(
    "FILE",
    type=Path,
    nargs="?",
    help="Read from file instead of stdin",
)
parser.add_argument(
    "-I",
    "--indent",
    type=int,
    default=4,
    help="Indentation in characters [default: 4]",
)
parser.add_argument(
    "-m",
    "--minify",
    action="store_true",
    help="Minify: remove indentation (overrides --indent)",
)
parser.add_argument(
    "-i",
    "--inplace",
    action="store_true",
    help="Overwrite input file in place (overrides --output-file)",
)
parser.add_argument(
    "-o", "--output-file", type=Path, required=False, help="Output to file"
)
args = parser.parse_args()

if args.FILE is not None:
    if not (input_file := args.FILE).exists():
        print(f"File {input_file} does not exist", file=sys.stderr)
        exit(1)
    data = json.loads(input_file.read_text())
else:
    data = json.loads(sys.stdin.read())


indentation = args.indent if not args.minify else None
output_string = json.dumps(data, indent=indentation)

if args.FILE and args.inplace:
    input_file.write_text(output_string)
elif (output_file := args.output_file) is None:
    print(output_string)
else:
    output_file.write_text(output_string)
