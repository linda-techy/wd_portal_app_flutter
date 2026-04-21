#!/usr/bin/env python3
"""
Second-pass verification for unused-file candidates.

For each candidate file:
  1. Extract all top-level class, enum, typedef, mixin names it exports.
  2. Grep the ENTIRE repo (including platform dirs, docs, configs) for each name.
  3. Report: any external hits? → NOT safe to delete. Flag.

This is the "cross-reference with at least two methods" step from the cleanup prompt.
"""
from __future__ import annotations
import argparse
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LIB = ROOT / "lib"

DECL_RE = re.compile(
    r"^\s*(?:abstract\s+)?(?:sealed\s+)?(?:mixin|class|enum|typedef)\s+(?:class\s+)?(\w+)",
    re.MULTILINE,
)
# Top-level function declarations (rare to matter but catch them)
FUNC_RE = re.compile(r"^(?:[A-Z]\w*|Future|Stream|List|Map|void|bool|int|double|String|dynamic)[^\n]*\s+(\w+)\s*\(", re.MULTILINE)


def extract_declared_symbols(path: Path) -> list[str]:
    try:
        text = path.read_text(encoding="utf-8", errors="ignore")
    except Exception:
        return []
    names = set()
    for m in DECL_RE.finditer(text):
        n = m.group(1)
        # Skip private (leading _) since they can't be imported anyway
        if not n.startswith("_"):
            names.add(n)
    return sorted(names)


def grep_repo(symbol: str, exclude_self: Path) -> list[str]:
    """Return lines where symbol appears in repo files, excluding the defining file."""
    hits: list[str] = []
    try:
        # Search only in source code dirs; ignore build/cache.
        r = subprocess.run(
            [
                "grep", "-rn", "-w",
                "--include=*.dart",
                "--include=*.yaml",
                "--include=*.json",
                "--include=*.md",
                "--include=*.html",
                "--include=*.gradle",
                "--include=*.kts",
                "--exclude-dir=build",
                "--exclude-dir=.dart_tool",
                "--exclude-dir=.idea",
                "--exclude-dir=.git",
                "--exclude-dir=node_modules",
                symbol,
                str(ROOT),
            ],
            capture_output=True, text=True, timeout=30,
        )
        for line in r.stdout.splitlines():
            # line looks like: "/abs/path:lineno:contents"
            path = line.split(":", 1)[0]
            try:
                if Path(path).resolve() == exclude_self:
                    continue
            except Exception:
                pass
            hits.append(line)
    except subprocess.TimeoutExpired:
        hits.append(f"# TIMEOUT grepping {symbol}")
    return hits


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--candidates", required=True, help="File with one candidate path per line (repo-relative)")
    ap.add_argument("--max-hits", type=int, default=3, help="Hits per symbol to print")
    args = ap.parse_args()

    cand_file = Path(args.candidates)
    if not cand_file.is_absolute():
        cand_file = ROOT / cand_file
    candidates = [ln.strip() for ln in cand_file.read_text().splitlines() if ln.strip() and not ln.startswith("#")]

    truly_unused: list[str] = []
    flagged: list[tuple[str, list[tuple[str, list[str]]]]] = []  # (path, [(symbol, hits)])

    for rel in candidates:
        abspath = (ROOT / rel).resolve()
        if not abspath.exists():
            continue
        syms = extract_declared_symbols(abspath)
        if not syms:
            # File has no top-level exports — a pure side-effect file or stub.
            # Keep flagged for manual review rather than assuming safe.
            flagged.append((rel, [("(no public symbols)", [])]))
            continue
        per_sym_hits = []
        total_external = 0
        for s in syms:
            hits = grep_repo(s, abspath)
            if hits:
                per_sym_hits.append((s, hits[: args.max_hits]))
                total_external += len(hits)
        if total_external == 0:
            truly_unused.append(rel)
        else:
            flagged.append((rel, per_sym_hits))

    print(f"# candidates checked: {len(candidates)}")
    print(f"# truly unused (zero external symbol refs): {len(truly_unused)}")
    print(f"# flagged for review: {len(flagged)}")
    print()
    print("## Truly unused (safe-to-delete candidates, pending Phase 3 human review):")
    for r in truly_unused:
        print(f"  {r}")
    print()
    print("## Flagged (symbols still referenced — keep or investigate):")
    for rel, pairs in flagged:
        print(f"  {rel}")
        for sym, hits in pairs:
            if not hits:
                print(f"    - {sym}")
                continue
            print(f"    - {sym}:")
            for h in hits[:2]:
                print(f"        {h[:140]}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
