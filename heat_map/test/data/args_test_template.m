function args_test_template(args_path)
%ARGS_TEST_TEMPLATE Arguments for heatMapReconstruction
%   ARGS_TEST_TEMPLATE(ARGS_PATH) Saves in ARGS_PATH the file path of a
%   .mat file with arguments defined here. Main args are:
%   solver = 'ga'
%   use_approx_fitness = false;
%   dist_foo = @histogram_sum_abs;
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

scene_name = 'test95_gaussian_new';

% Geat goal image path with convenience function
multi_goal = false; % Single or two goal image optimization
symmetric = false; % Symmetric or asymmetric goal image
[project_path, raw_file_path, scene_img_folder, goal_img_path, ...
    goal_mask_img_path, mask_img_path] = get_test_paths(scene_name, ...
    multi_goal, symmetric);

rand_seed = 'default';

% epsilon = 100; % Error tolerance, using Matlab default's at the moment
LB = 300; % Lower bounds, no less than 300K -> 27C
UB = 2000; % Upper bounds, no more than 2000K -> 1727C
use_approx_fitness = false; % Using the approximate fitness function?

% Distance function for the histogram error functions, any of the ones in
% the folder error_fnc/distance_fnc
% Common ones: histogram_sum_abs, histogram_intersection,
% chi_square_statistics_fast
dist_foo = @histogram_sum_abs;

% Error function used in the fitness function
% One of: histogramErrorOpti, histogramDErrorOpti, MSE
error_foo = {@histogramDErrorOpti};

% If use_approx_fitness is true, this function will be used in the fitness
% function, the one above one will used only to check the final result
approx_error_foo = @histogramErrorApprox;

% Path were the solver especific variables will be saved
[pathstr,name,ext] = fileparts(args_path);
solver_args_path = fullfile(pathstr, [name 'solver' ext]);

clearvars('pathstr', 'name', 'ext');

% Save all the variables in a mat file
save(args_path);

%% Solver specific arguments
args_test_solver_template(solver_args_path, solver);

end
