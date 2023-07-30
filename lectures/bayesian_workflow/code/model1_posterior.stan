data {
  int<lower=0> N;
  vector[N] y;
  vector[N] x;
  real<lower=0> sigma;
}
parameters {
  real a;
  real b;
}
model {
  a ~ normal(0, 1);
  b ~ normal(0, 1);
  y ~ normal(a + b*x, sigma);
}
generated quantities {
  vector[N] y_sim;
  for(i in 1:N) {
    y_sim[i] = normal_rng(a+b*x[i],sigma);
 }
}
