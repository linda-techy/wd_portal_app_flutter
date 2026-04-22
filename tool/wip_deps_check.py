#!/usr/bin/env python3
"""
For each candidate, check whether any FLAGGED-RECENT file
directly or transitively depends on it.

If yes, mark candidate as "held by WIP" — do NOT delete.
"""
from __future__ import annotations
import sys
from pathlib import Path
from collections import defaultdict, deque

# Reuse the same graph-building logic from find_unused.py
sys.path.insert(0, str(Path(__file__).parent))
from find_unused import (  # type: ignore
    collect_dart_files, resolve_target, parse_pubspec_name,
    DIRECTIVE_RE, CONDITIONAL_ALT_RE, QUOTED_PATH_RE,
)

ROOT = Path(__file__).resolve().parent.parent
LIB = ROOT / "lib"
TEST = ROOT / "test"
INTEGRATION = ROOT / "integration_test"


def build_graph(pkg: str):
    all_files = set(collect_dart_files(LIB, TEST, INTEGRATION))
    graph: dict[Path, set[Path]] = defaultdict(set)
    for f in all_files:
        try:
            text = f.read_text(encoding="utf-8", errors="ignore")
        except Exception:
            continue
        for d in DIRECTIVE_RE.findall(text):
            t = resolve_target(d, f, pkg)
            if t and t in all_files:
                graph[f].add(t)
        for stmt in CONDITIONAL_ALT_RE.findall(text):
            for alt in QUOTED_PATH_RE.findall(stmt):
                t = resolve_target(alt, f, pkg)
                if t and t in all_files:
                    graph[f].add(t)
    return all_files, graph


def main():
    pkg = parse_pubspec_name(ROOT / "pubspec.yaml")
    all_files, graph = build_graph(pkg)

    # Read flagged-recent list from git_history_out
    flagged: list[Path] = []
    history = (ROOT / "tool/_git_history_out.txt").read_text()
    in_flagged = False
    for line in history.splitlines():
        if line.startswith("## FLAGGED"):
            in_flagged = True
            continue
        if line.startswith("## CLEARED"):
            in_flagged = False
        if in_flagged and line.startswith("  lib/"):
            p = (ROOT / line.strip()).resolve()
            if p in all_files:
                flagged.append(p)

    # Forward BFS from each flagged file → what it transitively imports
    held: set[Path] = set()
    q = deque(flagged)
    while q:
        f = q.popleft()
        if f in held:
            continue
        held.add(f)
        for nxt in graph.get(f, ()):
            if nxt not in held:
                q.append(nxt)

    # Read cleared candidates
    cleared: list[str] = []
    in_cleared = False
    for line in history.splitlines():
        if line.startswith("## CLEARED"):
            in_cleared = True
            continue
        if in_cleared and line.strip().startswith("lib/"):
            cleared.append(line.split()[0])

    safe: list[str] = []
    held_rels: list[str] = []
    for c in cleared:
        p = (ROOT / c).resolve()
        if p in held:
            held_rels.append(c)
        else:
            safe.append(c)

    print(f"# flagged-recent files: {len(flagged)}")
    print(f"# files held by WIP (transitively): {len(held) - len(flagged)}")
    print(f"# cleared candidates: {len(cleared)}")
    print(f"# safe (not held by WIP): {len(safe)}")
    print(f"# held by WIP (DO NOT DELETE): {len(held_rels)}")
    print()
    print("## HELD BY WIP — keep these:")
    for r in held_rels:
        print(f"  {r}")
    print()
    print("## SAFE TO DELETE — not held by WIP:")
    for r in safe:
        print(f"  {r}")


if __name__ == "__main__":
    main()
