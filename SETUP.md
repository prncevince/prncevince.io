# Quarto Site Environment Setup 

Here's all the setup.

## Quarto

Setup [quarto-shims](https://github.com/prncevince/quarto-shims).

Then, run below to install & setup quarto. `wget` is required in your shell environment, can be installed on Mac via homebrew.

```sh
./utils/download-quarto.sh
```

## R

Setup [r-shims](https://github.com/prncevince/r-shims).

Create RStudio project within RStudio.

```r
rstudioapi::initializeProject()
```

Initialize the `{renv}` environment. Important packages can be discovered in [utils/deps.R](utils/deps.R)

```r
renv::init()
```

## Start

Explode on paper.

## Fin
