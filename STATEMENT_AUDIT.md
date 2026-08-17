# R006 statement audit

This file maps each load-bearing public R006 statement to its mathematical justification and executable evidence.

## Canonical scope

R006 concerns two **frozen, normalized, rank-47 decompositions of the 4×4 matrix-multiplication tensor over `F2`**. The canonical factor bytes are immutable artifact payloads in this repository, identified by SHA-256 in `PROVENANCE.md` and checked directly by `verify_release.sh`.

R006 does **not** prove tensor rank at least 48 over `F3`, `Q`, `R`, or `C`.

## Claim-to-evidence map

| Public claim | Mathematical basis | Executable evidence | Required result |
|---|---|---|---|
| The AlphaTensor frozen input is a valid rank-47 `F2` 4×4 matrix-multiplication scheme. | Tensor identity in manuscript §2. | `mod4/verify_f2_scheme.py` on the restored AlphaTensor factors. | All 4,096 tensor coordinates match. |
| The Kauers–Moosbauer frozen input is a valid rank-47 `F2` scheme. | Same. | `mod4/verify_f2_scheme.py` on the restored flip-graph factors. | All 4,096 tensor coordinates match. |
| A coefficient-wise lift to `Z/4Z` reduces to an `F2` linear system in 2,256 correction bits. | Expansion `(u+2x)(v+2y)(w+2z)` modulo four; manuscript §3. | `mod4/lift_mod4_generic.py`. | 4,096 exact equations, 2,256 variables. |
| The AlphaTensor seed has no coefficient-wise `Z/4Z` lift. | XOR-certificate soundness, manuscript §3. | `mod4/check_mod4_certificate_generic.py`, `mod4/independent_certificate_check.py`, and deterministic regeneration by `mod4/lift_mod4_generic.py`. | The 523 selected rows sum to coefficient vector 0 and RHS 1; regenerated certificate matches the frozen result. |
| The Kauers–Moosbauer seed has no coefficient-wise `Z/4Z` lift. | Same. | Same two replay paths plus deterministic regeneration. | The 292 selected rows sum to coefficient vector 0 and RHS 1; regenerated certificate matches. |
| For a fixed support over `F3`, every emitted sign-parity equation is a necessary condition for an actual decomposition. | Every nonzero `F3` coefficient is `±1`; unique negative-monomial count fixes a parity equation. Manuscript §4. | Independently implemented in `f3/check_f3_support_obstruction.py` and `f3/check_f3_support_obstruction_independent.py`. | Each frozen contradiction reconstructs exactly. |
| Neither frozen support admits nonzero `F3` coefficients satisfying the tensor equations. | F3 parity-obstruction lemma, manuscript §4. | Base certificates replayed by both F3 checkers. | XOR contradiction. |
| Every support at factor-entry Hamming distance one from either seed is obstructed. | A toggle either preserves the base contradiction or has a dedicated checked certificate. | Both F3 base/distance-one checkers enumerate all 2,256 possible single toggles per seed. | All single-toggle supports certified; 70 AlphaTensor and 113 Kauers–Moosbauer toggles require dedicated certificates. |
| Every support at factor-entry Hamming distance two from either seed is obstructed. | Complete pair-coverage theorem, manuscript §5. Every first toggle has a checked current contradiction; every unordered second toggle either preserves it or triggers fresh exact parity elimination. | Primary: `f3/verify_distance2_parallel.py`. Independent: `f3/independent_distance2_check.cpp`, fed only by the non-mathematical `f3/export_distance2_inputs.py`. Both are invoked by `verify_release.sh`. | Each implementation visits all 2,256 first toggles, accounts for all `C(2256,2)=2,543,640` unordered pairs per seed, and returns zero survivors/certificate failures. Their preserved-vs-fresh partition counts must agree. |
| The AlphaTensor distance-two partition is 2,451,033 preserved contradictions + 92,607 fresh exact eliminations. | Same complete pair partition. | Both complete implementations. | Exact cross-implementation count agreement and zero survivors. |
| The Kauers–Moosbauer distance-two partition is 2,418,698 preserved + 124,942 fresh exact eliminations. | Same. | Both complete implementations. | Exact cross-implementation count agreement and zero survivors. |
| The finite claims use no floating-point threshold. | All proof reductions are exact finite algebra/bit arithmetic. | Production verification sources and canonical clean replay. | No numerical tolerance appears in any acceptance condition. |
| The immutable proof/data payloads are the intended frozen artifacts. | Cryptographic content identity. | `sha256sum -c SHA256SUMS` at the beginning of `verify_release.sh`. | Every compressed payload hash matches. |
| Independent specialist review is pending. | Release-status fact only. | `README.md`, `CLAIM_BOUNDARY.md`, `claim.json`. | Must remain `pending` unless public auditable evidence tied to the release exists. |

## Statement identity rules

When editing public material, preserve these distinctions:

1. **No mod-4 lift** means no coefficient-wise lift reducing to the *same frozen binary factorization*. It is not a general obstruction to rank 47 over `Z/4Z`.
2. **No F3 assignment within support distance two** is in the frozen factor-entry coordinate representation. It is not a global search over all rank-47 decompositions.
3. The F3 sign-parity system contains **necessary conditions**. Inconsistency rigorously proves nonexistence; parity consistency alone would not prove that an `F3` tensor decomposition exists.
4. The finite support-radius theorem requires complete pair enumeration. The canonical release therefore runs two complete implementations and requires both to account for every pair with zero survivors.
5. Independent software implementations reduce implementation risk; they do not replace the mathematical proof that the parity reduction is sound.
6. The result does not imply rank ≥48 over `F3`, characteristic zero, or any field outside the stated local tests.

## Public-source crosswalk

- `README.md` summarizes only claims whose required results pass in CI.
- `CLAIM_BOUNDARY.md` is the concise citation-safe scope statement.
- `manuscript/r006_local_obstructions.tex` is the standalone mathematical proof manuscript.
- `VERIFICATION.md` defines reproduction commands and the software/certificate trust boundary.
- `FORMALIZATION_SCOPE.md` records what is and is not Lean/formally checked.
- `PROVENANCE.md` identifies the frozen theorem inputs and public upstream context.
- `claim.json` is the machine-readable canonical claim/status record.
- `RESULTS.json` records the frozen exact counts.
- `REPLAY_OUTPUT.txt` is a human-readable summary; it is not itself trusted evidence.
