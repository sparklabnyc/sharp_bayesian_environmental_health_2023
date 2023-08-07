%%%% ---------------------- %%%%
%%%% 1: Optimize Parameters %%%%
%%%% ---------------------- %%%%

%addpath("scripts/f_run_BNE/bne_v1/")

% 1 make grid search table
% 1a set parameter values we will consider
scale_space_w_list = [2, 1, 0.5];
scale_time_w_list = [2, 1, 0.5];
scale_space_rp_list = [2, 1, 0.5];
scale_time_rp_list = [2,1,0.5];
scale_space_wvar_list = [2,1,0.5];
lambda_list = [0.3679, 0.1353, 0.0498, 0.0183];
lambda_rp_list = [0.3679, 0.1353, 0.0498, 0.0183];
opt_stage_list = [1];
seed_list = [1234];
n_sample_list = [1000,2000];


% 1b actually make the table
% 1b.i get all the combinations
grid_mat = combvec(scale_space_w_list, scale_time_w_list, ...
    scale_space_rp_list, scale_time_rp_list, scale_space_wvar_list, lambda_list, lambda_rp_list, ...
     opt_stage_list, seed_list, n_sample_list).';
% 1b.ii put them in a nice labeled table
grid = table;
grid.scale_space_w = grid_mat(:,1);
grid.scale_time_w = grid_mat(:,2);
grid.scale_space_rp = grid_mat(:,3);
grid.scale_time_rp = grid_mat(:,4);
grid.scale_space_wvar = grid_mat(:,5);
grid.lambda_w = grid_mat(:,6);
grid.lambda_rp = grid_mat(:,7);
grid.opt_stage = grid_mat(:,8);
grid.seed = grid_mat(:,9);
grid.sample_n = grid_mat(:,10);
grid.rmse = transpose(repelem(0, size(grid,1)));
grid.r2 = transpose(repelem(0, size(grid,1)));
grid.cover = transpose(repelem(0, size(grid,1)));
grid.mse = transpose(repelem(0, size(grid,1)));

% bring in the training dataset
training_full = readtable('/data0/shr/bne/pm_data_jaime/pm_data_jaime/inputs/pm25/training_datasets/annual_combined/training_cvfolds_rev01_north_east_us.csv');

num_models = 7;


%%%% ---------------------- %%%%
%%%% 2: Optimize Parameters %%%%
%%%% ---------------------- %%%%

for i = 1:1:size(grid,1)
    time_metric = 'year';

    [rmse, r2, cover, mse] = make_cv(training_full, num_models, ...
        grid.scale_space_w(i), grid.scale_time_w(i),  ...
        grid.scale_space_rp(i), grid.scale_time_rp(i), grid.scale_space_wvar(i), ...
        grid.lambda_w(i), grid.lambda_rp(i), time_metric, ...
        grid.opt_stage(i), grid.seed(i), grid.sample_n(i));
    grid.rmse(i) = rmse; 
    grid.r2(i) = r2; 
    grid.cover(i) = cover; 
    grid.mse(i) = mse; 

        display(num2str(i))
        % update results table
    writetable(grid, 'annual_grid_search_PM25_2010_2015_test')
end
