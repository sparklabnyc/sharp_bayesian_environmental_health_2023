function [space, time, preds, obs, num_points] = extract_components(dataset, num_models, time_metric)
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
 % len_scale_space = 3.5'; len_scale_time = 1; len_scale_space_bias = 3.5';
 % len_scale_time_bias = 1; penalty = 0.1; time_metric = 'annual'; seed = 1234;

 % window = 'daily'; num_models = 5; fold=1;
 % len_scale_space = 3.5'; len_scale_time = 20; len_scale_space_bias = 3.5';
 % len_scale_time_bias = 20; penalty = 0.1; time_metric = 'julianDay'; seed = 1234;
 % yyyy_start = 2005; yyyy_end=2015; dir_out = 'test_run';

 %  time_metric = 'dayOfYear';

%%%% -------------------------- %%%%
%%%%  1: Process Training Data  %%%%
%%%% -------------------------- %%%%

% 1.a. determine number of points
num_points = size(dataset,1);

% 1.a. extract spatial location
space = dataset(:,1:2);

% 1.b. extract the right time variable
if strcmp(time_metric, 'percentOfYear')
    time = dataset.percent_of_year;

    if any(strcmp('julian_day', dataset.colnames))
        dataset.julian_day = [];
    end
    if any(strcmp('yyyy', dataset.colnames))
        dataset.yyyy = [];
    end

elseif strcmp(time_metric, 'julianDay')
    time = dataset.julian_day;

    if any(strcmp('percent_of_year', dataset.colnames))
        dataset.percent_of_year = [];
    end
    if any(strcmp('yyyy', dataset.colnames))
        dataset.yyyy = [];
    end

elseif strcmp(time_metric, 'year')
    time = dataset.yyyy;

    if any(strcmp('julian_day', dataset.colnames))
        dataset.julian_day = [];
    end
    if any(strcmp('percent_of_year', dataset.colnames))
        dataset.percent_of_year = [];
    end

end

% 1.c. extract the observations
if strcmp(dataset.colnames(4),'obs')
   preds = dataset(:,5:(4+num_models));
else
    preds = dataset(:,4:(3+num_models));
end

% 1.c. extract the predictions
%if any(strcmp('obs', dataset.colnames))
    obs = dataset(:,4);
%else
%    obs = transpose(repelem(0, num_points));
%end
obs = obs.array;
space = space.array;
preds = preds.array;
end
