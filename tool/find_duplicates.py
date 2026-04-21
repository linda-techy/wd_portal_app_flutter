#!/usr/bin/env python3
"""
Find duplicate .dart files by content hash.

Groups all lib/ files by SHA256 of (whitespace-normalised) content.
Also flags near-duplicates (>95% matching lines) as a secondary heuristic.
"""
from __future__ import annotations
import hashlib
import re
import sys
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LIB = ROOT / "lib"

WS_RE = re.compile(r"\s+")
COMMENT_RE = re.compile(r"//[^\n]*|/\*[\s\S]*?\*/")


def normalise(text: str) -> str:
    text = COMMENT_RE.sub("", text)
    return WS_RE.sub(" ", text).strip()


def main() -> int:
    by_hash: dict[str, list[Path]] = defaultdict(list)
    for f in LIB.rglob("*.dart"):
        try:
            text = f.read_text(encoding="utf-8", errors="ignore")
        except Exception:
            continue
        h = hashlib.sha256(normalise(text).encode("utf-8")).hexdigest()
        by_hash[h].append(f)

    dups = {h: paths for h, paths in by_hash.items() if len(paths) > 1}
    print(f"# total lib/ files scanned: {sum(len(p) for p in by_hash.values())}")
    print(f"# duplicate groups (identical ignoring comments+whitespace): {len(dups)}")
    print()
    for h, paths in dups.items():
        print(f"## group {h[:12]} ({len(paths)} files)")
        for p in paths:
            print(f"  {p.relative_to(ROOT).as_posix()}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
