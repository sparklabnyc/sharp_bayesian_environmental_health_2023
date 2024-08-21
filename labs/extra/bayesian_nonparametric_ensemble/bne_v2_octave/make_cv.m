function [rmse, r2, coverage, me, slope, slope_95CIl, slope_95CIu] = make_cv(training_full, num_models, ...
        scale_space_w, scale_time_w, scale_space_rp, scale_time_rp, scale_space_wvar, ...
        lambda_w, lambda_rp, time_metric, opt_stage, seed, sample_n)

    % parameter values

    %num_models = 6;
    %scale_space_w = 2; scale_time_w=0.5; scale_space_rp=2; scale_time_rp=0.5;
     %lambda_w=0.0498;  lambda_rp=0.1353; time_metric='year'; opt_stage= 2;
     %seed=1234;
%%%% ------------------------ %%%%
%%%%  1: Set fold fold table  %%%%
%%%% ------------------------ %%%%

fold = transpose([1:10]);
mse = repelem(0, 10);
r2 = repelem(0, 10);
cover = repelem(0, 10);

fold_table = dataframe();
fold_table.fold = fold;
fold_table.mse = mse;
fold_table.r2 = r2;
fold_table.cover = cover;

[num_obs,num_cols] = size(training_full);
preds = transpose(repelem(0, 1));
obs = transpose(repelem(0, 1));

%%%% ------------------------ %%%%
%%%%  1: Calcualte Metrics in each fold  %%%%
%%%% ------------------------ %%%%

for i = 1:10

    [partial_mse partial_r2 partial_cover, partial_me, partial_preds, partial_obs] = cv(training_full,...
        fold_table.fold(i),...
        num_models, ...
        scale_space_w, scale_time_w, scale_space_rp, scale_time_rp, scale_space_wvar, ...
        lambda_w, lambda_rp, time_metric, opt_stage, seed, sample_n);

    fold_table.mse(i) = partial_mse ;
    fold_table.r2(i) = partial_r2 ;
    fold_table.cover(i) = partial_cover ;
    fold_table.me(i) = partial_me ;
    preds = transpose(partial_preds);
    obs = transpose(partial_obs);

end

%%%% ------------------------ %%%%
%%%%  1: aggregate  %%%%
%%%% ------------------------ %%%%
   rmse = sqrt(sum(fold_table.mse));
   r2 = sum(fold_table.r2);
   coverage = sum(fold_table.cover);
   me = sum(fold_table.me);
   slope = preds\obs;

  % mdl = LinearRegression(preds,obs) % todo: add this linear regression
  % coef = table2array(mdl.Coefficients);
   %slope_95CIl = coef(2,1) - 1.96*coef(2,2)
   %slope_95CIu = coef(2,1) + 1.96*coef(2,2)

end
