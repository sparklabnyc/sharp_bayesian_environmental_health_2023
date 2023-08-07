function [partial_mse, partial_r2, partial_cover, partial_me, partial_preds, partial_obs, ...
    pc_95, pc_90, pc_85, pc_80, pc_75, pc_70] = cv(training_full, fold,... 
    num_models, ...
    scale_space_w, scale_time_w, scale_space_rp, scale_time_rp, scale_space_wvar, ...
    lambda_w, lambda_rp, time_metric, opt_stage, seed, sample_n)
% % 
% % === Inputs ===
% %  
% %     window: (string) whether annual or daily 
% %     num_mods: number of base models included 
% %     trainfold: (string) describes the locations used for training 
% %     predFold: (string) describes the locations/times we will predict 
% %     
% %     len_scale : (scalar) RBF kernel parameter (we've been using 3.5, but not optimized)
% %     penalty: (numeric) strength of the prior ; lambda
% %     bool_periodic: (string) whether julian day or day of year; only for daily data 
% %     seed: (numeric) the seed 
% % 
% %  === Outputs ===
% % 
% %     a written matrix of the mean values of the model parameters and
% %     their standard deviation. For predicted concentration, additional values
% %     like the 2.5th and 97.5th percentiles are reported. 

%%%% -------------------------------- %%%%
%%%%  0: Set Up Objects for Test Run  %%%%
%%%% -------------------------------- %%%% 


%%%% ----------------------------------------- %%%%
%%%%  1: Split Data into Training and Testing  %%%%
%%%% ----------------------------------------- %%%%

training = training_full(training_full.fold ~=fold,:);
testing = training_full(training_full.fold ==fold,:);

%%%% ------------------------------------- %%%%
%%%%  2: Train BNE on Left-In Observations %%%%
%%%% ------------------------------------- %%%%

% 2.a. extract components
[trainSpace, trainTime, trainPreds, trainAqs, ~] =  ...
    extract_components(training, num_models, time_metric);

% 2.b. train BNE
[W,RP,wvar,sigW,Zs,Zt,piZ,mse] = train(trainAqs, trainSpace, trainTime, trainPreds, ...
    scale_space_w, scale_time_w, scale_space_rp, scale_time_rp, scale_space_wvar, ...
    lambda_w, lambda_rp, time_metric, opt_stage, seed, 'cv', sample_n);


%%%% ----------------------------------------- %%%%
%%%%  3: Evalute BNE on Left-Out Observations  %%%% predict_BNE_v1 works
%%%%  for pm2.5 and predict_BNE_v2 works for NO2-2019
%%%% ----------------------------------------- %%%%

 [partial_mse, partial_r2, partial_cover,  partial_me, ...
     pc_95, pc_90, pc_85, pc_80, pc_75, pc_70, partial_preds, partial_obs] = predict(W,RP,sigW,wvar,Zs,Zt,piZ, ...
    testing, size(training_full,1), 'cv', num_models, ...
    scale_space_w, scale_time_w, scale_space_rp, scale_time_rp, scale_space_wvar, time_metric, sample_n, ...
    'nosave', 'nosave');


end
