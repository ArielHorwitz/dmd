#! /bin/python

import argparse
import datetime
import os
import subprocess
import sys
import time
import uuid
from typing import Optional

icon = "/usr/share/icons/dmd/clock.svg"
notification_id = uuid.uuid4()
BUSY_WAIT_INTERVAL_MS = 50


def parse_duration(s: str) -> float:
    multipliers = {"s": 1, "m": 60, "h": 3600}
    if s and s[-1] in multipliers:
        unit = s[-1]
        number = s[:-1]
    else:
        unit = "s"
        number = s
    try:
        return float(number) * multipliers[unit]
    except ValueError:
        return None


def parse_absolute(s: str) -> float:
    parts = s.split(":")
    if len(parts) not in (2, 3):
        return None
    try:
        h, m = int(parts[0]), int(parts[1])
        sec = int(parts[2]) if len(parts) == 3 else 0
    except ValueError:
        return None
    if not (0 <= h <= 23 and 0 <= m <= 59 and 0 <= sec <= 59):
        return None
    target = datetime.datetime.now().replace(
        hour=h,
        minute=m,
        second=sec,
        microsecond=0,
    )
    return target.timestamp()


def format_remaining(total_seconds: float) -> str:
    total = round(total_seconds)
    h, remainder = divmod(total, 3600)
    m, s = divmod(remainder, 60)
    if h > 0:
        return f"{h}h {m}m {s}s"
    if m > 0:
        return f"{m}m {s}s"
    return f"{s}s"


def notify(title: str, body: str, urgency: str, timeout_ms: int = 0):
    cmd = [
        "notify-send",
        "-u",
        urgency,
        "-i",
        icon,
        "-h",
        f"string:synchronous:dmd_countdown_{notification_id}",
    ]
    if timeout_ms > 0:
        cmd += ["-t", str(timeout_ms)]
    cmd.extend([title, body])
    subprocess.run(cmd)


def clear_terminal_line():
    cols = os.get_terminal_size().columns
    print(f"\r{' ':<{cols}}\r", end="", flush=True)


def parse_time_arg(
    s: str,
    label: str,
    end_time: float = None,
    required: bool = False,
) -> float:
    if s is None:
        if required:
            print(f"error: missing time for {label}", file=sys.stderr)
            sys.exit(1)
        return None

    if ":" in s:
        result = parse_absolute(s)
    elif s.startswith("+"):
        result = parse_duration(s[1:])
        if result is not None:
            result = time.time() + result
    else:
        result = parse_duration(s)
        if result is not None:
            if end_time is not None:
                result = end_time - result
            else:
                result = time.time() + result

    if result is None:
        if required:
            print(f"error: invalid time for {label}: '{s}'", file=sys.stderr)
            sys.exit(1)
        return None
    return result


def format_time(time: Optional[float]) -> str:
    if time is None:
        return "--"
    return datetime.datetime.fromtimestamp(time).strftime("%Y-%m-%d %H:%M:%S")


def main():
    parser = argparse.ArgumentParser(
        prog="countdown",
        description="Countdown to a target time or duration",
    )
    parser.add_argument(
        "end",
        help="End time for countdown",
    )
    parser.add_argument(
        "-t",
        "--title",
        default="Countdown",
        help="Title of the countdown",
    )
    parser.add_argument(
        "-c",
        "--count-low",
        metavar="TIME",
        help="Time to count down with low priority notification",
    )
    parser.add_argument(
        "-C",
        "--count-high",
        metavar="TIME",
        help="Time to count down with normal priority notification",
    )
    parser.add_argument(
        "-r",
        "--remind",
        nargs="*",
        metavar="reminder",
        help="Times to send reminders",
    )
    parser.add_argument(
        "-q",
        "--quiet",
        action="store_true",
        help="Do not print anything to stdout",
    )
    parser.add_argument(
        "--debug",
        action="store_true",
        help="Debug mode (overrides --quiet)",
    )
    args = parser.parse_args()

    title = args.title

    end_time = parse_time_arg(args.end, "end", required=True)
    low_time = parse_time_arg(args.count_low, "--count-low", end_time=end_time)
    normal_time = parse_time_arg(args.count_high, "--count-high", end_time=end_time)
    reminder_times = (
        [parse_time_arg(r, "reminder", end_time=end_time) for r in args.remind]
        if args.remind
        else []
    )
    reminders_sent = [False] * len(reminder_times)
    sleep_interval = float(BUSY_WAIT_INTERVAL_MS) / 1000
    notification_timeout_ms = 3000
    debug = args.debug
    last_update = -1.0

    quiet = args.quiet and not debug
    printout = print if not quiet else lambda *a, **k: None

    clear_line = clear_terminal_line if not quiet else lambda *a, **k: None

    if debug:
        printout("Countdown:")
        printout(f"      End: {format_time(end_time)}")
        printout(f"      Low: {format_time(low_time)}")
        printout(f"   Normal: {format_time(normal_time)}")
        if reminder_times:
            printout("Reminders:")
            for r in reminder_times:
                printout(f" - {format_time(r)}")
        else:
            printout("Reminders: --")
        printout()

    while True:
        time.sleep(sleep_interval)
        now = time.time()
        remaining = round(end_time - now)

        if remaining <= 0:
            body = "countdown finished"
            if title[0].isupper():
                body = body.capitalize()
            notify(title, body, "critical")
            break

        if debug:
            printout(".", end="", flush=True)
        if last_update == remaining:
            continue

        last_update = remaining

        remaining_text = format_remaining(remaining)
        clear_line()
        if debug:
            remaining_text = f"{remaining_text} ({now:.3f})"
        printout(f"{title}: {remaining_text}", end="", flush=True)

        for i, rt in enumerate(reminder_times):
            if not reminders_sent[i] and now >= rt:
                reminders_sent[i] = True
                notify(title, remaining_text, "low")

        if normal_time is not None and now >= normal_time:
            urgency = "normal"
        elif low_time is not None and now >= low_time:
            urgency = "low"
        else:
            continue

        notify(title, remaining_text, urgency, timeout_ms=notification_timeout_ms)

    clear_line()
    printout(f"{title}: done")


if __name__ == "__main__":
    main()
