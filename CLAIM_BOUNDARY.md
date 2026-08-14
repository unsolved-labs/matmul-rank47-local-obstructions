# Claim boundary

R006 does **not** prove that 4×4 matrix multiplication has tensor rank at least 48 over `F3`, `Q`, `R`, or `C`.

For each of the two frozen public rank-47 decompositions over `F2` in this repository, it proves:

1. no coefficient-wise lift to `Z/4Z` reduces to that frozen scheme modulo two and satisfies all 4,096 matrix-multiplication tensor equations; and
2. over `F3`, neither the frozen zero/nonzero factor-entry support nor any support obtained by one or two factor-entry toggles admits an assignment of nonzero coefficients satisfying the tensor equations.

The second statement is made in the frozen coordinate representation. Relabeling the 47 rank-one terms does not change it.

The release does not exclude a rank-47 `F3` decomposition at support distance at least three, another binary rank-47 scheme with different lifting behavior, an odd-characteristic or characteristic-zero scheme unrelated to these reductions, or singular/denominator-sensitive characteristic-zero branches.

Independent specialist review is pending. No global lower bound of 48 is claimed.
