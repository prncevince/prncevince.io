.PHONY: docs docs-dev docs-site docs-md docs-preview docs-preview-python conda-env-export conda-env-create proxy

CONDA_ENV = environment.yml
IP = $(shell ipconfig getifaddr en0)

docs: docs-site docs-md

docs-site:
	quarto render --profile site

docs-md:
	quarto render --profile md --to gfm

docs-dev:
	quarto preview --profile site --port 4321 --no-browser

docs-preview:
	Rscript -e "servr::httw(dir = '_site', hosturl = function(host) if (host == '127.0.0.1') 'localhost' else host)"

docs-preview-python:
	python -m http.server -d _site

conda-env-export:
	mamba env export > $(CONDA_ENV)
	sed -i '' -e '$$d' $(CONDA_ENV)

conda-env-create:
	mamba env create -f $(CONDA_ENV)

proxy:
	python -m http.server

proxy-subnet:
	python -m http.server --bind $(IP) -d $(D)
