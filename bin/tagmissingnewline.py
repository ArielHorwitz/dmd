#! /bin/python
import sys
import argparse

DESC = """Check for newline at end of text.

In check mode (--check), will exit with status code 1 if no newline at the end of the text. Otherwise, will process input and add a newline at the end."""

def main():
    # Parse args
    parser = argparse.ArgumentParser(description=DESC)
    parser.add_argument(
        "file",
        nargs='?',
        help="Read from file instead of stdin",
        type=str,
        default=None,
    )
    parser.add_argument(
        "-c",
        "--check",
        help="Check instead of process (exit code 1 if no newline at end of text)",
        action="store_true",
    )
    parser.add_argument(
        "-i",
        "--insert",
        help="Insert custom text if missing newline at end of file",
        type=str,
        required=False,
    )
    args = parser.parse_args()

    line = '\n'
    check = args.check
    if args.file:
        with open(args.file, 'r') as file:
            for line in file:
                if not check:
                    print(line, end='')
    else:
        for line in sys.stdin:
            if not check:
                print(line, end='')

    if not line.endswith('\n'):
        if check:
            exit(1)
        else:
            print(f"\033[30;41;2m{args.insert or '|'}\033[0m")
    print(end='', flush=True)


if __name__ == "__main__":
    main()

