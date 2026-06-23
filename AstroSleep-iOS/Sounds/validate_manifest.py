#!/usr/bin/env python3
"""
AstroSleep Sound Manifest Validator
====================================
Validates sounds_manifest.json for:
- Required fields and structure
- All 12 tag dimensions against valid values
- Unique IDs
- Bundle file references exist on disk
- Optional: recompute element scores from tags

Usage:
    python validate_manifest.py
    python validate_manifest.py --compute-scores
"""

import json
import sys
from pathlib import Path
from typing import Any

VALID_TAGS = {
    "domain": ["water", "air", "fire", "earth", "mechanical", "organic", "electrical", "cosmic"],
    "rhythm": ["steady", "pulse", "irregular", "chaotic", "rhythmic", "arrhythmic"],
    "register": ["sub", "deep", "mid", "bright", "full", "ultrasonic"],
    "context": ["nature", "domestic", "abstract", "urban", "industrial", "spiritual"],
    "weight": ["ethereal", "light", "medium", "heavy", "massive"],
    "texture": ["smooth", "rough", "crystalline", "diffuse", "granular", "glassy", "metallic"],
    "motion": ["static", "flowing", "surging", "swirling", "oscillating", "drifting", "pulsing"],
    "density": ["vacuum", "sparse", "moderate", "dense", "saturated"],
    "temperature": ["cold", "cool", "neutral", "warm", "hot"],
    "polarity": ["active", "receptive", "balanced", "neutral"],
    "celestial": ["solar", "lunar", "stellar", "planetary", "void"],
    "archetype": ["maiden", "mother", "crone", "hero", "mentor", "shadow", "trickster"],
}

DIMENSION_WEIGHTS = {
    "domain": 9.0,
    "celestial": 4.0,
    "archetype": 4.0,
    "rhythm": 3.0,
    "motion": 3.0,
    "register": 2.0,
    "context": 2.0,
    "weight": 2.0,
    "texture": 2.0,
    "density": 2.0,
    "temperature": 2.0,
    "polarity": 2.0,
}

# Same vectors as TagVectorTables in Swift
VECTOR_TABLES = {
    "domain": {
        "water": [0.5, 1.5, 1.0, 9.0],
        "air": [1.5, 0.5, 9.0, 1.0],
        "fire": [9.0, 0.5, 1.5, 0.5],
        "earth": [0.5, 9.0, 0.5, 1.5],
        "mechanical": [1.5, 6.0, 2.0, 1.0],
        "organic": [1.0, 5.0, 1.5, 4.0],
        "electrical": [3.0, 1.0, 7.0, 0.5],
        "cosmic": [4.0, 1.0, 6.0, 2.0],
    },
    "rhythm": {
        "steady": [0.0, 3.0, 0.5, 1.5],
        "pulse": [1.0, 2.0, 1.0, 1.5],
        "irregular": [2.0, 0.0, 2.0, 1.5],
        "chaotic": [3.0, 0.0, 2.5, 0.5],
        "rhythmic": [1.5, 2.0, 1.0, 2.0],
        "arrhythmic": [1.0, 0.0, 2.0, 2.0],
    },
    "register": {
        "sub": [0.0, 3.0, 0.0, 2.0],
        "deep": [0.0, 2.5, 0.0, 1.5],
        "mid": [1.0, 1.5, 1.0, 1.0],
        "bright": [1.5, 0.5, 2.5, 0.0],
        "full": [1.0, 1.0, 1.0, 1.0],
        "ultrasonic": [0.5, 0.0, 3.0, 0.0],
    },
    "context": {
        "nature": [1.0, 1.0, 1.0, 1.0],
        "domestic": [0.0, 2.0, 0.5, 1.5],
        "abstract": [0.5, 0.0, 2.0, 1.0],
        "urban": [1.5, 1.0, 2.0, 0.5],
        "industrial": [1.0, 3.0, 1.5, 0.0],
        "spiritual": [1.0, 0.5, 2.0, 2.5],
    },
    "weight": {
        "ethereal": [0.0, 0.0, 2.0, 1.0],
        "light": [0.0, 0.0, 1.5, 1.5],
        "medium": [1.0, 1.5, 0.5, 0.5],
        "heavy": [2.5, 1.0, 1.0, 0.5],
        "massive": [2.0, 3.0, 0.0, 0.0],
    },
    "texture": {
        "smooth": [1.0, 2.5, 1.0, 3.0],
        "rough": [3.5, 3.5, 0.5, 1.0],
        "crystalline": [2.5, 1.0, 4.0, 1.5],
        "diffuse": [1.0, 1.0, 2.5, 3.0],
        "granular": [2.0, 2.0, 1.0, 1.0],
        "glassy": [1.5, 1.0, 3.5, 1.0],
        "metallic": [2.0, 3.0, 2.0, 0.0],
    },
    "motion": {
        "static": [0.0, 4.0, 0.0, 1.0],
        "flowing": [1.0, 0.0, 1.0, 4.0],
        "surging": [4.5, 0.0, 2.0, 1.0],
        "swirling": [2.5, 0.0, 4.0, 1.0],
        "oscillating": [2.0, 1.0, 3.0, 1.0],
        "drifting": [1.0, 0.5, 3.0, 2.5],
        "pulsing": [2.5, 0.5, 1.5, 2.0],
    },
    "density": {
        "vacuum": [3.0, 0.0, 2.5, 1.0],
        "sparse": [2.5, 0.0, 2.0, 1.0],
        "moderate": [1.0, 1.0, 1.0, 1.0],
        "dense": [1.0, 3.0, 1.0, 2.0],
        "saturated": [1.5, 2.5, 2.0, 2.5],
    },
    "temperature": {
        "cold": [0.0, 3.0, 1.0, 2.0],
        "cool": [0.5, 2.0, 1.5, 2.0],
        "neutral": [1.0, 1.0, 1.0, 1.0],
        "warm": [2.5, 1.0, 1.5, 1.0],
        "hot": [4.0, 0.5, 1.0, 0.0],
    },
    "polarity": {
        "active": [3.0, 1.0, 2.0, 0.5],
        "receptive": [0.5, 2.0, 1.0, 3.0],
        "balanced": [1.0, 1.0, 1.0, 1.0],
        "neutral": [1.0, 1.0, 1.0, 1.0],
    },
    "celestial": {
        "solar": [4.0, 0.5, 1.0, 0.0],
        "lunar": [0.0, 1.0, 0.0, 4.0],
        "stellar": [1.0, 0.5, 3.0, 1.0],
        "planetary": [1.5, 1.5, 1.5, 1.5],
        "void": [0.5, 0.5, 0.5, 0.5],
    },
    "archetype": {
        "maiden": [1.0, 0.5, 3.0, 1.0],
        "mother": [0.5, 2.0, 0.5, 3.0],
        "crone": [1.0, 3.0, 2.0, 2.0],
        "hero": [4.0, 1.0, 2.0, 0.5],
        "mentor": [1.5, 3.0, 2.0, 1.0],
        "shadow": [0.5, 0.5, 1.0, 4.0],
        "trickster": [2.0, 0.5, 4.0, 1.0],
    },
}


