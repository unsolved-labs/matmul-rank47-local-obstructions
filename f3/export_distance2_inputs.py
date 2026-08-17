#!/usr/bin/env python3
"""Serialize frozen F3 support/certificate JSON to a minimal text interchange.

This script deliberately performs no parity mathematics. It exists only so the
independent C++ verifier does not need a third-party JSON parser. It validates
content identity and structural bounds, then serializes the exact frozen data.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

D = 16
RANK = 47


def checked_coord(xyz):
    assert len(xyz) == 3
    vals = tuple(int(x) for x in xyz)
    assert all(0 <= x < D for x in vals)
    return vals


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("source")
    ap.add_argument("distance1")
    ap.add_argument("output")
    args = ap.parse_args()

    raw = Path(args.source).read_bytes()
    source = json.loads(raw)
    cert = json.loads(Path(args.distance1).read_text())
    assert hashlib.sha256(raw).hexdigest() == cert["source_sha256"]

    factors = [source["U"], source["V"], source["W"]]
    rank = len(factors[0])
    assert rank == RANK
    assert all(len(q) == rank for q in factors)
    assert all(len(row) == D for q in factors for row in q)
    assert cert["total_possible_single_edits"] == 3 * rank * D

    base = cert["base_certificate_equations"]
    dedicated = cert["edit_certificates"]

    out: list[str] = []
    out.append(f"R {rank}")
    for q in range(3):
        for r in range(rank):
            bits = "".join(str(int(x)) for x in factors[q][r])
            assert set(bits) <= {"0", "1"} and len(bits) == D
            out.append(f"F {q} {r} {bits}")

    out.append(f"B {len(base)}")
    for xyz in base:
        a, b, c = checked_coord(xyz)
        out.append(f"C {a} {b} {c}")

    out.append(f"D {len(dedicated)}")
    seen = set()
    for item in dedicated:
        edit = tuple(int(x) for x in item["edit"][:3])
        assert len(edit) == 3
        q, r, i = edit
        assert 0 <= q < 3 and 0 <= r < rank and 0 <= i < D
        assert edit not in seen
        seen.add(edit)
        equations = item["equations"]
        assert equations
        out.append(f"E {q} {r} {i} {len(equations)}")
        for xyz in equations:
            a, b, c = checked_coord(xyz)
            out.append(f"C {a} {b} {c}")

    assert len(seen) == cert["affected_single_edits"]
    Path(args.output).write_text("\n".join(out) + "\n")
    print(
        f"EXPORTED rank={rank} base_equations={len(base)} "
        f"dedicated_certificates={len(dedicated)}"
    )


if __name__ == "__main__":
    main()
