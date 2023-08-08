 function [mse_partial, r2_partial, cover_partial, me_partial, ...
    cp_95, cp_90, cp_85, cp_80, cp_75, cp_70, preds_partial, obs_partial] = predict(W,RP,sigW,wvar,Zs,Zt,piZ, ...
    target, total_train_obs, predict_goal, num_models, ...
    scale_space_w, scale_time_w, scale_space_rp, scale_time_rp, scale_space_wvar, time_metric, sample_n, ...
    outPath, outName)
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

%%%% ------------------------------ %%%%
%%%% 0: Set Up Objects for Test Run %%%%
%%%% ------------------------------ %%%%

 % window = 'annual'; num_models = 7; trainFold = 'all'; predFold = 'refGridConus'; 
 % len_scale_space = 3.5'; len_scale_time = 1; len_scale_space_rp = 3.5';
 % len_scale_time_rp = 1; penalty = 0.1; time_metric = 'annual'; seed = 1234;

 % num_models = 7; 
 % scale_space_w = 2'; scale_time_w = 1; scale_space_rp = 2';
 % scale_time_rp = 1; time_metric = 'year'; seed = 1234;
 

% target =testing;

%%%% ------------------------------- %%%%
%%%% 1: Prepare Data for Predictions %%%%
%%%% ------------------------------- %%%%

% 1a determine target time variable
[targetSpace, targetTime, targetPreds, targetObs, num_points] = extract_components(target, num_models, time_metric);

%%%% -------------------------------- %%%%
%%%% 2: Set Up Objects for Prediction %%%%
%%%% -------------------------------- %%%%

% 2a Create num_samp samples of W and w0 from a Gaussian distribution used
% for calculating empirical mean and standard deviations. More samples is
% slower but more accurate.
% Basically, we take samples of the parameter values 
num_rand_feat = sample_n;

% 2b muW is a vector of the mean values of the parameters of weights and
% offset term 
muW = [W(:) ; RP];

% 2c set the number of samples that we will take 
num_samp = 250;

% 2d take the samples. we generate random numbers based on gaussian
% distributions, where the means are the mean values and the variances are 
% stored in sigW, which we calculate in the second half of the BNE function
wsamp1 = mvnrnd(muW,sigW,num_samp)';

% 2e put samples in tidy format
rpsamp = [];
wsamp = [];
for s = 1:num_samp
    rpsamp = [rpsamp wsamp1(end-num_rand_feat+1:end,s)];
    wsamp = [wsamp reshape(wsamp1(1:num_models*num_rand_feat,s),num_rand_feat,num_models)];
end

% 2f create empty vectors to fill
softmax_mean = zeros(num_points,num_models);
softmax_sd = zeros(num_points,num_models);
contrib_sd = zeros(num_points,num_models);
ens_mean = zeros(num_points,1);
ens_sd = zeros(num_points,1);
rp_mean = zeros(num_points,1);
rp_sd = zeros(num_points,1);
y_mean = zeros(num_points,1);
y_sd = zeros(num_points,1);
unc_mon = zeros(num_points,1);
y_95CIl = zeros(num_points,1);
y_95CIu = zeros(num_points,1);
y_90CIl = zeros(num_points,1);
y_90CIu = zeros(num_points,1);
y_85CIl = zeros(num_points,1);
y_85CIu = zeros(num_points,1);
y_80CIl = zeros(num_points,1);
y_80CIu = zeros(num_points,1);
y_75CIl = zeros(num_points,1);
y_75CIu = zeros(num_points,1);
y_70CIl = zeros(num_points,1);
y_70CIu = zeros(num_points,1);
            
%%%% ----------------------- %%%%
%%%% 3: Generate Predictions %%%%
%%%% ----------------------- %%%%

