# R006 — Exact local obstructions around rank-47 4×4 matrix multiplication

**Unsolved Labs Research Release R006**

R006 is a proof-carrying computational study of two frozen public rank-47 decompositions of the $4\times4$ matrix-multiplication tensor over `F2`. It proves two **local nonexistence results** around those particular binary schemes.

The global rank-47 question outside characteristic two remains open.

## Result

### 1. No coefficient-wise `Z/4Z` lift of either frozen scheme

For the AlphaTensor and Kauers–Moosbauer rank-47 binary decompositions distributed here, the complete first-order lifting systems over `F2` are inconsistent.

- 4,096 tensor equations per seed;
- 2,256 coefficient-correction variables per lifting system;
- AlphaTensor contradiction certificate: 523 tensor equations;
- Kauers–Moosbauer contradiction certificate: 292 tensor equations.

Each frozen XOR certificate is replayed by two implementations, and the complete certificate is also regenerated deterministically from the frozen factors.

### 2. No `F3` coefficient assignment within support distance two

Fix the zero/nonzero factor-entry support of either frozen rank-47 scheme. No assignment of nonzero `F3` coefficients satisfies the matrix-multiplication tensor equations on:

- the frozen support;
- any of the 2,256 supports obtained by one factor-entry toggle; or
- any support obtained by two distinct factor-entry toggles.

There are

$$
\binom{2256}{2}=2{,}543{,}640
$$

unordered distance-two supports per seed. The release verifier covers **every one**.

| Frozen seed | Distance-two supports | Preserved contradiction | Fresh global parity check | Survivors |
|---|---:|---:|---:|---:|
| AlphaTensor | 2,543,640 | 2,451,033 | 92,607 | 0 |
| Kauers–Moosbauer | 2,543,640 | 2,418,698 | 124,942 | 0 |

The `F3` proof uses exact necessary sign-parity equations. An inconsistent parity subsystem rigorously excludes an `F3` coefficient assignment. A parity-consistent support, if one existed, would **not** by itself prove that a decomposition exists.

The complete radius-two proof is implemented twice: the primary Python verifier uses dynamically renumbered active sign variables and integer bitmasks, while an independently structured C++20 verifier uses a fixed 2,256-variable sign space, 36-word rows, its own exact `GF(2)` elimination, and OpenMP. The canonical release command requires both paths to pass.

## What this does not prove

R006 does **not** prove tensor rank at least 48 over `F3`, `Q`, `R`, or `C`.

It does not exclude:

- rank-47 `F3` supports at factor-entry distance at least three from both frozen seeds;
- another binary rank-47 decomposition with different lifting behavior;
- an odd-characteristic or characteristic-zero rank-47 decomposition unrelated to these local reductions.

See [`CLAIM_BOUNDARY.md`](CLAIM_BOUNDARY.md) for the citation-safe scope.

## Why this is relevant

AlphaTensor published a 47-multiplication algorithm for $4\times4$ matrix multiplication in arithmetic modulo two. Public 48-multiplication constructions are known outside characteristic two, including rational constructions. R006 does not close the one-multiplication gap; it identifies exact obstructions to two natural local routes starting from two known binary rank-47 schemes.

## Paper

- [Canonical manuscript source](manuscript/r006_local_obstructions.tex)
- [Reproducible PDF build instructions](manuscript/README.md)

The GitHub Actions `manuscript` job rebuilds the paper from source on every push and pull request and uploads the resulting PDF as the `r006-manuscript` workflow artifact. The source remains canonical so an opaque binary cannot silently drift from the reviewed text.

The manuscript derives both obstruction lemmas, proves certificate soundness, gives the complete support-radius-two accounting, explains the independent verification paths, and states the limitations explicitly.

## Exact verification

From a clean Linux checkout with Python 3.12+ and a C++20 compiler with OpenMP support:

```bash
./verify_release.sh
```

Expected final line:

```text
ALL R006 EXACT REPLAYS PASSED
```

The command:

1. verifies SHA-256 hashes of all immutable factor/certificate payloads;
2. checks both rank-47 binary seeds against all 4,096 tensor equations;
3. replays and regenerates both `Z/4Z` no-lift certificates;
4. replays the `F3` base and distance-one certificates through two implementations;
5. performs the complete 2,543,640-pair radius-two sweep independently in Python and C++20 for each seed and requires exact pair accounting with zero survivors.

See [`VERIFICATION.md`](VERIFICATION.md) for the exact trust boundary and [`STATEMENT_AUDIT.md`](STATEMENT_AUDIT.md) for the claim-to-proof/checker map.

## Formal verification boundary

R006 currently uses exact finite certificates, exhaustive replay, and independent complete implementations rather than Lean as its primary verification layer. The repository does not add untested proof-assistant code merely to claim formalization. [`FORMALIZATION_SCOPE.md`](FORMALIZATION_SCOPE.md) identifies the small algebraic and certificate-soundness lemmas that are appropriate future Lean targets and the standard such a formalization would need to meet.

## Provenance

The two canonical mathematical inputs are the frozen normalized factor objects in this repository, identified by SHA-256 and independently checked as valid `F2` rank-47 schemes. [`PROVENANCE.md`](PROVENANCE.md) records the public AlphaTensor and Kauers–Moosbauer source families and explains a historical limitation: the initial R006 release did not preserve the exact upstream file/commit used to produce each normalized JSON, so the release does not guess that identity retroactively.

## Repository map

- `manuscript/` — canonical paper source and deterministic PDF build; CI publishes the generated PDF as an artifact.
- `claim.json` — machine-readable canonical claim/non-claim record.
- `STATEMENT_AUDIT.md` — public claim → mathematical argument → executable evidence.
- `VERIFICATION.md` — reproduction commands and trust boundary.
- `FORMALIZATION_SCOPE.md` — proof-assistant scope and acceptance standard.
- `PROVENANCE.md` — frozen-input identity and public source context.
- `mod4/` — exact coefficient-wise no-lift generator and independent certificate replay.
- `f3/` — exact sign-parity certificate replay plus independent Python and C++20 complete radius-two verifiers.
- `artifact/` — losslessly compressed frozen factor/certificate payloads.
- `SHA256SUMS` — immutable artifact manifest.
- `RESULTS.json` — machine-readable verified counts.
- `REPLAY_OUTPUT.txt` — deterministic summary of the canonical successful replay.
- `.github/workflows/verify.yml` — clean-checkout exact proof replay and manuscript build.

## Status

- Exact proof-carrying computational release
- Complete support-distance-two theorem: verified by exhaustive exact replay
- Reproducible manuscript build: verified in CI
- Independent specialist review: **pending**
- Global rank-47 problem outside characteristic two: **open**

## AI-origin disclosure

R006 is an Unsolved Labs research release generated with frontier AI. Correctness claims rest on the public mathematical argument and exact machine-checkable artifacts in this repository; no private conversation or hidden reasoning is part of the research record.

## Public release page

https://unsolved-labs.github.io/results/r006-matmul-rank47-obstructions/
