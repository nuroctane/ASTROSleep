#!/usr/bin/env python3
"""
AstroSleep shared-asset sync (one-way, source of truth -> platform copies)
===========================================================================
Replaces the manual PowerShell copy recipe. Sources of truth:

  shared/cosmic-systems/                      -> iOS Resources + Android assets
  AstroSleep-iOS/Sounds/sounds_manifest.json  -> Android assets/sounds/

Usage:

    python tools/sync_shared.py             # copy
    python tools/sync_shared.py --dry-run   # show what would change

Verify afterwards with tools/check_parity.py (CI runs the verifier only;
sync is always an explicit local action so drift is never silently healed).
"""

from __future__ import annotations

import argparse
import filecmp
import shutil
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent

COSMIC_SOURCE = REPO / "shared" / "cosmic-systems"
COSMIC_TARGETS = [
    REPO / "AstroSleep-iOS" / "AstroSleep" / "Resources" / "cosmic-systems",
    REPO / "AstroSleep-Android" / "app" / "src" / "main" / "assets" / "cosmic-systems",
]

# Lives with the shared source but is documentation, not a deployable asset.
TREE_EXCLUDE = {"README.md"}

MANIFEST_SOURCE = REPO / "AstroSleep-iOS" / "Sounds" / "sounds_manifest.json"
MANIFEST_TARGETS = [
    REPO / "AstroSleep-Android" / "app" / "src" / "main" / "assets" / "sounds" / "sounds_manifest.json",
]


def sync_tree(src: Path, dst: Path, dry: bool) -> int:
    """Mirror src into dst. Returns number of changed paths."""
    changed = 0
    src_files = {p.relative_to(src) for p in src.rglob("*")
                 if p.is_file() and str(p.relative_to(src)) not in TREE_EXCLUDE}
    dst_files = {p.relative_to(dst) for p in dst.rglob("*")
                 if p.is_file() and str(p.relative_to(dst)) not in TREE_EXCLUDE} if dst.exists() else set()

    for rel in sorted(src_files):
        s, d = src / rel, dst / rel
        if not d.exists() or not filecmp.cmp(s, d, shallow=False):
            changed += 1
            print(f"  {'would copy' if dry else 'copy':10s} {rel}  ->  {d.relative_to(REPO)}")
            if not dry:
                d.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(s, d)

    for rel in sorted(dst_files - src_files):
        changed += 1
        d = dst / rel
        print(f"  {'would prune' if dry else 'prune':10s} {d.relative_to(REPO)} (no source counterpart)")
        if not dry:
            d.unlink()

    if changed == 0:
        print(f"  in sync    {dst.relative_to(REPO)}")
    return changed


def sync_file(src: Path, dst: Path, dry: bool) -> int:
    if dst.exists() and filecmp.cmp(src, dst, shallow=False):
        print(f"  in sync    {dst.relative_to(REPO)}")
        return 0
    print(f"  {'would copy' if dry else 'copy':10s} {src.relative_to(REPO)}  ->  {dst.relative_to(REPO)}")
    if not dry:
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dst)
    return 1


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dry-run", action="store_true", help="report without writing")
    dry = parser.parse_args().dry_run

    if not COSMIC_SOURCE.is_dir():
        print(f"missing source tree: {COSMIC_SOURCE.relative_to(REPO)}", file=sys.stderr)
        return 2
    if not MANIFEST_SOURCE.is_file():
        print(f"missing source manifest: {MANIFEST_SOURCE.relative_to(REPO)}", file=sys.stderr)
        return 2

    total = 0
    print(f"cosmic-systems source: {COSMIC_SOURCE.relative_to(REPO)}")
    for target in COSMIC_TARGETS:
        total += sync_tree(COSMIC_SOURCE, target, dry)
    print(f"manifest source: {MANIFEST_SOURCE.relative_to(REPO)}")
    for target in MANIFEST_TARGETS:
        total += sync_file(MANIFEST_SOURCE, target, dry)

    print(f"\n{'would change' if dry else 'changed'}: {total} path(s). "
          f"Verify with: python tools/check_parity.py")
    return 0


if __name__ == "__main__":
    sys.exit(main())
