#!/usr/bin/env python3
"""Complete F3 support-distance-two parity-obstruction verifier.

For every first factor-entry toggle, keep a contradiction certificate for the
resulting distance-one support: either the frozen base certificate (when the
first toggle cannot affect it) or the frozen dedicated distance-one
certificate. For each second toggle, the current certificate is unchanged
unless that toggle can alter one of its monomials. Only in the latter case do
we rebuild all available necessary F3 sign-parity equations and search for a
fresh contradiction.

This proves coverage of every unordered pair of distinct factor-entry toggles,
including pairs that jointly create a monomial even though neither toggle
alone affects the original base certificate.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import multiprocessing as mp
import time
from pathlib import Path

D = 16


def target(a: int, b: int, c: int) -> int:
    i, j = divmod(a, 4)
    j2, k = divmod(b, 4)
    return int(j == j2 and c == 4 * k + i)


def all_edits(rank: int):
    return [(q, r, i) for q in range(3) for r in range(rank) for i in range(D)]


def affects(M, edit, coords) -> bool:
    """Whether toggling edit can change a monomial in one listed coordinate."""
    q, r, i = edit
    for x in coords:
        if x[q] != i:
            continue
        if all(M[o][r][x[o]] for o in range(3) if o != q):
            return True
    return False


def parity_equation(M, bit, xyz):
    """Return a necessary F3 sign-parity equation, or None if not informative."""
    a, b, c = xyz
    terms = []
    for r in range(len(M[0])):
        if M[0][r][a] and M[1][r][b] and M[2][r][c]:
            terms.append(r)
    k = len(terms)
    t = target(a, b, c)
    if k == 0:
        if t:
            return 0, 1
        return None
    if k > 4:
        return None
    neg = (t - k) % 3
    # The number of negative monomials is unique exactly in this range.
    if neg > k or neg + 3 <= k:
        return None
    mask = 0
    for r in terms:
        mask ^= 1 << bit[0, r, a]
        mask ^= 1 << bit[1, r, b]
        mask ^= 1 << bit[2, r, c]
    return mask, neg & 1


def variable_map(M):
    bit = {}
    n = 0
    for q in range(3):
        for r, row in enumerate(M[q]):
            for i, x in enumerate(row):
                if x:
                    bit[q, r, i] = n
                    n += 1
    return bit


def certificate_holds(M, coords) -> bool:
    bit = variable_map(M)
    acc = 0
    rhs = 0
    for xyz in coords:
        eq = parity_equation(M, bit, tuple(xyz))
        if eq is None:
            return False
        m, y = eq
        acc ^= m
        rhs ^= y
    return acc == 0 and rhs == 1


def contradiction(M) -> bool:
    """Search all 4096 coordinates for an inconsistent necessary parity system."""
    bit = variable_map(M)
    piv = {}
    for a in range(D):
        for b in range(D):
            for c in range(D):
                eq = parity_equation(M, bit, (a, b, c))
                if eq is None:
                    continue
                m, y = eq
                if m == 0:
                    if y:
                        return True
                    continue
                while m:
                    j = m.bit_length() - 1
                    if j not in piv:
                        piv[j] = (m, y)
                        break
                    m ^= piv[j][0]
                    y ^= piv[j][1]
                if not m and y:
                    return True
    return False


_G = None


def init_worker(src, dist):
    global _G
    d = json.load(open(src))
    D1 = json.load(open(dist))
    M = [d['U'], d['V'], d['W']]
    base_coords = D1['base_certificate_equations']
    dedicated = {
        tuple(x['edit'][:3]): x['equations'] for x in D1['edit_certificates']
    }
    edits = all_edits(len(M[0]))
    _G = (M, base_coords, dedicated, edits)


def work(first_index):
    base, base_coords, dedicated, edits = _G
    M = [[row[:] for row in Q] for Q in base]
    e1 = edits[first_index]

    needs_dedicated = affects(M, e1, base_coords)
    if needs_dedicated:
        if e1 not in dedicated:
            raise AssertionError(f'missing dedicated distance-one certificate for {e1}')
        coords = dedicated[e1]
    else:
        coords = base_coords

    q, r, i = e1
    M[q][r][i] ^= 1
    if not certificate_holds(M, coords):
        raise AssertionError(f'distance-one certificate failed after first edit {e1}')

    fresh_checks = 0
    bad = []
    # Each unordered distance-two support appears exactly once.
    for second_index in range(first_index + 1, len(edits)):
        e2 = edits[second_index]
        if not affects(M, e2, coords):
            # The current XOR contradiction is literally unchanged.
            continue
        fresh_checks += 1
        q2, r2, i2 = e2
        M[q2][r2][i2] ^= 1
        if not contradiction(M):
            bad.append(e2)
        M[q2][r2][i2] ^= 1

    return first_index, e1, needs_dedicated, fresh_checks, bad


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('source')
    ap.add_argument('distance1')
    ap.add_argument('output')
    ap.add_argument('--workers', type=int, default=8)
    args = ap.parse_args()

    raw = Path(args.source).read_bytes()
    d = json.loads(raw)
    M = [d['U'], d['V'], d['W']]
    D1 = json.load(open(args.distance1))
    assert hashlib.sha256(raw).hexdigest() == D1['source_sha256']

    edits = all_edits(len(M[0]))
    assert len(edits) == 3 * len(M[0]) * D
    assert len(edits) == D1['total_possible_single_edits']

    t0 = time.time()
    with mp.Pool(
        args.workers,
        initializer=init_worker,
        initargs=(args.source, args.distance1),
    ) as pool:
        res = list(pool.imap_unordered(work, range(len(edits))))
    res.sort()

    bad = [
        {'first': list(e1), 'second': list(e2)}
        for _, e1, _, _, bs in res
        for e2 in bs
    ]
    dedicated_count = sum(1 for x in res if x[2])
    fresh = sum(x[3] for x in res)
    pair_total = len(edits) * (len(edits) - 1) // 2

    assert dedicated_count == D1['affected_single_edits'] == len(D1['edit_certificates'])

    obj = {
        'source': args.source,
        'source_sha256': hashlib.sha256(raw).hexdigest(),
        'distance1': args.distance1,
        'all_first_edits': len(edits),
        'first_edits_using_dedicated_certificate': dedicated_count,
        'distance2_pairs_total': pair_total,
        'distance2_pairs_certified_by_preserved_certificate': pair_total - fresh,
        'distance2_pairs_requiring_fresh_global_parity_check': fresh,
        'linearly_consistent_pairs': bad,
        'complete_pair_sweep': True,
        'elapsed_seconds': time.time() - t0,
        'claim': (
            'every support at factor-entry Hamming distance at most 2 from the '
            'frozen seed has a necessary F3 sign-parity contradiction'
        ),
    }
    Path(args.output).write_text(json.dumps(obj, indent=2) + '\n')
    print(json.dumps({k: v for k, v in obj.items() if k != 'linearly_consistent_pairs'}, indent=2))
    print('consistent_pair_count', len(bad))
    if bad:
        raise SystemExit(1)


if __name__ == '__main__':
    main()
