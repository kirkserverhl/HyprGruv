#!/usr/bin/env python3
"""gitignore-style filter for config-edit.

Reads candidate names (one per line) from stdin.
Prints the names that should be ignored.

Usage:
  config-edit-ignore.py <config-root> [ignore-file ...]
"""
from __future__ import annotations

import fnmatch
import os
import sys


def load_patterns(path: str) -> list[tuple[bool, bool, str]]:
    out: list[tuple[bool, bool, str]] = []
    with open(path, encoding="utf-8") as fh:
        for raw in fh:
            line = raw.strip()
            if not line or line.startswith("#"):
                continue
            neg = line.startswith("!")
            if neg:
                line = line[1:]
            dir_only = line.endswith("/")
            if dir_only:
                line = line[:-1]
            out.append((neg, dir_only, line))
    return out


def is_ignored(rel: str, is_dir: bool, pats: list[tuple[bool, bool, str]]) -> bool:
    result = False
    base = os.path.basename(rel.rstrip("/"))
    for neg, dir_only, pat in pats:
        if dir_only and not is_dir:
            continue
        pat_l = pat.lstrip("/")
        if "/" in pat_l:
            hit = fnmatch.fnmatch(rel, pat_l) or fnmatch.fnmatch(rel, pat_l.rstrip("/"))
        else:
            hit = fnmatch.fnmatch(base, pat_l) or fnmatch.fnmatch(rel, pat_l)
        if hit:
            result = not neg
    return result


def main() -> int:
    if len(sys.argv) < 2:
        print("usage: config-edit-ignore.py <config-root> [ignore-file ...]", file=sys.stderr)
        return 2

    root = sys.argv[1]
    pats: list[tuple[bool, bool, str]] = []
    for path in sys.argv[2:]:
        if path and os.path.isfile(path):
            pats.extend(load_patterns(path))

    for line in sys.stdin:
        name = line.rstrip("\n")
        if not name:
            continue
        rel = name
        if name.startswith(root + os.sep):
            rel = name[len(root) + 1 :]
        abs_path = name if os.path.isabs(name) else os.path.join(root, rel)
        is_dir = os.path.isdir(abs_path)
        if is_ignored(rel, is_dir, pats):
            print(name)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
