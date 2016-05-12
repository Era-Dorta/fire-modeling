function args_test_template(args_path)
%ARGS_TEST_TEMPLATE Arguments for heatMapReconstruction
%   ARGS_TEST_TEMPLATE(ARGS_PATH) Saves in ARGS_PATH the file path of a
%   .mat file with arguments defined here. Main args are:
%   solver = 'ga'
%   use_approx_fitness = false;
%   dist_foo = @histogram_l1_norm;
%   error_foo = {@histogramDErrorOpti};
%   PopulationSize = 200;
%   CreationFcn = @gacreationheuristic1;
%
%   See also heatMapReconstruction

%% Common arguments
%   Solver should be one of the following
%   'ga' -> Genetic Algorithm
%   'sa' -> Simulated Annealing
%   'ga-re' -> Genetic Algorithm with heat map resampling
%   'grad' -> Gradient Descent
solver = 'ga';

% BlackBody, Propane, Acetylene, Methane, BlueSyn, Cu, S, Li, Ba, Na, Co, Sc, C, H, C3H8
%      0        1       2           3      4        5  6   7   8   9   10 11 12  13 14
fuel_type = 0;

scene_name = 'test95_gaussian_new';

% Geat goal image path with convenience function
multi_goal = false; % Single or two goal image optimization
symmetric = true; % Symmetric or asymmetric goal image
[project_path, raw_file_path, scene_img_folder, goal_img_path, ...
    goal_mask_img_path, mask_img_path] = get_test_paths(scene_name, ...
    multi_goal, symmetric);

% Threshold for edge detection, by default ignore any pixel that is less 
% than 10% foreground
bin_mask_threshold = zeros(numel(goal_img_path), 1) + 1e-1;

rand_seed = 'default';

% epsilon = 100; % Error tolerance, using Matlab default's at the moment
LB = 300; % Lower bounds, no less than 300K -> 27C
UB = 2000; % Upper bounds, no more than 2000K -> 1727C
use_approx_fitness = false; % Using the approximate fitness function?

% Distance function for the histogram error functions, any of the ones in
% the folder error_fnc/distance_fnc
% Common ones: histogram_l1_norm, histogram_intersection,
% chi_square_statistics_fast, jensen_shannon_divergence
dist_foo = @histogram_l1_norm;

% Error function used in the fitness function
% One of: histogramErrorOpti, histogramDErrorOpti, MSE
error_foo = {@histogramDErrorOpti};

% If use_approx_fitness is true, this function will be used in the fitness
% function, the one above one will used only to check the final result
approx_error_foo = @histogramErrorApprox;

% Prior functions that are added to the error function in the fitness
% function, any of smoothnessEstimate, smoothnessEstimateGrad, 
% upHeatEstimate, upHeatEstimateLinear, histogramErrorApprox
prior_fncs = {@smoothnessEstimateGrad, @upHeatEstimateLinear};

% Temperature threshold for the upHeatEstimateLinear
temp_th = 50; 

% Weights used to sum the error function and the prior functions, must be
% of size prior_fncs + 1, first corresponds to error function
prior_weights = [1/3, 1/3, 1/3];

% Path were the solver especific variables will be saved
[pathstr,name,ext] = fileparts(args_path);
solver_args_path = fullfile(pathstr, [name 'solver' ext]);

clearvars('pathstr', 'name', 'ext', 'multi_goal', 'symmetric');

% Save all the variables in a mat file
save(args_path);

%% Solver specific arguments
args_test_solver_template(solver_args_path, solver);

end
