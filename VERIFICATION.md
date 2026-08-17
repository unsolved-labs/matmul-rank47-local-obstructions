# R006 verification and trust boundary

R006 is a proof-carrying computational release. The public claims are intended to be reproducible from a clean checkout without trusting the search process that discovered the two seeds or the original contradiction certificates.

## One-command replay

Requirements:

- Linux/macOS-style shell environment;
- Python 3.12 or later;
- a C++20 compiler with OpenMP support (`g++` on the reference CI image);
- standard `base64`, `gzip`, and `sha256sum` utilities.

Run:

```bash
./verify_release.sh
```

A successful release replay ends with:

```text
ALL R006 EXACT REPLAYS PASSED
```

GitHub Actions runs the same command after syntax-checking the shell, Python, and C++ verification sources.

## What the command verifies

### 1. Frozen artifact identity

`SHA256SUMS` pins only the immutable compressed factor/certificate payloads. The release command checks every digest before decoding anything, restores the exact JSON byte streams in a temporary directory, and never relies on an unpacked working copy of the proof data.

### 2. Binary seed identity

`mod4/verify_f2_scheme.py` evaluates all 4,096 entries of the 4×4 matrix-multiplication tensor for each frozen rank-47 seed over `F2`.

This makes the frozen normalized factor object, not a moving upstream repository, the mathematical input to R006.

### 3. Coefficient-wise `Z/4Z` no-lift certificates

`mod4/lift_mod4_generic.py` reconstructs the complete first-order lifting system over `F2`: 4,096 equations in 2,256 correction variables. It deterministically regenerates a contradiction certificate.

Each frozen certificate is then replayed by two implementations:

- `mod4/check_mod4_certificate_generic.py`, using bit-packed row masks; and
- `mod4/independent_certificate_check.py`, using a byte-array accumulator and independently recomputing every selected equation.

Both check that the selected equations sum to coefficient vector zero and right-hand side one. The regenerated certificate is compared with the frozen result after removing only the temporary input path.

### 4. `F3` base and distance-one support obstructions

`f3/check_f3_support_obstruction.py` reconstructs the necessary sign-parity equations from the raw support data and checks the frozen base/distance-one certificate structure for all 2,256 possible single support toggles per seed.

`f3/check_f3_support_obstruction_independent.py` replays the same mathematical certificates with a separate bit-packed implementation. Both are Python, but they use different internal representations.

### 5. Complete distance-two support sweep: Python implementation

`f3/verify_distance2_parallel.py` covers every unordered pair of distinct factor-entry toggles.

For each of all 2,256 possible first toggles it establishes a current contradiction certificate: either the base certificate survives unchanged or a frozen dedicated distance-one certificate is checked. For every canonically later second toggle:

- if the second toggle cannot change a monomial occurring in the current certificate, that exact contradiction survives;
- otherwise the script applies both toggles, reconstructs all available necessary sign-parity equations over all 4,096 tensor coordinates, and performs exact Gaussian elimination over `F2` looking for a fresh contradiction.

There are

```text
C(2256, 2) = 2,543,640
```

unordered distance-two supports per seed. A valid Python report must contain:

```text
complete_pair_sweep = true
all_first_edits = 2256
distance2_pairs_total = 2543640
linearly_consistent_pairs = []
```

### 6. Independent complete distance-two sweep: C++20 implementation

`f3/independent_distance2_check.cpp` independently implements the same mathematical proof strategy with materially different software choices:

- a fixed 2,256-variable sign space rather than renumbering active variables per support;
- 36-word bit rows rather than Python arbitrary-precision integer masks;
- an independently written exact `GF(2)` Gaussian eliminator;
- OpenMP parallelism rather than Python multiprocessing.

`f3/export_distance2_inputs.py` performs only neutral JSON-to-text serialization so the C++ verifier does not need a third-party JSON dependency. It performs no parity or elimination mathematics.

The C++ verifier must independently:

- visit all 2,256 first edits;
- account for all 2,543,640 unordered pairs;
- validate every required distance-one certificate after the first toggle;
- return zero certificate failures and zero parity-consistent support pairs.

The canonical release command runs both complete implementations. Their exact partition statistics are intended to agree, not merely their final zero-survivor result.

## Mathematical trust boundary

The machine checks rely on the short implications proved in `manuscript/r006_local_obstructions.tex`:

1. a coefficient-wise `Z/4Z` lift induces the stated `F2` linear system;
2. a selected row sum yielding `0 = 1` proves that system inconsistent;
3. every genuine nonzero-coefficient `F3` decomposition on a fixed support satisfies each emitted parity equation;
4. an XOR contradiction in those necessary parity equations excludes a genuine `F3` assignment;
5. a support toggle that changes no monomial in a checked certificate leaves the certificate valid;
6. the canonical first/second ordering visits every unordered pair exactly once.

## What is not trusted

The final proof does not require trusting:

- the frontier-AI/search process that discovered or selected the two seeds;
- the search process that first found the contradiction certificates;
- floating-point optimization or numerical thresholds;
- `REPLAY_OUTPUT.txt` or any hand-written success assertion;
- a live upstream repository remaining unchanged.

All load-bearing finite evidence is regenerated or replayed from frozen data.

## Remaining verification limitations

R006 now has implementation diversity for the complete radius-two proof, but its assurance is not identical to R001's Lean-kernel proof.

- Both distance-two implementations check the same mathematically proved necessary sign-parity reduction; software diversity does not make that reduction independent mathematics.
- The C++ path consumes a minimal text serialization produced by a small Python exporter. The exporter is deliberately non-mathematical and auditable, but it remains part of the input path.
- The mathematical reductions are proved in the manuscript rather than kernel-checked in Lean.
- The initial release did not preserve immutable upstream file/commit identifiers for the normalized seeds; the frozen R006 factor hashes therefore define the canonical theorem inputs.
- Independent specialist review remains pending.

These limitations must not be hidden or translated into stronger review or formal-verification language.

## Why this release does not add untested Lean code

The finite claims have compact exact certificates, exhaustive replay, and independent complete implementations. A proof-assistant layer is valuable only if it decreases the remaining mathematical trust boundary. `FORMALIZATION_SCOPE.md` identifies the short lemmas appropriate for a future tested Lean formalization and the acceptance standard it must meet.

## Reproducibility policy

For any future release tag:

1. run `./verify_release.sh` from a clean checkout;
2. require both CI jobs to pass at the exact commit;
3. record the immutable commit/tag in public release metadata;
4. do not edit artifact payloads without updating hashes and rerunning the full proof;
5. keep `claim.json`, `RESULTS.json`, the manuscript, README, statement audit, and public site claim-consistent.