% 3a begin loop over the individual points
for i = 1:num_points
    
    
    % 3b set up the way to translate time to the RFF
    if strcmp(time_metric, 'dayOfYear') 
        phi_w = sqrt(2/num_rand_feat)*cos(Zs*targetSpace(i,:)'/scale_space_w + ...
            Zt*58.0916*[cos(2*pi*targetTime(i,:))' ; sin(2*pi*targetTime(i,:))']/scale_time_w + piZ);
        phi_rp = sqrt(2/num_rand_feat)*cos(Zs*targetSpace(i,:)'/scale_space_rp + ...
            Zt*58.0916*[cos(2*pi*targetTime(i,:)) ; sin(2*pi*targetTime(i,:))]/scale_time_rp + piZ);
        phi_wvar = sqrt(2/num_rand_feat)*cos(Zs*targetSpace(i,:)'/scale_space_wvar + ...
            Zt*58.0916*[cos(2*pi*targetTime(i,:)) ; sin(2*pi*targetTime(i,:))]/scale_time_rp + piZ);
    else
        phi_w = sqrt(2/num_rand_feat)*cos(Zs*targetSpace(i,:)'/scale_space_w + ...
            Zt*targetTime(i,:)/scale_time_w + piZ);
        phi_rp = sqrt(2/num_rand_feat)*cos(Zs*targetSpace(i,:)'/scale_space_rp + ...
            Zt*targetTime(i,:)/scale_time_rp + piZ);
        phi_wvar = sqrt(2/num_rand_feat)*cos(Zs*targetSpace(i,:)'/scale_space_wvar + ...
            Zt*targetTime(i,:)/scale_time_rp + piZ);
    end
    
    % 3c sample the weights
    softmax = phi_w'*wsamp;
    softmax = reshape(softmax',num_models,num_samp)';
    softmax = exp(softmax);
    softmax = softmax./repmat(sum(softmax,2),1,num_models);
    contrib = softmax.*targetPreds(i,:);
    ens = softmax*targetPreds(i,:)';
    rp = phi_rp'*rpsamp;
    y = softmax*targetPreds(i,:)' + rp';
    noise = exp(.5*phi_wvar'*wvar); 
    % 3d fill in those empty arrays
    softmax_mean(i,:) = mean(softmax,1);
    softmax_sd(i,:) = std(softmax,1);
    contrib_sd(i,:) = std(contrib,1);
    ens_mean(i) = mean(ens);
    ens_sd(i) = std(ens);
    rp_mean(i) = mean(rp);
    rp_sd(i) = std(rp);
    y_mean(i) = mean(y);
    y_sd(i) = std(y);
    unc_mon(i) = noise;
    y_95CIl(i) = quantile(y, 0.025);
    y_95CIu(i) = quantile(y, 0.975);
    y_90CIl(i) = quantile(y, 0.05);
    y_90CIu(i) = quantile(y, 0.95);
    y_85CIl(i) = quantile(y, 0.075);
    y_85CIu(i) = quantile(y, 0.925);
    y_80CIl(i) = quantile(y, 0.10);
    y_80CIu(i) = quantile(y, 0.90);
    y_75CIl(i) = quantile(y, 0.125);
    y_75CIu(i) = quantile(y, 0.875);
    y_70CIl(i) = quantile(y, 0.15);
    y_70CIu(i) = quantile(y, 0.85);
    
    % 3e progress message
    if mod(i,1000) == 0
        display(['Point ' num2str(i) ' :::  ' num2str(num_points)]);
    end
            
% 3f finish loop
end

%%%% ---------------------- %%%%
%%%% 5: Compile PPD Summary %%%%
%%%% ---------------------- %%%%

% 5a nicely label the weight columns
if num_models == 7
        w_mean_av = softmax_mean(:,1);
        w_sd_av = softmax_sd(:,1);
        contrib_sd_av = contrib_sd(:,1);
        w_mean_cc = softmax_mean(:,2);
        w_sd_cc = softmax_sd(:,2);
        contrib_sd_cc = contrib_sd(:,2);
        w_mean_cm = softmax_mean(:,3);
        w_sd_cm = softmax_sd(:,3);
        contrib_sd_cm = contrib_sd(:,3);
        w_mean_gs = softmax_mean(:,4);
        w_sd_gs = softmax_sd(:,4);
        contrib_sd_gs = contrib_sd(:,4);
        w_mean_js = softmax_mean(:,5);
        w_sd_js = softmax_sd(:,5);
        contrib_sd_js = contrib_sd(:,5);
        w_mean_me = softmax_mean(:,6);
        w_sd_me = softmax_sd(:,6);
        contrib_sd_me = contrib_sd(:,6);
        w_mean_rk = softmax_mean(:,7);
        w_sd_rk = softmax_sd(:,7);
        contrib_sd_rk = contrib_sd(:,7);
        
        weights = table(w_mean_av, w_sd_av, w_mean_cc, w_sd_cc, w_mean_cm, w_sd_cm, ...
            w_mean_gs, w_sd_gs, w_mean_js, w_sd_js, w_mean_me, w_sd_me,...
            w_mean_rk, w_sd_rk, 'VariableNames', ...
            {'w_mean_av', 'w_sd_av', 'w_mean_cc', 'w_sd_cc',...
             'w_mean_cm', 'w_sd_cm', ...
             'w_mean_gs', 'w_sd_gs','w_mean_js', 'w_sd_js', ...
             'w_mean_me', 'w_sd_me', 'w_mean_rk', 'w_sd_rk'});
       contribs = table(contrib_sd_av, contrib_sd_cc, contrib_sd_cm, ...
            contrib_sd_gs, contrib_sd_js,  contrib_sd_me, contrib_sd_rk, ...
            'VariableNames', ...
            {'contrib_sd_av', 'contrib_sd_cc', 'contrib_sd_cm', ...
             'contrib_sd_gs','contrib_sd_js', 'contrib_sd_me', 'contrib_sd_rk'});
         
pred_av = targetPreds(:,1);
pred_cc = targetPreds(:,2);
pred_cm = targetPreds(:,3);
pred_gs = targetPreds(:,4);
pred_js = targetPreds(:,5);
pred_me = targetPreds(:,6);
pred_rk = targetPreds(:,7);

preds = table(pred_av, pred_cc, pred_cm, pred_gs, pred_js, pred_me, pred_rk, ...
    'VariableNames', ... 
    {'pred_av', 'pred_cc', 'pred_cm', 'pred_gs', 'pred_js', 'pred_me', 'pred_rk'});
end

% 5b combine other parameters
lat = targetSpace(:,1);
lon = targetSpace(:,2);
time = targetTime;

otherparam = table(lat, lon, time, ...
    ens_mean, ens_sd, rp_mean, rp_sd, y_mean, y_sd, unc_mon, ... 
    y_95CIl, y_95CIu, y_90CIl, y_90CIu,y_85CIl, y_85CIu,y_80CIl, y_80CIu,...
    y_75CIl, y_75CIu,y_70CIl, y_70CIu,...
    'VariableNames', ... 
    {'lat', 'lon', 'time',...
    'ens_mean', 'ens_sd', 'rp_mean',  'rp_sd', 'y_mean', 'y_sd', 'unc_mon', ...
    'y_95CIl', 'y_95CIu', 'y_90CIl', 'y_90CIu', 'y_85CIl', 'y_85CIu', 'y_80CIl', 'y_80CIu', ...
    'y_75CIl', 'y_75CIu', 'y_70CIl', 'y_70CIu'});
   
% 5c combine all parameters 
results = [otherparam weights contribs preds];

% 5d add observations if doing external validation
if strcmp(predict_goal, 'compare obs') | strcmp(predict_goal, 'cv')
    obs= targetObs;
   obstab = table(obs, 'VariableNames', {'obs'});
   results = [results obstab];
else 
   obs= transpose(repelem(0, size(results,1)));
   obstab = table(obs, 'VariableNames', {'obs'});
   results = [results obstab];
end

%%%% ----------------- %%%%
%%%% 6: Return Results %%%%
%%%% ----------------- %%%%

% compute the stuff
    error = results.obs - results.y_mean;
    mse_fold = mean(error.^2);
    corrmat = corrcoef(results.obs, results.y_mean);
    r2_fold = corrmat(2)^2;
    me_fold = mean(error);
    cover = results.obs >= results.y_95CIl & results.obs <= results.y_95CIu;
    cover_fold = mean(cover);
    cover_95 = results.obs >= results.y_95CIl & results.obs <= results.y_95CIu;
    cover_95_fold = mean(cover_95);
    cover_90 = results.obs >= results.y_90CIl & results.obs <= results.y_90CIu;
    cover_90_fold = mean(cover_90);
    cover_85 = results.obs >= results.y_85CIl & results.obs <= results.y_85CIu;
    cover_85_fold = mean(cover_85);
    cover_80 = results.obs >= results.y_80CIl & results.obs <= results.y_80CIu;
    cover_80_fold = mean(cover_80);
    cover_75 = results.obs >= results.y_75CIl & results.obs <= results.y_75CIu;
    cover_75_fold = mean(cover_75);
    cover_70 = results.obs >= results.y_70CIl & results.obs <= results.y_70CIu;
    cover_70_fold = mean(cover_70);
% 5e save as csv
% only if we are not doing cross-validation
if ~strcmp(predict_goal, 'cv')
   writetable(results, append(outPath, '/', outName,'.csv')) 
   mse_partial = mse_fold;
   r2_partial = r2_fold;
   cover_partial = cover_fold;
   me_partial = me_fold;
   cp_95 = cover_95_fold;
   cp_90 = cover_90_fold;
   cp_85 = cover_85_fold;
   cp_80 = cover_80_fold;
   cp_75 = cover_75_fold;
   cp_70 = cover_70_fold;
   preds_partial = results.y_mean; 
   obs_partial = results.obs;
       % 2d determine error 

    
elseif strcmp(predict_goal, 'cv')
    % 2d determine error 
   mse_partial = mse_fold* num_points / total_train_obs;
   r2_partial = r2_fold* num_points / total_train_obs;
   cover_partial = cover_fold* num_points / total_train_obs;
   me_partial = me_fold* num_points / total_train_obs;
   cp_95 = cover_95_fold* num_points / total_train_obs;
   cp_90 = cover_90_fold* num_points / total_train_obs;
   cp_85 = cover_85_fold* num_points / total_train_obs;
   cp_80 = cover_80_fold* num_points / total_train_obs;
   cp_75 = cover_75_fold* num_points / total_train_obs;
   cp_70 = cover_70_fold* num_points / total_train_obs;
   preds_partial = results.y_mean; 
   obs_partial = results.obs; 
end

 % end function
end
