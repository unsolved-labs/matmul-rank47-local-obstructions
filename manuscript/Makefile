PDF=r006_local_obstructions.pdf
TEX=r006_local_obstructions.tex

.PHONY: all clean

all: $(PDF)

$(PDF): $(TEX)
	pdflatex -interaction=nonstopmode -halt-on-error $(TEX)
	pdflatex -interaction=nonstopmode -halt-on-error $(TEX)

clean:
	rm -f *.aux *.log *.out *.toc $(PDF)
