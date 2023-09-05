.PHONY: docs docs-dev docs-preview docs-preview-python conda-env-export conda-env-create

CONDA_ENV = environment.yml

docs:
	quarto render

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
