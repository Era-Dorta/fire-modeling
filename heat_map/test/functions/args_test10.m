function [args_path] = args_test10()
%ARGS_TEST10 Pegoraro Image1, single goal
%   ARGS_PATH = ARGS_TEST10() Returns in ARGS_PATH the file path of a .mat
%   file with arguments defined here.
%
%   See also heatMapReconstruction, args_test_template,
%   args_test_solver_template

data_dir = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'data');
args_path = fullfile(data_dir, [mfilename('clas') '.mat']);
args_test_template(args_path);

L = load(args_path);

% Geat goal image path with convenience function
multi_goal = false; % Single or two goal image optimization
symmetric = true; % Symmetric or asymmetric goal image
[project_path, raw_file_path, scene_img_folder, goal_img_path, ...
    goal_mask_img_path, mask_img_path] = get_test_paths(L.scene_name, ...
    multi_goal, symmetric);

goal_img_path = {'~/maya/projects/fire/data/fire-test-pics/pegoraro1.png'};
goal_mask_img_path = {'~/maya/projects/fire/data/fire-test-pics/trimap/pegoraro1-mask.png'};

clearvars('L', 'multi_goal', 'symmetric', 'data_dir');

% Update the variables that do not match the template
save(args_path, '*', '-append');

end
