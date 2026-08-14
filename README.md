# R006 — Local obstructions around rank-47 4×4 matrix multiplication

**Unsolved Labs Research Release R006**

Exact computer-assisted nonexistence certificates around the two public rank-47 decompositions of 4×4 matrix multiplication over `F2`.

## Result

The global characteristic-zero rank-47 problem remains open. This release establishes three narrower exact statements.

1. **No coefficient-wise mod-4 lift of either frozen binary rank-47 scheme.**  For the AlphaTensor and Kauers–Moosbauer decompositions, the complete first-order lifting systems over `F2` are inconsistent. Explicit XOR contradiction certificates use 523 and 292 tensor equations, respectively.

2. **No `F3` coefficient assignment on either frozen support, or after any one or two factor-entry support toggles.**  Each support within factor-entry Hamming distance at most two violates a necessary sign-parity condition over `F3`. The audit covers all 2,256 single toggles per seed and all conflict-directed affected second toggles: 15,075 for AlphaTensor and 18,157 for Kauers–Moosbauer, with zero parity-consistent cases.

3. **A published finite rank-49 `F3` flip component has no reducible state.**  A heuristic search generated 2,935 exactly verified rank-49 decompositions. The complete ordinary-flip closure of that frozen pool contains 2,950 states and 8,256 ordinary flip moves, with zero reducible states and zero rank-48 endpoints. The generation phase is heuristic; the validity and complete ordinary-flip closure of the published finite pool are exact.

## Baseline

The two rank-47 binary seeds are the public AlphaTensor and Kauers–Moosbauer decompositions. Rank 47 is known in characteristic two. The audited characteristic-zero/rational frontier remains rank 48.

This release does **not** establish a lower bound of 48 over `F3`, `Q`, `R`, or `C`.

## Exact trust boundary

The release relies on exact finite arithmetic only:

- all 4,096 tensor equations are checked for both binary seeds;
- mod-4 lifting reduces to linear systems over `F2` with 2,256 correction variables;
- contradiction certificates are replayed by two independent implementations;
- the `F3` support claims reduce to exact parity contradictions;
- the distance-two audits enumerate every second edit capable of invalidating the current contradiction;
- every state in the frozen `F3` pool and closure is checked exactly;
- the ordinary-flip closure is regenerated and compared byte-for-byte with the frozen closure file.

No floating-point acceptance threshold enters any released claim.

## Reproduce

Linux with Python 3.12+ and a C++20 compiler is sufficient.

```bash
./verify_release.sh
```

Expected terminal line:

```text
ALL R006 EXACT REPLAYS PASSED
```

The two distance-two audits are parallelized across five processes and are intentionally run as separate commands inside the release verifier.

## Repository layout

- `mod4/` — two exact no-lift certificates, generators, and independent checkers.
- `f3/` — exact support-obstruction certificates and the frozen rank-49 flip component; the two large state lists are stored losslessly as base64-encoded `.gz` and decompressed by the verifier.
- `RESULTS.json` — machine-readable claim summary.
- `CLAIM_BOUNDARY.md` — limitations that must accompany citation of the result.
- `PROVENANCE.md` — public-source provenance for the frozen rank-47 inputs.
- `.github/workflows/verify.yml` — automated replay of the principal verifier.

## Status

- Proof-carrying computational release
- Exact local nonexistence claims independently replayable from this repository
- Independent specialist review: pending
- Global rank-47 problem: open

## Public release page

https://unsolved-labs.github.io/results/r006-matmul-rank47-obstructions/
