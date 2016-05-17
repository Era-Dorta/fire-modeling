function [args_path] = args_test4()
%ARGS_TEST4 Ga-Re, Two goal, 30 seconds
%   ARGS_PATH = ARGS_TEST4() Returns in ARGS_PATH the file path of a .mat
%   file with arguments defined here.
%
%   See also heatMapReconstruction, args_test_template,
%   args_test_solver_template

%% Change common parameters
data_dir = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'data');
args_path = fullfile(data_dir, [mfilename('clas') '.mat']);
args_test_template(args_path, false);

L = load(args_path);

solver = 'ga-re';

% Geat goal image path with convenience function
multi_goal = true; % Single or two goal image optimization
symmetric = true; % Symmetric or asymmetric goal image
[project_path, raw_file_path, scene_img_folder, goal_img_path, ...
    goal_mask_img_path, mask_img_path] = get_test_paths(L.scene_name, ...
    multi_goal, symmetric);

% Save all but L
save(args_path, '-regexp','^(?!(L|multi_goal|symmetric|data_dir)$).', '-append');

%% Change solver parameters
clearvars -except solver args_path

args_test_solver_template(args_path, solver);

L = load(args_path);

options = L.options;

minimumVolumeSize = 2;
populationInitSize = 4;
populationScale = 1;
time_limit = 30; % In seconds
options.TimeLimit = time_limit;

% Save all but L, solver and 
save(args_path, '-regexp','^(?!(L|solver|args_path)$).', '-append');

end
