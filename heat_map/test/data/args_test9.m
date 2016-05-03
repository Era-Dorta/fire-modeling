function [args_path] = args_test9()
%ARGS_TEST9 Ga, Pegoraro Image1, single goal, 200 Population
%   ARGS_PATH = ARGS_TEST9() Returns in ARGS_PATH the file path of a .mat
%   file with arguments defined here. Main args are:
%   solver = 'ga'
%   use_approx_fitness = false;
%   dist_foo = @histogram_sum_abs;
%   error_foo = {@histogramErrorOpti};
%   PopulationSize = 200;
%   CreationFcn = @gacreationheuristic1;
%
%   See also heatMapReconstruction, args_test_template,
%   args_test_solver_template

args_path = [mfilename('fullpath') '.mat'];
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

clearvars('L', 'multi_goal', 'symmetric');

% Update the variables that do not match the template
save(args_path, '*', '-append');

end
