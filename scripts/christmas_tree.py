#!/usr/bin/env python3
"""Small script to draw an ASCII Christmas (Noel) tree.

Usage examples:
  python scripts/christmas_tree.py --height 10
  python scripts/christmas_tree.py --height 8 --char '#' --no-ornaments
"""
from __future__ import annotations
import argparse
import random
import sys


def draw_tree(height: int = 6, char: str = "*", ornaments: bool = True, ornament_chars: str = "@o*", seed: int | None = None) -> None:
    if height < 1:
        return
    if seed is not None:
        random.seed(seed)

    # Draw foliage: each row has odd number of chars centered
    width = 2 * height - 1
    for row in range(1, height + 1):
        count = 2 * row - 1
        line = []
        for i in range(count):
            if ornaments and random.random() < 0.12:
                line.append(random.choice(ornament_chars))
            else:
                line.append(char)
        print((" ") * ((width - count) // 2) + "".join(line))

    # Draw trunk: centered, height//3 rows
    trunk_height = max(1, height // 3)
    trunk_width = max(1, height // 3)
    if trunk_width % 2 == 0:
        trunk_width += 1
    trunk_pad = (width - trunk_width) // 2
    for _ in range(trunk_height):
        print(" " * trunk_pad + "|" * trunk_width)


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Draw a simple ASCII Christmas (Noel) tree")
    p.add_argument("-n", "--height", type=int, default=6, help="Tree height (number of foliage rows)")
    p.add_argument("-c", "--char", type=str, default="*", help="Character to use for leaves")
    p.add_argument("--no-ornaments", dest="ornaments", action="store_false", help="Disable random ornaments")
    p.add_argument("--ornament-chars", type=str, default="@o*", help="Characters used for ornaments")
    p.add_argument("--seed", type=int, default=None, help="Random seed for reproducible ornaments")
    return p.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    draw_tree(height=args.height, char=args.char, ornaments=args.ornaments, ornament_chars=args.ornament_chars, seed=args.seed)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
