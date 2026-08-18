#!/usr/bin/env python3
"""Generate compact proof-carrying F3 radius-two plans for Lean.

This is an untrusted certificate generator. It may search, eliminate, and choose
proof witnesses, but the generated plan is accepted only if the Lean checker
reconstructs every parity row, validates every certificate, and verifies complete
coverage of every affected distance-two support.
"""
from __future__ import annotations

import json
import multiprocessing as mp
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
IN = ROOT / "formal_inputs"
D = 16
R = 47
EDITS = [(q, r, i) for q in range(3) for r in range(R) for i in range(D)]
_G = None


def target(a: int, b: int, c: int) -> int:
    i, j = divmod(a, 4)
    j2, k = divmod(b, 4)
    return int(j == j2 and c == 4 * k + i)


def coord_index(x) -> int:
    a, b, c = map(int, x)
    return (a * D + b) * D + c


def decode_coord(x: int):
    a, rem = divmod(x, D * D)
    b, c = divmod(rem, D)
    return (a, b, c)


def affects(M, edit, coords) -> bool:
    q, r, i = edit
    for raw in coords:
        x = decode_coord(raw) if isinstance(raw, int) else tuple(raw)
        if x[q] != i:
            continue
        if all(M[o][r][x[o]] for o in range(3) if o != q):
            return True
    return False


def variable_map(M):
    bit = {}
    n = 0
    for q in range(3):
        for r, row in enumerate(M[q]):
            for i, present in enumerate(row):
                if present:
                    bit[q, r, i] = n
                    n += 1
    return bit


def parity_equation(M, bit, xyz):
    a, b, c = xyz
    terms = []
    for r in range(R):
        if M[0][r][a] and M[1][r][b] and M[2][r][c]:
            terms.append(r)
    k = len(terms)
    t = target(a, b, c)
    if k == 0:
        return (0, 1) if t else None
    if k > 4:
        return None
    neg = (t - k) % 3
    if neg > k or neg + 3 <= k:
        return None
    mask = 0
    for r in terms:
        mask ^= 1 << bit[0, r, a]
        mask ^= 1 << bit[1, r, b]
        mask ^= 1 << bit[2, r, c]
    return mask, neg & 1


def certificate_holds(M, coords) -> bool:
    bit = variable_map(M)
    mask = 0
    rhs = 0
    for raw in coords:
        xyz = decode_coord(raw) if isinstance(raw, int) else tuple(raw)
        eq = parity_equation(M, bit, xyz)
        if eq is None:
            return False
        m, y = eq
        mask ^= m
        rhs ^= y
    return mask == 0 and rhs == 1


def contradiction_witness(M):
    bit = variable_map(M)
    pivots = {}
    for a in range(D):
        for b in range(D):
            for c in range(D):
                eq = parity_equation(M, bit, (a, b, c))
                if eq is None:
                    continue
                mask, rhs = eq
                provenance = 1 << ((a * D + b) * D + c)
                if mask == 0:
                    if rhs:
                        return provenance
                    continue
                while mask:
                    p = mask.bit_length() - 1
                    if p not in pivots:
                        pivots[p] = (mask, rhs, provenance)
                        break
                    pm, py, pp = pivots[p]
                    mask ^= pm
                    rhs ^= py
                    provenance ^= pp
                if mask == 0 and rhs:
                    return provenance
    return None


def witness_coords(bits: int):
    out = []
    while bits:
        low = bits & -bits
        out.append(low.bit_length() - 1)
        bits -= low
    return tuple(out)


def toggle_copy(base, *indices):
    M = [[row[:] for row in Q] for Q in base]
    for idx in indices:
        q, r, i = EDITS[idx]
        M[q][r][i] ^= 1
    return M


def init_worker(factors, distance1):
    global _G
    data = json.loads(Path(factors).read_text())
    cert = json.loads(Path(distance1).read_text())
    base = [data["U"], data["V"], data["W"]]
    base_cert = cert["base_certificate_equations"]
    dedicated = {
        tuple(item["edit"][:3]): item["equations"]
        for item in cert["edit_certificates"]
    }
    _G = (base, base_cert, dedicated)


def fresh_for_first(first: int):
    base, base_cert, dedicated = _G
    e1 = EDITS[first]
    current = dedicated[e1] if affects(base, e1, base_cert) else base_cert
    M = toggle_copy(base, first)
    if not certificate_holds(M, current):
        raise RuntimeError(("invalid distance-one certificate", first))
    records = []
    for second in range(first + 1, len(EDITS)):
        e2 = EDITS[second]
        if not affects(M, e2, current):
            continue
        M2 = toggle_copy(base, first, second)
        witness = contradiction_witness(M2)
        if witness is None:
            raise RuntimeError(("parity-consistent support", first, second))
        records.append((second, witness_coords(witness)))
    return first, tuple(coord_index(x) for x in current), records


