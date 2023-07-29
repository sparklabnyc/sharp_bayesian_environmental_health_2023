data {
  int<lower=0> N;
  vector[N] y;
  vector[N] x;
  real<lower=0> sigma;
}
generated quantities {
  vector[N] y_sim;
  real a = normal_rng(0,1);
  real b = normal_rng(0.5,0.5);
  for(i in 1:N) {
    y_sim[i] = normal_rng(a+b*x[i],sigma);
 }
}
