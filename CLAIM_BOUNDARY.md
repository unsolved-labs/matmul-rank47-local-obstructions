# R006 claim boundary

R006 does **not** prove that 4×4 matrix multiplication has tensor rank at least 48 over `F3`, `Q`, `R`, or `C`.

For each of the two frozen normalized rank-47 decompositions over `F2` distributed in this repository, it proves two local statements.

## 1. Coefficient-wise `Z/4Z` no-lift

There is no coefficient-wise lift of the frozen factorization to `Z/4Z` that:

- reduces entry-by-entry to the same binary factorization modulo two; and
- satisfies all 4,096 matrix-multiplication tensor equations.

This does **not** exclude a different rank-47 factorization over `Z/4Z` or another binary rank-47 seed with different lifting behavior.

## 2. `F3` support-radius-two obstruction

Fix the zero/nonzero factor-entry support of either frozen seed. There is no assignment of nonzero `F3` coefficients satisfying the tensor equations on:

- the frozen support itself;
- any support obtained by one factor-entry toggle; or
- any support obtained by two distinct factor-entry toggles.

There are 2,256 possible factor-entry positions and therefore

```text
C(2256, 2) = 2,543,640
```

unordered distance-two supports per seed. The release verifier now visits **all 2,256 possible first toggles** and accounts for every unordered pair exactly once. A pair is accepted as obstructed only when a checked sign-parity contradiction either survives the second toggle unchanged or is freshly reconstructed by exact global parity elimination.

This statement is made in the frozen coordinate representation. Consistent relabeling of the 47 rank-one terms does not change the mathematical support-radius statement.

The `F3` parity system is a system of **necessary** conditions. Inconsistency is a rigorous nonexistence certificate. If a support were parity-consistent, that alone would not prove that an `F3` decomposition exists.

## What remains open

R006 does not exclude:

- a rank-47 `F3` decomposition at factor-entry support distance at least three from both frozen seeds;
- another binary rank-47 scheme with different local behavior;
- an odd-characteristic or characteristic-zero rank-47 scheme unrelated to these reductions;
- characteristic-zero branches that are not coefficient-wise lifts of the two frozen binary schemes.

The global rank-47 question outside characteristic two remains open. Independent specialist review of R006 remains pending; the release is public and exactly replayable but is not described as peer reviewed.
