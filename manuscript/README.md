# R006 manuscript

Canonical source:

- `r006_local_obstructions.tex`

Build locally with a standard LaTeX installation:

```bash
make -C manuscript
```

This runs `pdflatex` twice with `-halt-on-error` and produces:

```text
manuscript/r006_local_obstructions.pdf
```

The GitHub Actions `manuscript` job performs the same build on every push and pull request, checks that the PDF is nonempty, and uploads it as the `r006-manuscript` workflow artifact.

The `.tex` source is the canonical versioned manuscript. The PDF is deliberately treated as a reproducible build product so it cannot silently drift from the reviewed source.
