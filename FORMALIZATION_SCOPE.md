# R006 formalization scope

R006 uses exact finite certificates rather than a proof assistant as its primary machine-verification layer. This is a deliberate trust-boundary decision, not a claim that the mathematics is unsuitable for formalization.

## Current machine-checked core

The released checkers establish, by exact integer/bit arithmetic:

- validity of both frozen rank-47 `F2` tensor decompositions at all 4,096 coordinates;
- construction and inconsistency of each coefficient-wise `Z/4Z` first-order lifting system;
- replay of compact XOR contradiction certificates for those systems;
- sound necessary sign-parity contradictions for the frozen `F3` supports and all single toggles;
- exhaustive coverage of every unordered pair of support toggles at distance two, with a surviving or freshly generated parity contradiction for each pair.

The human proof that these finite certificates imply the stated mathematical results is in `manuscript/r006_local_obstructions.tex`.

## Natural Lean targets

If a tested Lean 4/Mathlib formalization is added later, the highest-value declarations are small abstract lemmas rather than a transcription of millions of finite cases.

1. **Mod-4 linearization.** For binary `u,v,w` and correction bits `x,y,z`, prove

   ```text
   (u + 2x)(v + 2y)(w + 2z)
   = uvw + 2(xvw + uyw + uvz)  (mod 4).
   ```

   Lift this coordinatewise to the tensor-factorization statement.

2. **XOR certificate soundness.** For a finite linear system over `F2`, prove that a finite subset of rows summing to coefficient vector zero and RHS one implies unsatisfiability.

3. **F3 sign encoding.** Prove that every nonzero `F3` value is `±1`, and that a product of factor signs corresponds to XOR/addition of sign bits modulo two.

4. **Unique negative-count parity lemma.** If a coordinate has `k` active monomials and the congruence `n ≡ t-k (mod 3)` has a unique solution `n ∈ [0,k]`, prove that every satisfying `F3` assignment obeys the emitted parity equation.

5. **Parity-certificate soundness.** An XOR contradiction among necessary sign-parity equations excludes a coefficient assignment satisfying the original tensor equations.

6. **Certificate preservation under a support toggle.** If a toggle changes no monomial in any coordinate used by a valid parity certificate, the same certificate remains valid after the toggle.

7. **Pair-enumeration coverage.** Canonically enumerating `(i,j)` with `0 ≤ i < j < 2256` visits every unordered pair of distinct support entries exactly once.

A formalization can treat the frozen certificate data and large pair sweep as externally checked data whose verification result enters only through a deliberately small interface. If instead all finite evaluation is brought into Lean, the build must remain practical and deterministic.

## Acceptance standard for future Lean code

Do not describe R006 as Lean-verified unless the production formalization:

- builds under a pinned Lean/Mathlib toolchain from a clean checkout;
- contains no `sorry`, `admit`, or equivalent proof bypass in the trusted production path;
- records the exact final declarations and their axiom sets;
- is wired into CI;
- has an explicit statement crosswalk to the manuscript and `claim.json`;
- proves the actual certificate-soundness/claim implication rather than a weakened toy statement.

Until then, the accurate description is **exact proof-carrying computational verification**, with the limitations documented in `VERIFICATION.md`.
