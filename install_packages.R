# Welcome to SHARP Bayesian Modeling for Environmental Health Workshop!

# All the packages you will need should be already installed when you open the project in
# posit cloud.

# In case you'd like to run the labs on R locally in the future,
# the code below installs all necessary packages, including specific code for INLA


# install packages:
list.of.packages <- c(
  "here", "tidyverse", "bayesplot", "posterior", "hrbrthemes",
  "colorspace", "readr", "ggplot2", "rgeos", "patchwork",
  "coda", "ggmcmc", "lubridate", "fastDummies", "nimble"
)
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[, "Package"])]
if (length(new.packages)) install.packages(new.packages)

# install INLA
if (("INLA" %in% installed.packages()) == F) {
  install.packages("INLA", repos = c(getOption("repos"), INLA = "https://inla.r-inla-download.org/R/testing"), dep = TRUE)
}
