#!/usr/bin/env python3
"""
Per-candidate git history check (Phase 3 evidence).

For each candidate file:
  - First-commit author/date
  - Last-commit author/date
  - Total commits touching it

Files recently added (within last 30 days) are flagged for manual review
before deletion — they may be a WIP feature, not abandoned legacy.
"""
from __future__ import annotations
import argparse
import subprocess
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def git(args: list[str]) -> str:
    r = subprocess.run(["git", *args], capture_output=True, text=True, cwd=ROOT)
    return r.stdout.strip()


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--candidates", required=True)
    ap.add_argument("--recent-days", type=int, default=30)
    args = ap.parse_args()

    cand_file = Path(args.candidates)
    if not cand_file.is_absolute():
        cand_file = ROOT / cand_file
    candidates = [ln.strip() for ln in cand_file.read_text().splitlines() if ln.strip() and not ln.startswith("#")]

    now = datetime.now(timezone.utc)
    cutoff = now - timedelta(days=args.recent_days)

    flagged_recent = []
    cleared = []

    for rel in candidates:
        first = git(["log", "--follow", "--reverse", "--format=%ai|%an|%h", "--", rel])
        if not first:
            # No history → untracked file
            flagged_recent.append((rel, "untracked (no git history)", "", 0))
            continue
        first_line = first.splitlines()[0]
        last_line = git(["log", "--follow", "-1", "--format=%ai|%an|%h", "--", rel])
        count = int(git(["log", "--follow", "--format=%h", "--", rel]).count("\n") or 0) + 1

        first_date_s, first_author, first_sha = first_line.split("|", 2)
        last_date_s, last_author, last_sha = last_line.split("|", 2)
        # Git %ai format: "YYYY-MM-DD HH:MM:SS +ZZZZ" — parse explicitly.
        first_dt = datetime.strptime(first_date_s.strip(), "%Y-%m-%d %H:%M:%S %z")
        last_dt = datetime.strptime(last_date_s.strip(), "%Y-%m-%d %H:%M:%S %z")

        entry = (rel, first_line, last_line, count)
        if first_dt > cutoff or last_dt > cutoff:
            flagged_recent.append(entry)
        else:
            cleared.append(entry)

    print(f"# candidates: {len(candidates)}")
    print(f"# cleared (old, likely safe): {len(cleared)}")
    print(f"# flagged recent (added/modified in last {args.recent_days} days): {len(flagged_recent)}")
    print()
    print("## FLAGGED (recent changes — review before deletion):")
    for rel, first, last, count in flagged_recent:
        print(f"  {rel}")
        print(f"    first: {first}")
        print(f"    last:  {last}   ({count} commits)")
    print()
    print("## CLEARED (old, no recent activity):")
    for rel, first, last, count in cleared:
        print(f"  {rel}  ({count}c, first={first.split('|')[0][:10]}, last={last.split('|')[0][:10]})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
