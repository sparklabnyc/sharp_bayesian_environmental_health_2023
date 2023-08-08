# SHARP: Bayesian  Modeling  for Environmental Health Workshop

![course logo](assets/bmeh-1200x630.jpg)

## Introduction

GitHub repo through which we're developing and sharing materials for the SHARP Bayesian Modeling for Environmental Health Workshop, taking place in person during August 14th-15th 2023.

## Notes for attendees

The workshop will be a series of lectures and interactive supervised lab sessions.

We will be using Posit (RStudio) Cloud, which assumes knowledge of R and RStudio. We will also ask you to pull the final versions of the GitHub repo to your Cloud account. The basics of doing this are in a previously-created guide found via [another guide repo](https://github.com/rmp15/rstudio_cloud_tutorial/tree/main).

Below is the set of labs to follow throughout the two days:

### Day 1

[Introduction to Bayesian Methods](/labs/introduction_to_bayesian_methods/introduction_to_bayesian_methods.qmd)

[Bayesian Regression and Temporal Modelling](/labs/bayesian_regression_and_temporal_modelling/bayesian_regression_and_temporal_modelling.qmd)

[Hierarchical Modelling](/labs/hierarchical_modelling/hierarchical_modelling.qmd)

### Day 2

[Spatial and Spatio-temporal Modelling](/labs/spatiotemporal_models/spatiotemporal_models_partA.qmd)

[Software Options](/labs/software_options/software_options.qmd)

[Bayesian Non-Parametric Ensemble](/labs/bayesian_nonparametric_ensemble/bayesian_nonparametric_ensemble.qmd)

## Notes for those working on the repo

### Using `pre-commit`

Run `pre-commit install` to install the hooks. You now won't be able to commit until you pass the hooks. These (among other things) automatically format files and prevent us from committing ugly code. For more details, see the main [docs](https://pre-commit.com/) and the `R` [docs](https://lorenzwalthert.github.io/precommit/).

### Using `renv`

`renv` maintains consistency between users' `R` environments. Run `renv::restore()` and the environment will be downloaded into the repository based on the `renv.lock` file. If you want to add a packages to the lockfile, install the package and then run `renv::snapshot()`. For more details, see the [docs](https://rstudio.github.io/renv/articles/renv.html).

### Using Quarto for presentations

Quarto is pretty cool. I won't bore you, but have a look at the [docs](https://quarto.org/docs/guide/). Here, we're using it for [presentations](https://quarto.org/docs/presentations/revealjs/). It's designed by the folks at RStudio, so you `R` folk will be happy. Make a `.qmd` file and run `quarto render *.qmd` to generate the `html`, which you can open in browser. We can get fancy and import our own `css` to have a consistent theme for out presentations.