def round2(value: float) -> float:
    return round(value * 100) / 100


def compute_element_scores(tags: dict[str, str]) -> dict[str, float]:
    """Recompute element scores from tags using the same formula as TagEngine."""
    raw = [0.0, 0.0, 0.0, 0.0]  # fire, earth, air, water
    for dim, value in tags.items():
        weight = DIMENSION_WEIGHTS.get(dim, 2.0)
        vec = VECTOR_TABLES[dim].get(value, [1.0, 1.0, 1.0, 1.0])
        for i in range(4):
            raw[i] += vec[i] * weight

    # Normalize to 0-10
    max_val = max(raw) if max(raw) > 0 else 1.0
    return {
        "fire": round2(raw[0] / max_val * 10.0),
        "earth": round2(raw[1] / max_val * 10.0),
        "air": round2(raw[2] / max_val * 10.0),
        "water": round2(raw[3] / max_val * 10.0),
    }


def validate_manifest(manifest_path: Path, compute_scores: bool = False) -> bool:
    ok = True
    errors = []
    warnings = []

    if not manifest_path.exists():
        print(f"ERROR: Manifest not found at {manifest_path}")
        return False

    try:
        with open(manifest_path, "r", encoding="utf-8") as f:
            data = json.load(f)
    except json.JSONDecodeError as e:
        print(f"ERROR: Invalid JSON: {e}")
        return False

    sounds = data.get("sounds", [])
    print(f"Manifest version: {data.get('version', '???')}")
    print(f"Sounds found: {len(sounds)}")
    print()

    seen_ids = set()
    manifest_dir = manifest_path.parent

    for idx, sound in enumerate(sounds):
        prefix = f"[{idx + 1}/{len(sounds)}] {sound.get('id', '???')}"

        # Required fields
        for field in ["id", "name", "tags", "elementScores", "durationSeconds", "cdnUrl"]:
            if field not in sound:
                errors.append(f"{prefix}: missing required field '{field}'")
                ok = False

        # Unique ID
        sound_id = sound.get("id")
        if sound_id:
            if sound_id in seen_ids:
                errors.append(f"{prefix}: duplicate id '{sound_id}'")
                ok = False
            seen_ids.add(sound_id)

        # Validate 12 tag dimensions
        tags = sound.get("tags", {})
        for dim, valid_values in VALID_TAGS.items():
            if dim not in tags:
                errors.append(f"{prefix}: missing tag dimension '{dim}'")
                ok = False
            elif tags[dim] not in valid_values:
                errors.append(
                    f"{prefix}: invalid value '{tags[dim]}' for '{dim}'. Valid: {valid_values}"
                )
                ok = False

        # Check bundle file exists if referenced
        bundle_file = sound.get("bundleFilename")
        if bundle_file:
            file_path = manifest_dir / bundle_file
            if not file_path.exists():
                warnings.append(f"{prefix}: bundle file '{bundle_file}' not found on disk")

        # Optional: recompute scores
        if compute_scores and "tags" in sound:
            computed = compute_element_scores(tags)
            stored = sound.get("elementScores", {})
            mismatches = []
            for el in ["fire", "earth", "air", "water"]:
                if abs(computed[el] - stored.get(el, 0)) > 0.05:
                    mismatches.append(f"  {el}: stored={stored.get(el)}, computed={computed[el]}")
            if mismatches:
                warnings.append(f"{prefix}: element score mismatch:")
                warnings.extend(mismatches)

    if errors:
        print("ERRORS:")
        for e in errors:
            print(f"  {e}")
        print()

    if warnings:
        print("WARNINGS:")
        for w in warnings:
            print(f"  {w}")
        print()

    if ok and not warnings:
        print("All sounds passed validation.")
    elif ok:
        print("Validation passed with warnings.")
    else:
        print(f"Validation FAILED: {len(errors)} error(s), {len(warnings)} warning(s).")

    return ok


if __name__ == "__main__":
    compute = "--compute-scores" in sys.argv
    manifest = Path(__file__).parent / "sounds_manifest.json"
    success = validate_manifest(manifest, compute_scores=compute)
    sys.exit(0 if success else 1)
