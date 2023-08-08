library(rstan)
library(ggplot2)

### generate data ###
set.seed(12345)

N <- 100
x <- 1:N
sigma <- 10.0
a <- 0.5
b <- 0.2
y <- rnorm(N, a * x + b, sigma)
# hist(y)

df <- data.frame(x, y)
(p <- ggplot(df, aes(x, y)) +
  geom_point(col = "red", shape = 19, size = 3) +
  theme_minimal())
ggsave(p, filename = "../assets/data1.png", width = 6.5, h = 5)

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
n_sims <- dim(y_sim)[1]
str(y_sim)

lower <- apply(y_sim, 2, function(x) quantile(x, 0.025))
df_lower <- data.frame(x, y = lower)
df_lower["type"] <- "lower"
upper <- apply(y_sim, 2, function(x) quantile(x, 1 - 0.025))
df_upper <- data.frame(x, y = upper)
df_upper["type"] <- "upper"


df <- data.frame(x, y, y_sim = y_sim[n_sims, ], lower, upper)
head(df)
(p <- ggplot(df) +
  geom_point(aes(x, y), shape = 19, size = 3, col = "red") +
  geom_point(aes(x, y_sim), shape = 19, size = 3, col = "dodgerblue") +
  geom_ribbon(aes(x, ymin = lower, ymax = upper), fill = "dodgerblue", alpha = 0.2) +
  theme_minimal()
)
ggsave(p, filename = "../assets/data2.png", width = 6.5, h = 5)

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
n_sims <- dim(y_sim)[1]
str(y_sim)

lower <- apply(y_sim, 2, function(x) quantile(x, 0.025))
df_lower <- data.frame(x, y = lower)
df_lower["type"] <- "lower"
upper <- apply(y_sim, 2, function(x) quantile(x, 1 - 0.025))
df_upper <- data.frame(x, y = upper)
df_upper["type"] <- "upper"

df <- data.frame(x, y, y_sim = y_sim[n_sims, ], lower, upper)
head(df)
(p <- ggplot(df) +
  geom_point(aes(x, y), shape = 19, size = 3, col = "red") +
  geom_point(aes(x, y_sim), shape = 19, size = 3, col = "dodgerblue") +
  geom_ribbon(aes(x, ymin = lower, ymax = upper), fill = "dodgerblue", alpha = 0.2) +
  theme_minimal()
)
ggsave(p, filename = "../assets/data3.png", width = 6.5, h = 5)


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
n_sims <- dim(y_sim)[1]
str(y_sim)

lower <- apply(y_sim, 2, function(x) quantile(x, 0.025))
df_lower <- data.frame(x, y = lower)
df_lower["type"] <- "lower"
upper <- apply(y_sim, 2, function(x) quantile(x, 1 - 0.025))
df_upper <- data.frame(x, y = upper)
df_upper["type"] <- "upper"

df <- data.frame(x, y, y_sim = y_sim[n_sims, ], lower, upper)
head(df)
(p <- ggplot(df) +
  geom_point(aes(x, y), shape = 19, size = 3, col = "red") +
  geom_point(aes(x, y_sim), shape = 19, size = 3, col = "dodgerblue") +
  geom_ribbon(aes(x, ymin = lower, ymax = upper), fill = "dodgerblue", alpha = 0.2) +
  theme_minimal()
)
ggsave(p, filename = "../assets/posterior1.png", width = 6.5, h = 5)
