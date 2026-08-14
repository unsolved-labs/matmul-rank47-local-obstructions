# R006 — Rank-47 matrix-multiplication local obstructions

**Unsolved Labs Research Release R006**

Exact computer-assisted nonexistence certificates around the two public rank-47 decompositions of 4×4 matrix multiplication over `F2`.

## Result

The global characteristic-zero rank-47 problem remains open. This release establishes two narrower exact statements.

1. **No coefficient-wise mod-4 lift of either frozen binary rank-47 scheme.** For the AlphaTensor and Kauers–Moosbauer decompositions, the complete first-order lifting systems over `F2` are inconsistent. Explicit XOR contradiction certificates use 523 and 292 tensor equations, respectively.

2. **No `F3` coefficient assignment on either frozen support, or after any one or two factor-entry support toggles.** Each support within factor-entry Hamming distance at most two violates a necessary sign-parity condition over `F3`. The audit covers all 2,256 single toggles per seed and every affected ordered second toggle: 15,075 for AlphaTensor and 18,157 for Kauers–Moosbauer, with zero parity-consistent cases.

## Baseline

The frozen inputs are two public rank-47 binary decompositions: AlphaTensor and Kauers–Moosbauer. Rank 47 is known in characteristic two; the audited characteristic-zero/rational frontier remains rank 48.

This release does **not** establish a lower bound of 48 over `F3`, `Q`, `R`, or `C`.

## Exact trust boundary

- Both binary seeds are checked against all 4,096 matrix-multiplication tensor equations.
- Mod-4 lifting reduces exactly to linear systems over `F2` with 2,256 correction variables.
- Each no-lift contradiction is replayed by two independent implementations.
- The `F3` support exclusions use exact parity constraints only.
- All 2,256 single support edits per seed are checked.
- The distance-two verifier exhausts every second edit capable of invalidating the current contradiction.
- No floating-point acceptance threshold enters any released claim.

## Reproduce

Linux with Python 3.12+ is sufficient:

```bash
./verify_release.sh
```

Expected final line:

```text
ALL R006 EXACT REPLAYS PASSED
```

## Repository layout

- `mod4/` — exact no-lift generator and two independent checkers.
- `f3/` — independent support-obstruction checkers and exhaustive distance-two verifier.
- `artifact/` — losslessly compressed, base64-encoded frozen inputs and certificates; `verify_release.sh` restores the exact byte streams before replay.
- `RESULTS.json` — machine-readable result summary.
- `CLAIM_BOUNDARY.md` — precise limitations.
- `PROVENANCE.md` — provenance of the frozen public rank-47 inputs.
- `.github/workflows/verify.yml` — CI replay of the complete verifier.

## Status

- Proof-carrying computational release
- Independent specialist review: pending
- Global rank-47 problem: open

## Public release page

https://unsolved-labs.github.io/results/r006-matmul-rank47-obstructions/
