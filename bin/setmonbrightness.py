#!/usr/bin/python

import subprocess
import argparse


MAX_STEPS = 10

def run(*command, **kwargs):
    kwargs = dict(capture_output=True, check=True) | kwargs
    result = subprocess.run(command, **kwargs)
    return result.stdout.decode().strip()


def get_device():
    name = run("ls", "-1", "/sys/class/backlight/")
    return f"/sys/class/backlight/{name}"


def get_brightness(device):
    return int(run("cat", f"{device}/brightness"))


def get_max_brightness(device):
    return int(run("cat", f"{device}/max_brightness"))


def set_brightness(device, brightness):
    run("tee", f"{device}/brightness", input=str(brightness).encode())


def main():
    # Parse args
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-i",
        "--increase",
        help="Increase brightness",
        action="store_true",
    )
    parser.add_argument(
        "-d",
        "--decrease",
        help="Decrease brightness",
        action="store_true",
    )
    parser.add_argument(
        "-s",
        "--set",
        help="Set brightness (0-10)",
        type=int,
    )
    args = parser.parse_args()
    # Collect parameters
    device = get_device()
    brightness = get_brightness(device)
    max_brightness = get_max_brightness(device)
    # Find new brightness value
    if args.set is not None:
        steps = max(0, min(int(args.set), MAX_STEPS))
        value = max_brightness * (2 ** (-MAX_STEPS + steps))
    elif args.increase:
        value = max(1, brightness) * 2
    elif args.decrease:
        value = brightness / 2
    else:
        value = max_brightness
    new_brightness = round(max(0, min(value, max_brightness)))
    print(f"Setting brightness: {new_brightness} / {max_brightness}")
    set_brightness(device, new_brightness)


if __name__ == "__main__":
    main()
