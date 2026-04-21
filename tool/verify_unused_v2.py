#!/usr/bin/env python3
"""
Second-pass (revised): for each candidate, grep the repo for its filename (basename).

Produces three buckets:
  - ZERO external references: no file (outside the candidate itself) mentions its basename → safe candidate.
  - REFERENCED but only from other Method-1 unreachable files: suspect — the "reference" is from another orphan, a dead-code cluster.
  - REFERENCED from reachable / external files: keep, may be loaded indirectly.
"""
from __future__ import annotations
import argparse
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def grep_basename(basename: str, exclude: Path) -> list[str]:
    r = subprocess.run(
        [
            "grep", "-rln", "-w",
            "--include=*.dart",
            "--include=*.yaml",
            "--include=*.json",
            "--include=*.md",
            "--include=*.html",
            "--exclude-dir=build",
            "--exclude-dir=.dart_tool",
            "--exclude-dir=.idea",
            "--exclude-dir=.git",
            basename,
            str(ROOT),
        ],
        capture_output=True, text=True, timeout=30,
    )
    lines = []
    for ln in r.stdout.splitlines():
        try:
            if Path(ln).resolve() != exclude:
                lines.append(ln)
        except Exception:
            lines.append(ln)
    return lines


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--candidates", required=True)
    args = ap.parse_args()

    cand_file = Path(args.candidates)
    if not cand_file.is_absolute():
        cand_file = ROOT / cand_file
    candidates = [ln.strip() for ln in cand_file.read_text().splitlines() if ln.strip() and not ln.startswith("#")]
    cand_set = {(ROOT / c).resolve() for c in candidates}

    zero_refs: list[str] = []
    only_orphan_refs: list[tuple[str, list[str]]] = []
    live_refs: list[tuple[str, list[str]]] = []

    for rel in candidates:
        abspath = (ROOT / rel).resolve()
        if not abspath.exists():
            continue
        hits = grep_basename(abspath.name, abspath)
        if not hits:
            zero_refs.append(rel)
            continue
        # Split hits by whether the hit-file is itself an orphan.
        orphan_hits, live_hits = [], []
        for h in hits:
            hpath = Path(h).resolve()
            if hpath in cand_set:
                orphan_hits.append(h)
            else:
                live_hits.append(h)
        if not live_hits:
            only_orphan_refs.append((rel, orphan_hits))
        else:
            live_refs.append((rel, live_hits))

    print(f"# candidates checked: {len(candidates)}")
    print(f"# zero external references: {len(zero_refs)}")
    print(f"# referenced only from other orphan candidates (dead cluster): {len(only_orphan_refs)}")
    print(f"# referenced from live files (keep or investigate): {len(live_refs)}")
    print()
    print("## ZERO REFERENCES (strongest delete-candidates):")
    for r in zero_refs:
        print(f"  {r}")
    print()
    print("## DEAD CLUSTER (candidate only referenced by other orphan candidates):")
    for rel, hits in only_orphan_refs:
        print(f"  {rel}")
        for h in hits[:3]:
            print(f"    ref: {Path(h).relative_to(ROOT).as_posix()}")
    print()
    print("## REFERENCED FROM LIVE FILES (keep unless manually cleared):")
    for rel, hits in live_refs:
        print(f"  {rel}")
        for h in hits[:3]:
            print(f"    ref: {Path(h).relative_to(ROOT).as_posix()}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
