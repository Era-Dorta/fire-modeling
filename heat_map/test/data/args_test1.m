function [args_path] = args_test1()
%ARGS_TEST1 Two goal
%   ARGS_PATH = ARGS_TEST1() Returns in ARGS_PATH the file path of a .mat
%   file with arguments defined here. Main args are:
%
%   See also heatMapReconstruction, args_test_template,
%   args_test_solver_template

args_path = [mfilename('fullpath') '.mat'];
args_test_template(args_path);

L = load(args_path);

% Geat goal image path with convenience function
multi_goal = true; % Single or two goal image optimization
symmetric = true; % Symmetric or asymmetric goal image
[project_path, raw_file_path, scene_img_folder, goal_img_path, ...
    goal_mask_img_path, mask_img_path] = get_test_paths(L.scene_name, ...
    multi_goal, symmetric);

clearvars('L', 'multi_goal', 'symmetric');

% Update the variables that do not match the template
save(args_path, '*', '-append');

end
