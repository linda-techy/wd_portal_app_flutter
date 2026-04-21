#!/usr/bin/env python3
"""
Find unreferenced .dart files in a Flutter project.

Builds an import graph by:
  1. Parsing every import/export/part directive in every .dart file under lib/, test/, integration_test/.
  2. Resolving each import target to an absolute on-disk path (handling package:, relative, and dart:/external).
  3. Marking files reachable from a set of roots (main.dart + test files + generated-output producers).
  4. Reporting files in lib/ that are not reachable.

Usage: python tool/find_unused.py [--pkg PKG_NAME] [--verbose]
"""
from __future__ import annotations
import argparse
import os
import re
import sys
from pathlib import Path
from collections import defaultdict, deque

ROOT = Path(__file__).resolve().parent.parent
LIB = ROOT / "lib"
TEST = ROOT / "test"
INTEGRATION = ROOT / "integration_test"

# Directive opening line, up to the first quoted path.
DIRECTIVE_RE = re.compile(
    r"""^\s*(?:import|export|part(?:\s+of)?)\s+['"]([^'"]+)['"]""", re.MULTILINE
)
# Any additional quoted alternates within a directive (for conditional imports:
#   `import 'stub.dart' if (dart.library.html) 'web.dart' if (dart.library.io) 'io.dart';`).
# The directive can span multiple lines; we capture every quoted string inside
# the statement body up to the terminating semicolon.
CONDITIONAL_ALT_RE = re.compile(
    r"""(?:import|export)\s+['"][^'"]+['"][\s\S]*?;""", re.MULTILINE
)
QUOTED_PATH_RE = re.compile(r"""['"]([^'"\s]+?\.dart)['"]""")


def parse_pubspec_name(pubspec_path: Path) -> str:
    for line in pubspec_path.read_text(encoding="utf-8").splitlines():
        m = re.match(r"^\s*name\s*:\s*(\S+)", line)
        if m:
            return m.group(1)
    raise RuntimeError("Could not find 'name:' in pubspec.yaml")


def collect_dart_files(*roots: Path) -> list[Path]:
    out: list[Path] = []
    for root in roots:
        if not root.exists():
            continue
        for p in root.rglob("*.dart"):
            out.append(p.resolve())
    return out


def resolve_target(directive: str, importer: Path, pkg: str) -> Path | None:
    """Resolve a directive target to an on-disk absolute path, or None if external."""
    if directive.startswith("dart:"):
        return None
    if directive.startswith("package:"):
        # package:<name>/<rel>
        rest = directive[len("package:"):]
        slash = rest.find("/")
        if slash == -1:
            return None
        name, rel = rest[:slash], rest[slash + 1:]
        if name != pkg:
            return None  # third-party package — not our file
        return (LIB / rel).resolve()
    # Relative path
    return (importer.parent / directive).resolve()


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--pkg", help="pub package name (default: from pubspec.yaml)")
    ap.add_argument("--verbose", action="store_true")
    args = ap.parse_args()

    pkg = args.pkg or parse_pubspec_name(ROOT / "pubspec.yaml")

    all_files = set(collect_dart_files(LIB, TEST, INTEGRATION))

    # Build import graph: importer -> set of imported files
    graph: dict[Path, set[Path]] = defaultdict(set)
    for f in all_files:
        try:
            text = f.read_text(encoding="utf-8", errors="ignore")
        except Exception as e:
            print(f"# skip unreadable: {f}: {e}", file=sys.stderr)
            continue
        # 1. Primary target of each directive
        for directive in DIRECTIVE_RE.findall(text):
            target = resolve_target(directive, f, pkg)
            if target is not None and target in all_files:
                graph[f].add(target)
        # 2. Conditional-import alternates: any extra quoted '.dart' path
        #    inside an import/export statement body.
        for stmt in CONDITIONAL_ALT_RE.findall(text):
            for alt in QUOTED_PATH_RE.findall(stmt):
                target = resolve_target(alt, f, pkg)
                if target is not None and target in all_files:
                    graph[f].add(target)

    # Also handle "part of" the reverse direction: if A declares `part 'B.dart'`,
    # B's "part of" is implicit. We've already captured A->B via DIRECTIVE_RE.

    # Roots: main.dart + all test files + any file ending in _test.dart
    roots: set[Path] = set()
    main = LIB / "main.dart"
    if main.exists():
        roots.add(main.resolve())
    for f in all_files:
        rel = f.relative_to(ROOT)
        parts = rel.parts
        if parts and parts[0] in ("test", "integration_test"):
            roots.add(f)
        elif f.name.endswith("_test.dart"):
            roots.add(f)

    # BFS reachability
    reachable: set[Path] = set()
    queue: deque[Path] = deque(roots)
    while queue:
        f = queue.popleft()
        if f in reachable:
            continue
        reachable.add(f)
        for nxt in graph.get(f, ()):
            if nxt not in reachable:
                queue.append(nxt)

    # Candidates: files under lib/ that are not reachable AND not part of codegen pairs
    lib_files = {f for f in all_files if str(f).startswith(str(LIB))}
    unreachable = sorted(lib_files - reachable, key=lambda p: p.relative_to(ROOT).as_posix())

    # Classify
    codegen = []
    unused = []
    for f in unreachable:
        name = f.name
        if name.endswith(".g.dart") or name.endswith(".freezed.dart") or name.endswith(".config.dart"):
            # generated: only worth keeping if its source file is reachable
            stem = name.rsplit(".", 2)[0]  # "foo" from "foo.g.dart"
            source = f.with_name(f"{stem}.dart")
            if source in reachable:
                continue  # still needed
            codegen.append(f)
        else:
            unused.append(f)

    print(f"# package: {pkg}")
    print(f"# total dart files scanned: {len(all_files)}")
    print(f"# lib/ files: {len(lib_files)}")
    print(f"# reachable from roots: {len(reachable & lib_files)}")
    print(f"# unreachable lib/ files: {len(unreachable)}")
    print(f"# of those, codegen with dead source: {len(codegen)}")
    print(f"# of those, hand-written candidates: {len(unused)}")
    print()
    print("## Hand-written unreachable files (candidates for review):")
    for f in unused:
        print(f"  {f.relative_to(ROOT).as_posix()}")
    if codegen:
        print()
        print("## Codegen files whose source is also unreachable:")
        for f in codegen:
            print(f"  {f.relative_to(ROOT).as_posix()}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
