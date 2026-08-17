# R006 statement audit

This file maps each public R006 claim to its mathematical justification and executable evidence. It is intentionally narrower than a general research narrative: every load-bearing public statement should have a concrete row here.

## Canonical scope

R006 concerns two **frozen, normalized, rank-47 decompositions of the 4×4 matrix-multiplication tensor over `F2`**. The canonical factor bytes are the immutable artifact payloads in this repository, identified by SHA-256 in `PROVENANCE.md` and checked by `verify_release.sh`.

R006 does **not** prove tensor rank at least 48 over `F3`, `Q`, `R`, or `C`.

## Claim-to-evidence map

| Public claim | Mathematical basis | Executable evidence | Expected result |
|---|---|---|---|
| The AlphaTensor frozen input is a valid rank-47 `F2` 4×4 matrix-multiplication scheme. | Tensor identity in manuscript §2. | `mod4/verify_f2_scheme.py` on the restored AlphaTensor factor file. | All 4,096 tensor coordinates match. |
| The Kauers–Moosbauer frozen input is a valid rank-47 `F2` scheme. | Same. | `mod4/verify_f2_scheme.py` on the restored flip-graph factor file. | All 4,096 tensor coordinates match. |
| A coefficient-wise lift to `Z/4Z` reduces to a linear system over `F2` in 2,256 correction bits. | Expansion `(u+2x)(v+2y)(w+2z)` modulo four; manuscript §3. | `mod4/lift_mod4_generic.py`. | 4,096 exact equations, 2,256 variables. |
| The frozen AlphaTensor seed has no coefficient-wise `Z/4Z` lift. | XOR contradiction lemma, manuscript §3. | `mod4/check_mod4_certificate_generic.py` and `mod4/independent_certificate_check.py` on the 523-equation frozen certificate; regeneration by `mod4/lift_mod4_generic.py`. | Selected rows XOR to coefficient vector 0 and RHS 1; regenerated certificate matches frozen certificate. |
| The frozen Kauers–Moosbauer seed has no coefficient-wise `Z/4Z` lift. | Same. | The two mod-4 checkers on the 292-equation frozen certificate; regeneration by `mod4/lift_mod4_generic.py`. | Same contradiction and byte-level logical match after removing the temporary input path. |
| For a fixed factor-entry support over `F3`, the verifier's sign-parity equations are necessary conditions for an actual decomposition. | Every nonzero `F3` coefficient is `±1`; unique negative-monomial count yields a parity equation. Manuscript §4. | Implemented independently in `f3/check_f3_support_obstruction.py` and `f3/check_f3_support_obstruction_independent.py`. | Each frozen certificate reconstructs to an XOR contradiction. |
| Neither frozen support admits nonzero `F3` coefficients satisfying the tensor equations. | F3 parity-obstruction lemma, manuscript §4. | Base certificates replayed by both F3 checkers. | XOR contradiction. |
| Every support at factor-entry Hamming distance one from either seed is obstructed. | A single toggle either preserves the base contradiction or has a dedicated contradiction certificate. | Both F3 checkers enumerate all 2,256 possible single toggles per seed. | All single-toggle supports certified; 70 AlphaTensor and 113 Kauers–Moosbauer toggles require dedicated certificates. |
| Every support at factor-entry Hamming distance two from either seed is obstructed. | Complete-pair coverage theorem, manuscript §5. After every first toggle a checked current certificate exists; every unordered second toggle either preserves it or triggers a fresh exact global parity contradiction search. | `f3/verify_distance2_parallel.py` as invoked by `verify_release.sh`. | `complete_pair_sweep=true`, all 2,256 first toggles visited, all `C(2256,2)=2,543,640` unordered pairs accounted for, and `linearly_consistent_pairs=[]`. |
| The published finite claims do not depend on floating-point tolerances. | All reductions are finite integer/bit arithmetic. | Review of production verification sources plus clean replay. | No numerical threshold is used by any acceptance condition. |
| The immutable proof/data payloads are the intended frozen artifacts. | Cryptographic content identity. | `sha256sum -c SHA256SUMS` at the start of `verify_release.sh`. | Every compressed payload hash matches. |
| Independent specialist review is pending. | Release-status fact only. | `README.md`, `CLAIM_BOUNDARY.md`, `claim.json`. | Must remain `pending` until public auditable evidence exists. |

## Statement identity rules

When editing public material, preserve these distinctions:

1. **No mod-4 lift** means no coefficient-wise lift reducing to the *same frozen binary factorization*. It is not a general obstruction to rank 47 over `Z/4Z`.
2. **No F3 assignment within support distance two** is in the frozen factor-entry coordinate representation. It is not a global search over all rank-47 decompositions.
3. An inconsistent sign-parity system is a sound **necessary-condition obstruction**. A parity-consistent support would not, by itself, prove that an `F3` tensor decomposition exists.
4. The finite support-radius result is only as strong as the complete enumeration logic. The release therefore requires `complete_pair_sweep=true` and an empty survivor list before publishing the distance-two statement.
5. The result does not imply rank ≥48 over `F3`, characteristic zero, or any other field outside the stated local tests.

## Public-source crosswalk

- `README.md` should summarize only rows whose expected results pass in CI.
- `CLAIM_BOUNDARY.md` is the concise citation-safe non-claim boundary.
- `manuscript/r006_local_obstructions.tex` supplies the human mathematical proof of checker soundness.
- `VERIFICATION.md` defines commands and the software/certificate trust boundary.
- `claim.json` is the machine-readable canonical claim/status record.
- `RESULTS.json` records concrete verified counts produced by the frozen release.
