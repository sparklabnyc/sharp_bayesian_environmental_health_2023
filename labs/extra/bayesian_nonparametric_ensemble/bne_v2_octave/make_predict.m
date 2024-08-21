scale_space_w = 2;
scale_time_w = 0.5;
scale_space_rp = 2;
scale_time_rp = 0.5;
scale_space_wvar = 2;
lambda_w = 0.0498;
lambda_rp = 0.1353;
num_models = 7;
opt_stage = 1;
seed = 1234;
bne_mode = 'cv';
sample_n = 1000;

% 1.c. set time metric
time_metric = 'year';

training = dataframe('data/training_cvfolds_south_west.csv');

num_models = 7;


% 1.e. extract components
[trainSpace, trainTime, trainPreds, trainAqs, ~] =  ...
    extract_components(training, num_models, time_metric);

% 1.f. set parameter values we will consider
yyyy_list = [2010, 2011, 2012, 2013, 2014, 2015];

%%%% -------------------------------------------- %%%%
%%%% 2: Generate PPD's; loop over years %%%%
%%%% --------------------------------------------- %%%%

    % 2.a. generate model

    [W,RP,wvar,sigW,Zs,Zt,piZ,mse] = train(trainAqs, trainSpace, trainTime, trainPreds, ...
    scale_space_w, scale_time_w, scale_space_rp, scale_time_rp, scale_space_wvar, ...
    lambda_w, lambda_rp, time_metric, opt_stage, seed, 'cv', sample_n);

         % 2.b.generating results for year 2011 as example
        yyyy = 2011;

        % 2.c bring in the data frame of gridded predictions
        target = dataframe(strcat(src_path, 'data/preds_annual_', ...
            num2str(yyyy), '_south_west.csv'));

        % 2.c. generate and write ppd summary
        predict(W,RP,sigW,wvar,Zs,Zt,piZ, ...
          target, 10, 'summarize ppd', num_models, ...
          scale_space_w, scale_time_w, scale_space_rp, scale_time_rp, scale_space_wvar, time_metric, sample_n);
