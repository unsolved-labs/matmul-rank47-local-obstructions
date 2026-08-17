#!/usr/bin/env python3
"""Serialize frozen F3 support/certificate JSON to a minimal text interchange.

This script deliberately performs no parity mathematics. It exists only so the
independent C++ verifier does not need a third-party JSON parser. The C++ path
reconstructs and checks all mathematical equations itself.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("source")
    ap.add_argument("distance1")
    ap.add_argument("output")
    args = ap.parse_args()

    source = json.loads(Path(args.source).read_text())
    cert = json.loads(Path(args.distance1).read_text())

    factors = [source["U"], source["V"], source["W"]]
    rank = len(factors[0])
    assert rank == 47
    assert all(len(q) == rank for q in factors)
    assert all(len(row) == 16 for q in factors for row in q)
    assert cert["total_possible_single_edits"] == 3 * rank * 16

    base = cert["base_certificate_equations"]
    dedicated = cert["edit_certificates"]

    out: list[str] = []
    out.append(f"R {rank}")
    for q in range(3):
        for r in range(rank):
            bits = "".join(str(int(x)) for x in factors[q][r])
            assert set(bits) <= {"0", "1"} and len(bits) == 16
            out.append(f"F {q} {r} {bits}")

    out.append(f"B {len(base)}")
    for xyz in base:
        assert len(xyz) == 3
        out.append(f"C {int(xyz[0])} {int(xyz[1])} {int(xyz[2])}")

    out.append(f"D {len(dedicated)}")
    for item in dedicated:
        edit = item["edit"][:3]
        equations = item["equations"]
        out.append(
            f"E {int(edit[0])} {int(edit[1])} {int(edit[2])} {len(equations)}"
        )
        for xyz in equations:
            assert len(xyz) == 3
            out.append(f"C {int(xyz[0])} {int(xyz[1])} {int(xyz[2])}")

    Path(args.output).write_text("\n".join(out) + "\n")
    print(
        f"EXPORTED rank={rank} base_equations={len(base)} "
        f"dedicated_certificates={len(dedicated)}"
    )


if __name__ == "__main__":
    main()
