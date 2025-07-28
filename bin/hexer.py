#! /bin/python

import argparse
import shutil


def analyze(title, value, column_size) -> tuple[str, ...]:
    title = f"From {title}"
    output = (
        f"{title:^{column_size}}",
        "-" * column_size,
    )
    if value is None:
        return (*output, *(f"{'---':^{column_size}}" for _ in range(4)))
    i = int(value)
    return (
        *output,
        f"0x{i:02x}",
        f"{i}",
        f"{i // 16:<4}  double doubles [+{i % 16:>2}]",
        f"{i // 8:<4}  doubles        [+{i % 8:>2}]",
        f"{i // 4:<4}  longs          [+{i % 4:>2}]",
    )


def get_int(value) -> int:
    try:
        return int(value)
    except ValueError:
        return None


def get_hex(value) -> int:
    try:
        return int(str(value), 16)
    except ValueError:
        return None


def main():
    parser = argparse.ArgumentParser(
        "hexer",
        description="Show details of integer and hexadecimal values",
    )
    parser.add_argument("values", nargs="+", help="Integer and hexadecimal values")
    parser.add_argument("--width", help="Width of the output")
    args = parser.parse_args()

    if args.width is None:
        total_width = shutil.get_terminal_size().columns
    else:
        total_width = int(args.width)
    column_size = (total_width - 4) // 2

    split = "=" * total_width
    output = [split]
    for value in args.values:
        output_hex = analyze("hex", get_hex(value), column_size)
        output_int = analyze("int", get_int(value), column_size)
        table = "\n".join(
            f" {h:<{column_size}} | {i}" for h, i in zip(output_hex, output_int)
        )
        output.append(table)
        output.append(split)
    print(f"\n".join(output))


if __name__ == "__main__":
    main()
