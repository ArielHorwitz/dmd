#! /bin/python

import subprocess
import sys
import time
import argparse


ICONS = {
    "sink": "/usr/share/icons/dmd/speaker3.svg",
    "sink_mute": "/usr/share/icons/dmd/speaker0.svg",
    "source": "/usr/share/icons/dmd/mic1.svg",
    "source_mute": "/usr/share/icons/dmd/mic0.svg",
}


def run_cmd(*cmd):
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        raise RuntimeError(f"{result.stderr.strip()}")
    return result.stdout.strip()


def get_default_device(device_type):
    return f"@DEFAULT_{device_type.upper()}@"


def get_volume(device_type):
    device_name = get_default_device(device_type)
    volumes = run_cmd("pactl", f"get-{device_type}-volume", device_name)
    parts = volumes.split()
    left = int(parts[4].rstrip("%"))
    right = int(parts[11].rstrip("%")) if len(parts) > 11 else left
    return (left + right) // 2


def set_volume(device_type, volume):
    device_name = get_default_device(device_type)
    run_cmd("pactl", f"set-{device_type}-volume", device_name, f"{volume}%")


def set_mute(device_type, mute_status):
    device_name = get_default_device(device_type)
    mute_status = str(int(mute_status))
    run_cmd("pactl", f"set-{device_type}-mute", device_name, mute_status)


def print_mute(device_type):
    device_name = get_default_device(device_type)
    output = run_cmd("pactl", f"get-{device_type}-mute", device_name)
    return output == "Mute: yes"


def fade_out(device_type, fade_seconds=5):
    initial_volume = get_volume(device_type)
    current_volume = initial_volume
    step_delay = fade_seconds / initial_volume

    print(
        f"Fading out volume of {initial_volume}% in steps of 1% of {step_delay:.2f} seconds over {fade_seconds} seconds",
        file=sys.stderr,
    )
    while True:
        if current_volume != get_volume(device_type):
            print("Volume changed externally, stopping fade out", file=sys.stderr)
            break
        current_volume = max(0, current_volume - 1)
        set_volume(device_type, current_volume)
        if current_volume <= 0:
            break
        time.sleep(step_delay)


def notify(device_type):
    current_volume = get_volume(device_type)
    is_muted = print_mute(device_type)

    if is_muted:
        volume_text = f"{current_volume}% [MUTED]"
        icon = ICONS[f"{device_type}_mute"]
    else:
        volume_text = f"{current_volume}%"
        icon = ICONS[device_type]

    if device_type == "sink":
        description = run_cmd("adevice")
    else:
        description = run_cmd("adevice", "--mic")

    cmd = [
        "notify-send",
        "-u",
        "low",
        "-t",
        "1500",
        "-i",
        icon,
        "-h",
        f"int:value:{current_volume}",
        "-h",
        f"string:synchronous:volume_{device_type}",
        f"Volume: {volume_text}",
        f"{description} ({device_type})",
    ]
    subprocess.run(cmd)


def main():
    parser = argparse.ArgumentParser(
        prog="avolume",
        description="Get and set volume of default device.",
    )
    parser.add_argument("-o", "--volume", type=int, help="Set volume percentage")
    parser.add_argument("-i", "--increase", type=float, help="Increase volume percentage")
    parser.add_argument("-d", "--decrease", type=float, help="Decrease volume percentage")
    parser.add_argument(
        "-O",
        "--fade-out",
        type=float,
        help="Fade out volume over seconds",
    )
    parser.add_argument("--mic", action="store_true", help="Use source instead of sink")
    mute_group = parser.add_mutually_exclusive_group()
    mute_group.add_argument("-m", "--mute", action="store_true", help="Mute device")
    mute_group.add_argument("-u", "--unmute", action="store_true", help="Unmute device")
    parser.add_argument(
        "-M",
        "--is-mute",
        action="store_true",
        help="Print mute status",
    )
    parser.add_argument(
        "-N",
        "--notification",
        action="store_true",
        help="Show notification",
    )
    parser.add_argument(
        "--notify-all",
        action="store_true",
        help="Show notifications for sink and source",
    )

    args = parser.parse_args()
    device_type = "source" if args.mic else "sink"

    if args.volume is not None:
        set_volume(device_type, args.volume)
    if args.increase is not None:
        set_volume(device_type, f"+{args.increase}")
    if args.decrease is not None:
        set_volume(device_type, f"-{args.decrease}")
    if args.mute:
        set_mute(device_type, 1)
    if args.unmute:
        set_mute(device_type, 0)
    if args.fade_out is not None:
        fade_out(device_type, args.fade_out)

    if args.is_mute:
        print(print_mute(device_type))
    elif args.notify_all:
        notify("sink")
        time.sleep(0.1)
        notify("source")
    else:
        print(get_volume(device_type))
        if args.notification:
            notify(device_type)


if __name__ == "__main__":
    main()
