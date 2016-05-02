function [args_path] = args_test4()
%ARGS_TEST4 Ga-Re, Two goal, 200 Population
%   ARGS_PATH = ARGS_TEST4() Returns in ARGS_PATH the file path of a .mat
%   file with arguments defined here. Main args are:
%   solver = 'ga-re'
%   use_approx_fitness = false;
%   dist_foo = @histogram_sum_abs;
%   error_foo = {@histogramDErrorOpti};
%   PopulationSize = 4;
%   CreationFcn = @gacreationheuristic1;
%
%   See also heatMapReconstruction, args_test_template,
%   args_test_solver_template

%% Change common parameters
args_path = [mfilename('fullpath') '.mat'];
args_test_template(args_path);

L = load(args_path);

solver = 'ga-re';

% Geat goal image path with convenience function
multi_goal = true; % Single or two goal image optimization
symmetric = true; % Symmetric or asymmetric goal image
[project_path, raw_file_path, scene_img_folder, goal_img_path, ...
    goal_mask_img_path, mask_img_path] = get_test_paths(L.scene_name, ...
    multi_goal, symmetric);

% Save all but L
save(args_path, '-regexp','^(?!(L)$).', '-append');

solver_path = [mfilename('fullpath') 'solver.mat'];

%% Change solver parameters
clearvars -except solver_path solver args_path

args_test_solver_template(solver_path, solver);

L = load(solver_path);

options = L.options;

minimumVolumeSize = 2;
populationInitSize = 4;
populationScale = 1;
time_limit = 30; % In seconds
options.TimeLimit = time_limit;

% Save all but L, solver and solver_path
save(solver_path, '-regexp','^(?!(L|solver|solver_path|args_path)$).', '-append');

end
