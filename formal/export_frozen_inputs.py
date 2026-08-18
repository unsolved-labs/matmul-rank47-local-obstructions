#!/usr/bin/env python3
"""Restore the exact frozen JSON objects needed by the Lean formalization.

This utility performs transport decoding only. It does not perform any
mathematical verification; Lean and the existing independent checkers do that.
"""
from __future__ import annotations

import base64
import gzip
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "formal_inputs"

LOGICAL = [
    "mod4/data/r47_alphatensor_f2_factors.json",
    "mod4/data/r47_flips_data.json",
    "mod4/certificates/alpha_mod4_result_generic.json",
    "mod4/certificates/flips_mod4_result.json",
    "f3/data/r47_alphatensor_f2_factors.json",
    "f3/data/r47_flips_data.json",
    "f3/certificates/alpha_distance1_f3_obstruction.json",
    "f3/certificates/flips_distance1_f3_obstruction.json",
]


def main() -> None:
    OUT.mkdir(exist_ok=True)
    for logical in LOGICAL:
        packed = ROOT / "artifact" / (logical.replace("/", "__") + ".gz.b64")
        restored = gzip.decompress(base64.b64decode(packed.read_bytes()))
        target = OUT / logical.replace("/", "__")
        target.write_bytes(restored)
        print(f"{logical}: {len(restored)} bytes -> {target.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
