#!/usr/bin/env python3
"""Independent byte-array replay of a Z/4 first-order no-lift certificate.

This deliberately does not reuse the bit-packed elimination representation in
lift_mod4_generic.py.  It directly accumulates every variable coefficient in
the selected equations and checks that the left side cancels while the right
side is 1 in F2.
"""
from __future__ import annotations
import argparse, json
from pathlib import Path

D = 16

def target(a: int, b: int, c: int) -> int:
    ai, aj = divmod(a, 4)
    bj, bk = divmod(b, 4)
    return int(aj == bj and c == 4 * bk + ai)

def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("factors")
    p.add_argument("certificate")
    args = p.parse_args()
    factors = json.loads(Path(args.factors).read_text())
    result = json.loads(Path(args.certificate).read_text())
    U = factors.get("U", factors.get("u"))
    V = factors.get("V", factors.get("v"))
    W = factors.get("W", factors.get("w"))
    r = len(U)
    coefficients = bytearray(3 * r * D)
    rhs = 0
    ids = result["contradiction_certificate"]["equation_indices"]
    for e in ids:
        a, rem = divmod(e, D * D)
        b, c = divmod(rem, D)
        integer_value = 0
        for q in range(r):
            u, v, w = U[q][a], V[q][b], W[q][c]
            integer_value += u * v * w
            if v and w:
                coefficients[q * D + a] ^= 1
            if u and w:
                coefficients[r * D + q * D + b] ^= 1
            if u and v:
                coefficients[2 * r * D + q * D + c] ^= 1
        residual = integer_value - target(a, b, c)
        if residual % 2:
            raise SystemExit(f"input is not an F2 scheme at equation {e}")
        rhs ^= (residual // 2) & 1
    nonzero = [i for i, x in enumerate(coefficients) if x]
    if nonzero or rhs != 1:
        raise SystemExit(
            f"INVALID certificate: {len(nonzero)} surviving coefficients, RHS={rhs}"
        )
    print(
        f"VALID no-lift certificate: XOR of {len(ids)} equations gives 0 = 1 "
        f"over F2 ({3*r*D} lift variables)"
    )

if __name__ == "__main__":
    main()
