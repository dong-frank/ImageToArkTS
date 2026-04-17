#!/usr/bin/env python3
from __future__ import annotations

import sys
from pathlib import Path


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    offenders: list[Path] = []

    for path in sorted(root.rglob("*.sh")):
        if b"\r\n" in path.read_bytes():
            offenders.append(path.relative_to(root))

    if offenders:
        print("Found CRLF line endings in shell scripts:")
        for offender in offenders:
            print(f"- {offender}")
        return 1

    print("All shell scripts use LF line endings.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
