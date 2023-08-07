

%%%% ---------------------- %%%%
%%%% 1: Set up for Loop  %%%%
%%%% ---------------------- %%%%

% 1.a make table of hyperparameter combinations
% 1a set parameter values we will consider
% 
scale_space_w_list = [2];
scale_time_w_list = [0.5];
scale_space_rp_list = [2];
scale_time_rp_list = [0.5];
scale_space_wvar_list = scale_space_rp_list;
lambda_w_list = [0.0498];
lambda_rp_list = [0.1353];
time_metric_list = [1]; %['julianDay', 'dayOfYear'];
seed_list = [1234];
opt_stage_list = [1];
sample_n = 500;


% 1.b. actually make the table
% 1b.i get all the combinations
grid_mat = combvec(scale_space_w_list, scale_time_w_list, ...
    scale_space_rp_list, scale_time_rp_list, scale_space_wvar_list, lambda_w_list, lambda_rp_list,...
   time_metric_list, seed_list, opt_stage_list).';
% 1b.ii put them in a nice labeled table
grid = table;
grid.scale_space_w = grid_mat(:,1);
grid.scale_time_w = grid_mat(:,2);
grid.scale_space_rp = grid_mat(:,3);
grid.scale_time_rp = grid_mat(:,4);
grid.scale_space_wvar = grid_mat(:,5);
grid.lambda_w = grid_mat(:,6);
grid.lambda_rp =grid_mat(:,7);
grid.time_metric = grid_mat(:,8);
grid.seed = grid_mat(:,9);
grid.opt_stage = grid_mat(:,10);

% set time metric
time_metric = 'year';
    
training = readtable('./data/training_cvfolds_south_west.csv');

num_models = 7;


% Extract components
[trainSpace, trainTime, trainPreds, trainAqs, num_points] =  ...
    extract_components(training, num_models, time_metric);

%%%% -------------------------------------------- %%%%
%%%% 2: Generate PPD's; loop over models and years %%%%
%%%% --------------------------------------------- %%%%

for i = 1:size(grid,1)
    
    % 2.a. generate model
    [W,RP,wvar,sigW,Zs,Zt,piZ,mse] = train(trainAqs, trainSpace, trainTime, trainPreds, ...
    grid.scale_space_w(i), grid.scale_time_w(i), grid.scale_space_rp(i), grid.scale_time_rp(i), grid.scale_space_wvar(i), ...
    grid.lambda_w(i), grid.lambda_rp(i), time_metric, grid.opt_stage(i), grid.seed(i), 'cv', sample_n);
        
         % 2.b.loop to generate ppd for each year
    yyyy = 2011;
        
        % 2.c bring in the data frame of gridded predictions
        target = readtable(append('./data/preds_annual_', ...
            num2str(yyyy), '_south_west.csv'));
        
        % 2.c. generate and write ppd summary
        predict(W,RP,sigW,wvar,Zs,Zt,piZ, ...
            target, 10, 'summarize ppd', num_models, ...
            grid.scale_space_w(i), grid.scale_time_w(i), grid.scale_space_rp(i), ...
            grid.scale_time_rp(i), grid.scale_space_wvar(i), time_metric, sample_n, ...
            './outputs', ....
            append('refGrid_pm25_test_', num2str(yyyy), '_', ...
                strrep(num2str(grid.scale_space_w(i)), '.', '-'), '_', ...
                strrep(num2str(grid.scale_time_w(i)), '.', '-'), '_', ...
                strrep(num2str(grid.scale_space_rp(i)), '.', '-'), '_', ...
                strrep(num2str(grid.scale_time_rp(i)), '.', '-'), '_', ...
                strrep(num2str(grid.scale_space_wvar(i)), '.', '-'), '_', ...
                strrep(num2str(grid.lambda_w(i)), '.', '-'), '_', ...
                strrep(num2str(grid.lambda_rp(i)), '.', '-')))


    
end


