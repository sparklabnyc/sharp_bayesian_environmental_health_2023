setwd("~/Dropbox/00 Oxford/70_Robbie_workshop_SHARP/GitHub_Liza/sharp_bayesian_environmental_health_2023/lectures/bayesian_workflow/code")

library(rstan)

### generate data ###
set.seed(12345)

N <- 100
x <- 1:N
sigma <- 10.0
a <- 0.5
b <- 0.2
y <- rnorm(N, a * x + b, sigma)
# hist(y)
plot(x, y, pch = 19, col = "red")


# assume we know sigma
data <- list(N = N, x = x, y = y, sigma = sigma)


# prior predictive
fit <- stan(
  file = "model1_prior.stan", # Stan program
  data = data, # named list of data
  chains = 4, # number of Markov chains
  warmup = 1000, # number of warmup iterations per chain
  iter = 2000, # total number of iterations per chain
  cores = 1, # number of cores (could use one per chain)
  algorithm = "Fixed_param"
  # refresh = 0             # no progress shown
)

y_sim <- extract(fit, pars = "y_sim")$y_sim
str(y_sim)
plot(x, y, pch = 19, col = "red")
for (i in 1:3) {
  points(x, y_sim[i, ], pch = 19, col = "dodgerblue")
}


# prior predictive
fit <- stan(
  file = "model1_prior_v2.stan", # Stan program
  data = data, # named list of data
  chains = 4, # number of Markov chains
  warmup = 1000, # number of warmup iterations per chain
  iter = 2000, # total number of iterations per chain
  cores = 1, # number of cores (could use one per chain)
  algorithm = "Fixed_param"
  # refresh = 0             # no progress shown
)

y_sim <- extract(fit, pars = "y_sim")$y_sim
str(y_sim)
plot(x, y, pch = 19, col = "red")
for (i in 1:5) {
  points(x, y_sim[i, ], pch = 19, col = "dodgerblue")
}


# fit the model
fit <- stan(
  file = "model1.stan", # Stan program
  data = data, # named list of data
  chains = 4, # number of Markov chains
  warmup = 1000, # number of warmup iterations per chain
  iter = 2000, # total number of iterations per chain
  cores = 1, # number of cores (could use one per chain)
  # refresh = 0             # no progress shown
)


print(fit, pars = c("a", "b"), probs = c(.1, .5, .9))

plot(fit)

traceplot(fit, pars = c("a", "b"), inc_warmup = TRUE, nrow = 2)

# posterior predictive
fit <- stan(
  file = "model1_posterior.stan", # Stan program
  data = data, # named list of data
  chains = 4, # number of Markov chains
  warmup = 1000, # number of warmup iterations per chain
  iter = 2000, # total number of iterations per chain
  cores = 1, # number of cores (could use one per chain)
  # refresh = 0             # no progress shown
)

y_sim <- extract(fit, pars = "y_sim")$y_sim
str(y_sim)
plot(x, y, pch = 19, col = "red")
for (i in 1:3) {
  points(x, y_sim[i, ], pch = 19, col = "dodgerblue")
}
