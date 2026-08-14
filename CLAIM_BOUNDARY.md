# Claim boundary

R006 does **not** prove that 4×4 matrix multiplication has tensor rank at least 48 over `F3`, `Q`, `R`, or `C`.

It proves the following representation-specific statements for the two frozen public rank-47 decompositions over `F2` used in this repository.

1. Neither decomposition admits a coefficient-wise lift to `Z/4Z` that reduces to the frozen scheme modulo two and satisfies all 4,096 matrix-multiplication tensor equations.
2. Over `F3`, neither frozen zero/nonzero factor-entry support admits an assignment of nonzero coefficients. The same is true after any one or any two factor-entry support toggles in the frozen coordinate representation. Consistent relabeling of the 47 rank-one terms does not change the statement.
3. The frozen 2,935-state rank-49 `F3` pool is exactly valid. Its complete ordinary-flip closure contains 2,950 rank-49 decompositions, 8,256 ordinary flip moves, zero reducible ordinary-flip states, and zero rank-48 endpoints. The earlier search that discovered the 2,935-state pool was heuristic; only the finite pool and its complete ordinary-flip closure are claimed exactly.

The release does not exclude:

- a rank-47 `F3` decomposition at support distance at least three from both frozen seeds;
- another rank-47 `F2` decomposition with different lifting behavior;
- a rank-47 decomposition over an odd field or characteristic zero unrelated to these reductions;
- singular or denominator-sensitive characteristic-zero branches;
- rank reductions requiring search paths outside the released finite flip component.

The novelty boundary is also deliberately conservative: the certificates are public and replayable, but independent specialist review is pending. R006 does not claim a global best-known lower bound or resolution of the parent rank-47 problem.

The frozen rank-49 pool and closure are distributed as base64-encoded lossless `.gz` text files; `verify_release.sh` decodes and decompresses them before exact replay.
