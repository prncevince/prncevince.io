.PHONY: docs docs-dev docs-site docs-md docs-preview docs-preview-python conda-env-export conda-env-create

CONDA_ENV = environment.yml

docs: docs-site docs-md

#docs:
#	quarto render --profile site
#	quarto render --profile md --to gfm

docs-site:
	quarto render --profile site

docs-md:
	quarto render --profile md --to gfm

docs-dev:
	quarto preview

docs-preview:
	Rscript -e "servr::httw(dir = '_site')"

docs-preview-python:
	python -m http.server -d _site

conda-env-export:
	mamba env export > $(CONDA_ENV)
	sed -i '' -e '$$d' $(CONDA_ENV)

conda-env-create:
	mamba env create -f $(CONDA_ENV)
