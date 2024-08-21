scale_space_w = 2;
scale_time_w = 0.5;
scale_space_rp = 2;
scale_time_rp = 0.5;
scale_space_wvar = 2;
lambda_w = 0.0498;
lambda_rp = 0.1353;
num_models = 7;
time_var = 'year'
opt_stage = 1;
seed = 1234;
bne_mode = 'cv';
sample_n = 1000;

training_full = dataframe('data/training_cvfolds_south_west.csv');

[rmse, r2, coverage, me, slope] = make_cv(training_full, num_models, ...
        scale_space_w, scale_time_w, scale_space_rp, scale_time_rp, scale_space_wvar, ...
        lambda_w, lambda_rp, time_var, opt_stage, seed, sample_n);
fprintf('cross-validated results: %d is RMSE, %d is R2.\n',rmse,r2);
