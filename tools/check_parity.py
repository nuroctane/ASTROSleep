#!/usr/bin/env python3
"""
AstroSleep cross-platform parity guard
======================================
Mechanizes the repo's lockstep rules. Fails (exit 1) with named paths if:

1. shared/cosmic-systems/** differs from either platform copy
2. The two sounds_manifest.json copies differ
3. The 12 tag-dimension weights disagree between TagEngine.swift,
   TagEngine.kt, and validate_manifest.py
4. More than one PrivacyInfo.xcprivacy or .entitlements exists in the
   iOS tree (App Store declaration ambiguity; see go-live checklist 3.12)

Run from anywhere inside the repo:

    python tools/check_parity.py

CI runs this on every push/PR (.github/workflows/ci.yml). After editing
anything under shared/, run tools/sync_shared.py to push copies out.
"""

from __future__ import annotations

import hashlib
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent

COSMIC_SOURCE = REPO / "shared" / "cosmic-systems"
COSMIC_COPIES = [
    REPO / "AstroSleep-iOS" / "AstroSleep" / "Resources" / "cosmic-systems",
    REPO / "AstroSleep-Android" / "app" / "src" / "main" / "assets" / "cosmic-systems",
]

# Documentation that lives with the shared source but is not a deployable
# WebView asset (never copied into app bundles).
TREE_EXCLUDE = {"README.md"}

MANIFEST_SOURCE = REPO / "AstroSleep-iOS" / "Sounds" / "sounds_manifest.json"
MANIFEST_COPIES = [
    REPO / "AstroSleep-Android" / "app" / "src" / "main" / "assets" / "sounds" / "sounds_manifest.json",
]

WEIGHT_FILES = {
    "swift": REPO / "AstroSleep-iOS" / "AstroSleep" / "Core" / "Engine" / "TagEngine.swift",
    "kotlin": REPO / "AstroSleep-Android" / "app" / "src" / "main" / "java" / "com"
    / "astrosleep" / "app" / "core" / "engine" / "TagEngine.kt",
    "python": REPO / "AstroSleep-iOS" / "Sounds" / "validate_manifest.py",
}
WEIGHT_ANCHORS = {
    "swift": "baseDimensionWeights",
    "kotlin": "baseDimensionWeights",
    "python": "DIMENSION_WEIGHTS",
}
# "domain" to 9.0   (kotlin)  ·  "domain": 9.0   (swift / python)
WEIGHT_PAIR = re.compile(r'"(\w+)"\s*(?:to|:)\s*([0-9]+(?:\.[0-9]+)?)')
EXPECTED_DIMENSIONS = 12

IOS_TREE = REPO / "AstroSleep-iOS"

failures: list[str] = []


def fail(msg: str) -> None:
    failures.append(msg)
    print(f"  FAIL  {msg}")


def ok(msg: str) -> None:
    print(f"  ok    {msg}")


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def tree_hashes(root: Path) -> dict[str, str]:
    return {
        str(p.relative_to(root)): sha256(p)
        for p in sorted(root.rglob("*"))
        if p.is_file() and str(p.relative_to(root)) not in TREE_EXCLUDE
    }


def check_tree_parity() -> None:
    print(f"[1/4] cosmic-systems parity ({COSMIC_SOURCE.relative_to(REPO)} -> platforms)")
    if not COSMIC_SOURCE.is_dir():
        fail(f"missing source tree: {COSMIC_SOURCE.relative_to(REPO)}")
        return
    src = tree_hashes(COSMIC_SOURCE)
    for copy in COSMIC_COPIES:
        rel = copy.relative_to(REPO)
        if not copy.is_dir():
            fail(f"missing platform copy: {rel}")
            continue
        dst = tree_hashes(copy)
        drift = False
        for name in sorted(set(src) | set(dst)):
            if name not in dst:
                fail(f"{rel}/{name} missing (exists in shared source)")
                drift = True
            elif name not in src:
                fail(f"{rel}/{name} has no shared source counterpart")
                drift = True
            elif src[name] != dst[name]:
                fail(f"{rel}/{name} differs from shared source")
                drift = True
        if not drift:
            ok(f"{rel} matches source ({len(src)} files)")


