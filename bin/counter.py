#! /bin/python

import argparse
import collections
import sys


def eprint(text):
    print(text, file=sys.stderr)


parser = argparse.ArgumentParser("counter", description="Count unique lines.")
args = parser.parse_args()

lines = sys.stdin.read().splitlines()
counter = collections.Counter(lines)
print("       Count | Line")
print("---------------------------")
for line, count in counter.most_common():
    print(f"{count:>12,} | {line}")
