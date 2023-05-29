#!/usr/bin/python

import subprocess
import argparse


def run(*command, **kwargs):
    kwargs = dict() | kwargs
    result = subprocess.run(command, check=True)
    return result.stdout.decode().strip()


def main():
    # Parse args
    parser = argparse.ArgumentParser()
    parser.add_argument("-s", "--show", help="Show scratchpad #", type=int)
    parser.add_argument("-m", "--move", help="Move to scratchpad #", type=int)
    args = parser.parse_args()
    if args.show:
        assert 0 < args.show < 10
        subprocess.run(
            ["i3-msg", f'[class="Scratchpad {args.show}"] scratchpad show'],
            check=True,
        )
    elif args.move:
        assert 0 < args.move < 10
        set_command = [
            "xdotool",
            "getactivewindow",
            "set_window",
            "--class",
            f"'Scratchpad {args.move}'",
        ]
        subprocess.run(set_command, check=True)
        subprocess.run(["i3-msg", "move", "scratchpad"], check=True)
    else:
        raise Exception("Missing argument, must use -s or -m")


if __name__ == "__main__":
    main()