def unaffected(M, second: int, witness) -> bool:
    return not affects(M, EDITS[second], witness)


def build_plan(factors_path: Path, distance1_path: Path, workers: int):
    data = json.loads(factors_path.read_text())
    cert = json.loads(distance1_path.read_text())
    base = [data["U"], data["V"], data["W"]]
    base_cert = cert["base_certificate_equations"]
    dedicated = {
        tuple(item["edit"][:3]): item["equations"]
        for item in cert["edit_certificates"]
    }

    with mp.Pool(workers, initializer=init_worker,
                 initargs=(str(factors_path), str(distance1_path))) as pool:
        rows = list(pool.imap(fresh_for_first, range(len(EDITS)), chunksize=1))
    rows.sort(key=lambda x: x[0])

    current_witness = [None] * len(EDITS)
    fresh_records = [[] for _ in EDITS]
    for first, current, records in rows:
        current_witness[first] = current
        fresh_records[first] = records

    # Candidate certificate library per first support: current contradiction plus
    # every fresh contradiction found with that canonical first edit.
    candidates = []
    for first in range(len(EDITS)):
        M1 = toggle_copy(base, first)
        pool = {current_witness[first]}
        pool.update(w for _, w in fresh_records[first])
        valid = [w for w in sorted(pool, key=lambda w: (len(w), w))
                 if certificate_holds(M1, w)]
        candidates.append(valid)

    certs = []
    cert_id = {}

    def cid(w):
        w = tuple(w)
        if w not in cert_id:
            cert_id[w] = len(certs)
            certs.append(w)
        return cert_id[w]

    current = [cid(w) for w in current_witness]
    groups = []
    assignments = [[] for _ in EDITS]

    # Greedy set cover, independently for each canonical first edit. Any fresh
    # pair not covered by a certificate already valid after the first edit gets
    # a direct two-edit certificate from the elimination witness.
    for first in range(len(EDITS)):
        fresh = {second: witness for second, witness in fresh_records[first]}
        uncovered = set(fresh)
        M1 = toggle_copy(base, first)
        coverages = []
        for w in candidates[first]:
            cover = {s for s in uncovered if unaffected(M1, s, w)}
            if cover:
                coverages.append((w, cover))
        while uncovered:
            best_w = None
            best_cover = set()
            for w, cover in coverages:
                active = cover & uncovered
                if len(active) > len(best_cover):
                    best_w = w
                    best_cover = active
            if not best_cover:
                break
            gid = len(groups)
            groups.append({"first": first, "cert": cid(best_w)})
            for second in sorted(best_cover):
                assignments[first].append({"second": second, "kind": 0, "ref": gid})
            uncovered -= best_cover
        for second in sorted(uncovered):
            assignments[first].append({
                "second": second,
                "kind": 1,
                "ref": cid(fresh[second]),
            })
        assignments[first].sort(key=lambda a: a["second"])
        if [a["second"] for a in assignments[first]] != sorted(fresh):
            raise RuntimeError(("coverage mismatch", first))

    return {
        "certificates": [list(w) for w in certs],
        "current_certificate": current,
        "groups": groups,
        "assignments": assignments,
        "fresh_pairs": sum(len(x) for x in assignments),
        "direct_pairs": sum(a["kind"] == 1 for xs in assignments for a in xs),
    }


def main() -> None:
    workers = max(1, min(4, mp.cpu_count()))
    specs = [
        ("alpha",
         IN / "f3__data__r47_alphatensor_f2_factors.json",
         IN / "f3__certificates__alpha_distance1_f3_obstruction.json"),
        ("flips",
         IN / "f3__data__r47_flips_data.json",
         IN / "f3__certificates__flips_distance1_f3_obstruction.json"),
    ]
    for name, factors, cert in specs:
        plan = build_plan(factors, cert, workers)
        path = IN / f"{name}_f3_radius2_plan.json"
        path.write_text(json.dumps(plan, separators=(",", ":")) + "\n")
        print(
            name,
            "certificates", len(plan["certificates"]),
            "groups", len(plan["groups"]),
            "fresh_pairs", plan["fresh_pairs"],
            "direct_pairs", plan["direct_pairs"],
        )


if __name__ == "__main__":
    main()
