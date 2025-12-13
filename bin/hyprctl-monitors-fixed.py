#! /bin/python

import argparse
import json
import subprocess
import sys
from pathlib import Path

APP_DESCRIPTION = "Get monitor info from hyprctl with transformed dimensions"
APP_NAME = Path(__file__).name.removesuffix(".py")
ROTATED_90_DEGREES_TRANSFORMS = (1, 3, 5, 7)


def run_command(*args):
    result = subprocess.run(
        args,
        capture_output=True,
        check=True,
    )
    if result.stderr:
        print(result.stderr.decode(), file=sys.stderr)
    return result.stdout.decode()


def main():
    parser = argparse.ArgumentParser(APP_NAME, description=APP_DESCRIPTION)
    parser.add_argument(
        "--focused",
        action="store_true",
        help="Show only the focused monitor",
    )
    args = parser.parse_args()
    monitors = json.loads(run_command("hyprctl", "monitors", "-j"))
    for monitor in monitors:
        if monitor["transform"] in ROTATED_90_DEGREES_TRANSFORMS:
            monitor["transformed_width"] = monitor["height"]
            monitor["transformed_height"] = monitor["width"]
        else:
            monitor["transformed_width"] = monitor["width"]
            monitor["transformed_height"] = monitor["height"]
        if args.focused and monitor["focused"]:
            print(json.dumps(monitor))
            return
    print(json.dumps(monitors))


if __name__ == "__main__":
    main()
