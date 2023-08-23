#!/bin/python

import argparse
import shlex
import subprocess


def run(*commands):
    result = subprocess.run(commands, capture_output=True)
    if result.returncode != 0:
        raise Exception(f"{result}\n{result.stdout}")
    return result.stdout.decode().strip()


def main():
    # Parse args
    parser = argparse.ArgumentParser()
    parser.add_argument("OUTPUT", nargs="*", help="List of outputs from left to right")
    parser.add_argument("-f", "--file", help="Collect list of outputs from file")
    parser.add_argument("-p", "--primary", help="Set primary output")
    parser.add_argument(
        "-l",
        "--list",
        help="List all outputs and quit",
        action="store_true",
    )
    args = parser.parse_args()
    if args.list:
        print(run("xrandr", "--listmonitors"))
        quit()
    if args.file:
        outputs = shlex.split(run("xargs", "--arg-file", shlex.quote(args.file)))
    else:
        outputs = args.OUTPUT
    if len(outputs) > 1:
        for outl, outr in zip(outputs[:-1], outputs[1:]):
            print(f"{outl} | {outr}")
            run("xrandr", "--output", outr, "--right-of", outl)
    if args.primary:
        run("xrandr", "--output", args.primary, "--primary")
        print(f"Set primary: {args.primary}")


if __name__ == "__main__":
    main()