def check_manifest_parity() -> None:
    print(f"[2/4] sounds_manifest parity ({MANIFEST_SOURCE.relative_to(REPO)} -> copies)")
    if not MANIFEST_SOURCE.is_file():
        fail(f"missing source manifest: {MANIFEST_SOURCE.relative_to(REPO)}")
        return
    src = sha256(MANIFEST_SOURCE)
    for copy in MANIFEST_COPIES:
        rel = copy.relative_to(REPO)
        if not copy.is_file():
            fail(f"missing manifest copy: {rel}")
        elif sha256(copy) != src:
            fail(f"{rel} differs from source manifest")
        else:
            ok(f"{rel} matches source")


def extract_weights(lang: str, path: Path) -> dict[str, float] | None:
    if not path.is_file():
        fail(f"missing weight table file: {path.relative_to(REPO)}")
        return None
    text = path.read_text(encoding="utf-8")
    anchor = text.find(WEIGHT_ANCHORS[lang])
    if anchor == -1:
        fail(f"{path.relative_to(REPO)}: anchor '{WEIGHT_ANCHORS[lang]}' not found")
        return None
    # Scan a bounded window after the anchor; the literal table is small.
    window = text[anchor : anchor + 1200]
    pairs = dict(
        (k, float(v)) for k, v in WEIGHT_PAIR.findall(window)[:EXPECTED_DIMENSIONS]
    )
    if len(pairs) != EXPECTED_DIMENSIONS:
        fail(
            f"{path.relative_to(REPO)}: expected {EXPECTED_DIMENSIONS} dimension "
            f"weights, parsed {len(pairs)}"
        )
        return None
    return pairs


def check_weight_parity() -> None:
    print("[3/4] tag-dimension weight parity (swift / kotlin / python)")
    tables = {lang: extract_weights(lang, path) for lang, path in WEIGHT_FILES.items()}
    if any(t is None for t in tables.values()):
        return
    reference_lang = "kotlin"  # the unit-tested engine
    reference = tables[reference_lang]
    clean = True
    for lang, table in tables.items():
        if lang == reference_lang:
            continue
        for dim in sorted(set(reference) | set(table)):
            a, b = reference.get(dim), table.get(dim)
            if a != b:
                fail(
                    f"weight '{dim}': {reference_lang}={a} vs {lang}={b} "
                    f"({WEIGHT_FILES[lang].relative_to(REPO)})"
                )
                clean = False
    if clean:
        ok(f"all {EXPECTED_DIMENSIONS} weights identical across 3 implementations")


def check_ios_config_singletons() -> None:
    print("[4/4] iOS config singletons (privacy manifest / entitlements)")
    for pattern, label in (
        ("PrivacyInfo.xcprivacy", "PrivacyInfo.xcprivacy"),
        ("*.entitlements", ".entitlements"),
    ):
        matches = sorted(IOS_TREE.rglob(pattern))
        if len(matches) == 1:
            ok(f"exactly one {label}: {matches[0].relative_to(REPO)}")
        elif not matches:
            fail(f"no {label} found under {IOS_TREE.relative_to(REPO)}")
        else:
            listed = ", ".join(str(m.relative_to(REPO)) for m in matches)
            fail(f"{len(matches)} {label} files (must be exactly 1): {listed}")


def main() -> int:
    print(f"AstroSleep parity guard · repo: {REPO}")
    check_tree_parity()
    check_manifest_parity()
    check_weight_parity()
    check_ios_config_singletons()
    if failures:
        print(f"\nPARITY FAILED: {len(failures)} problem(s). "
              f"Run tools/sync_shared.py if shared/ is the intended source of truth.")
        return 1
    print("\nPARITY OK: platforms are in lockstep.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
