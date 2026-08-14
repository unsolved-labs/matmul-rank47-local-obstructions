#!/usr/bin/env python3
"""Exact verifier for a rank-r 4x4 matrix multiplication scheme over F2."""
from __future__ import annotations
import argparse, json
from pathlib import Path

D = 16

def target(a: int, b: int, c: int) -> int:
    i, j = divmod(a, 4)
    j2, k = divmod(b, 4)
    return int(j == j2 and c == 4 * k + i)

def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("factors")
    args = p.parse_args()
    data = json.loads(Path(args.factors).read_text())
    U = data.get("U", data.get("u"))
    V = data.get("V", data.get("v"))
    W = data.get("W", data.get("w"))
    if not (len(U) == len(V) == len(W)):
        raise SystemExit("factor matrices have different numbers of terms")
    r = len(U)
    if any(len(row) != D for M in (U, V, W) for row in M):
        raise SystemExit("each factor row must have 16 coordinates")
    mismatches = []
    for a in range(D):
        for b in range(D):
            for c in range(D):
                value = 0
                for q in range(r):
                    value ^= (U[q][a] & V[q][b] & W[q][c])
                expected = target(a, b, c)
                if value != expected:
                    mismatches.append((a, b, c, value, expected))
                    if len(mismatches) == 10:
                        break
            if len(mismatches) == 10:
                break
        if len(mismatches) == 10:
            break
    if mismatches:
        raise SystemExit(f"INVALID: first mismatches {mismatches}")
    print(f"VALID F2 rank-{r} 4x4 scheme: all {D**3} tensor equations hold")

if __name__ == "__main__":
    main()
