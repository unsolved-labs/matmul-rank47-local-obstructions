# Provenance and frozen-input identity

R006 uses two public rank-47 decompositions of the 4×4 matrix-multiplication tensor over `F2` as **frozen mathematical inputs**. The release claims are about the exact normalized factor bytes distributed here, not about a moving upstream branch.

## Canonical R006 input identity

The canonical inputs are restored from the compressed payloads by `verify_release.sh` and checked directly against all 4,096 tensor equations.

### AlphaTensor-derived frozen seed

Normalized-factor SHA-256:

```text
48cc645eaa0b37cf39fe1f079354e06bb6448f2c837ac965993ec43d292b9ed7
```

Immutable payloads:

```text
artifact/f3__data__r47_alphatensor_f2_factors.json.gz.b64
artifact/mod4__data__r47_alphatensor_f2_factors.json.gz.b64
```

### Kauers–Moosbauer-derived frozen seed

Normalized-factor SHA-256:

```text
0777ee0faed803d874f1b4fa3ccf376899a2bd4b912e4a8079a7bd4ee16eba87
```

Immutable payloads:

```text
artifact/f3__data__r47_flips_data.json.gz.b64
artifact/mod4__data__r47_flips_data.json.gz.b64
```

The factor hashes above are computed on the restored normalized JSON bytes, while `SHA256SUMS` pins the compressed/base64 transport payloads themselves.

## Public upstream context

### AlphaTensor

The rank-47 characteristic-two 4×4 construction was published in:

> A. Fawzi et al., “Discovering faster matrix multiplication algorithms with reinforcement learning,” *Nature* 610 (2022), 47–53. DOI: `10.1038/s41586-022-05172-4`.

Public paper:

https://doi.org/10.1038/s41586-022-05172-4

Official public algorithm/factorization repository:

https://github.com/google-deepmind/alphatensor

The official repository distributes AlphaTensor matrix-multiplication factorizations, including modular-arithmetic data.

### Kauers–Moosbauer / flip-graph source family

The flip-graph methodology is published in:

> M. Kauers and J. Moosbauer, “Flip Graphs for Matrix Multiplication,” *ISSAC 2023*, 381–388; arXiv:2212.01175. DOI: `10.1145/3597066.3597120`.

Public preprint:

https://arxiv.org/abs/2212.01175

Public matrix-multiplication repository maintained by Manuel Kauers:

https://github.com/mkauers/matrix-multiplication

### Catalog used during the research campaign

The original R006 notes identified `solven-eu/matmulcatalog` as the catalog through which the two normalized source records were used:

https://github.com/solven-eu/matmulcatalog

A provenance re-audit on 2026-08-17 observed catalog `master` at commit:

```text
e9f481ff0a1b87bf2da6217faada1c86c02729b3
```

This current snapshot is recorded only to make the re-audit reproducible. It is **not** asserted to be the historical commit from which the 2026-08-14 frozen R006 JSON was extracted.

## Historical provenance limitation

The initial R006 publication preserved the normalized factor bytes and hashes but did not preserve an immutable upstream repository commit + exact upstream file path for each normalized seed. Therefore this repository does not claim a byte-for-byte reconstruction from a particular historical upstream checkout.

For verification of R006, this does not create ambiguity about the theorem input: the two frozen factor objects above are the canonical objects, and `mod4/verify_f2_scheme.py` independently verifies that each is a valid rank-47 decomposition of the required `F2` matrix-multiplication tensor.

Future releases should preserve both:

1. the immutable upstream source identifier/file hash when available; and
2. the normalized release object/hash actually consumed by the proof.

## Scope

R006 makes no claim over upstream data beyond their role as provenance for the two frozen inputs. It does not claim that every AlphaTensor or flip-graph rank-47 object has the local obstruction properties proved here.
