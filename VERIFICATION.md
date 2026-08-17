# R006 verification and trust boundary

R006 is a proof-carrying computational release. The public claims are intended to be reproducible from a clean checkout without the search process that discovered the seeds or certificates.

## One-command replay

Requirements:

- Linux/macOS-style shell environment;
- Python 3.12 or later;
- standard `base64`, `gzip`, and `sha256sum` utilities.

Run:

```bash
./verify_release.sh
```

A successful release replay ends with:

```text
ALL R006 EXACT REPLAYS PASSED
```

GitHub Actions runs the same command under Python 3.12 after syntax-checking the verification sources.

## What the command verifies

### 1. Frozen artifact identity

`SHA256SUMS` contains hashes only for the immutable compressed factor/certificate payloads. `verify_release.sh` checks every hash before decoding anything.

The compressed/base64 packaging is transport only: the verifier restores the exact JSON byte streams in a temporary directory and never relies on a pre-existing unpacked work tree.

### 2. Binary seed identity as tensor decompositions

`mod4/verify_f2_scheme.py` evaluates all 4,096 entries of the 4×4 matrix-multiplication tensor for each frozen rank-47 seed over `F2`.

This check is independent of the provenance narrative. Even if an upstream repository later changes, the R006 mathematical input is the frozen normalized factor object whose bytes and hash are part of this release.

### 3. `Z/4Z` coefficient-wise no-lift certificates

`mod4/lift_mod4_generic.py` reconstructs the complete first-order lifting system over `F2`, with 4,096 equations and 2,256 correction variables. It deterministically regenerates a contradiction certificate.

The frozen certificate is then replayed by:

- `mod4/check_mod4_certificate_generic.py`, using bit-packed row masks; and
- `mod4/independent_certificate_check.py`, using a byte-array coefficient accumulator and independently recomputing every selected equation.

Both verify that the selected equation sum has zero coefficient vector and right-hand side one. The regenerated result is compared with the frozen result after removing the temporary input path.

### 4. `F3` base and distance-one support obstructions

`f3/check_f3_support_obstruction.py` reconstructs the necessary sign-parity equations from raw support data, validates the frozen certificate metadata, and checks all 2,256 possible single support toggles per seed.

`f3/check_f3_support_obstruction_independent.py` replays the same mathematical certificates with a separate bit-packed implementation. This provides implementation diversity for the base/distance-one certificate replay, although both implementations are Python and use the same proven parity reduction.

### 5. Complete distance-two support sweep

`f3/verify_distance2_parallel.py` covers every unordered pair of distinct factor-entry toggles.

For each of all 2,256 possible first toggles it establishes a current contradiction certificate: either the base certificate survives unchanged or a frozen dedicated distance-one certificate is checked. For every canonically later second toggle:

- if the second toggle cannot change a monomial occurring in the current certificate, that exact contradiction survives and certifies the pair without new elimination;
- otherwise the script applies both toggles, reconstructs all available necessary sign-parity equations over all 4,096 tensor coordinates, and performs exact Gaussian elimination over `F2` looking for a contradiction.

There are

```text
C(2256, 2) = 2,543,640
```

unordered distance-two supports per seed. A valid final report must contain:

```text
complete_pair_sweep = true
all_first_edits = 2256
distance2_pairs_total = 2543640
linearly_consistent_pairs = []
```

The exact number of pairs requiring fresh global elimination is an implementation statistic, not part of the mathematical claim.

## Mathematical trust boundary

The machine checks rely on the following mathematical implications, proved in `manuscript/r006_local_obstructions.tex`:

1. a coefficient-wise `Z/4Z` lift induces the stated `F2` linear system;
2. an XOR of linear equations yielding `0 = 1` proves that system inconsistent;
3. every genuine nonzero-coefficient `F3` decomposition on a fixed support satisfies each parity equation emitted by the verifier;
4. an XOR contradiction in those necessary parity equations excludes a genuine `F3` assignment;
5. a support toggle that cannot alter any monomial in a checked certificate leaves the certificate valid;
6. the canonical first/second ordering visits every unordered pair exactly once.

## What is *not* trusted

The final proof does not require trusting:

- the AI/search process that discovered or selected the two seeds;
- the search process that first found the contradiction certificates;
- floating-point optimization or numerical thresholds;
- `REPLAY_OUTPUT.txt` or any human-written success claim;
- a live upstream repository remaining unchanged.

All load-bearing finite evidence is regenerated or replayed from frozen data.

## Remaining verification limitations

R006 is substantially machine checked, but its assurance is not identical to R001's Lean-kernel proof.

- The complete distance-two traversal/global parity search currently has one production implementation. Its mathematical reduction and coverage argument are public and compact, but an independently written second-language complete sweep would further reduce software trust.
- The base/distance-one F3 checkers are independently implemented in Python rather than in different runtimes/languages.
- The mathematical reduction itself is proved in the manuscript rather than kernel-checked in Lean.
- The original release did not preserve immutable upstream file/commit identifiers for the normalized seeds; therefore the frozen R006 factor hashes, not a reconstructed upstream path, define the canonical inputs.
- Independent specialist review remains pending.

These limitations must not be hidden or translated into stronger review/formal-verification language.

## Why this release does not add untested Lean code

The finite claims have compact exact certificates and deterministic exhaustive replay. A proof-assistant layer is valuable only if it decreases the trust boundary. This repository therefore does not add speculative or uncompiled Lean declarations merely for presentation. `FORMALIZATION_SCOPE.md` identifies the short mathematical lemmas that would be appropriate to formalize in a tested Lean environment.

## Reproducibility policy

For any future release tag:

1. run `./verify_release.sh` from a clean checkout;
2. require CI success at the exact commit;
3. record the immutable commit/tag in any public release page;
4. do not edit artifact payloads without updating hashes and rerunning the full proof;
5. keep `claim.json`, `RESULTS.json`, the manuscript, README, and public site statement-consistent.
