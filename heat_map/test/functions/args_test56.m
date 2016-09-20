function [args_path] = args_test56()
%ARGS_TEST56 ICM Vox_bin_00841 128 close, Vox_bin_00841 Goal resize
%   ARGS_PATH = ARGS_TEST56() Returns in ARGS_PATH the file path of a .mat
%   file with arguments defined here.
%
%   See also heatMapReconstruction, args_test_template,
%   args_test_solver_template

%% Change common parameters
data_dir = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'data');
args_path = fullfile(data_dir, [mfilename('clas') '.mat']);
args_test_template(args_path, false);

solver = 'icm';

% Save all but L
save(args_path, '-regexp','^(?!(L|data_dir)$).', '-append');

% Update solver parameters
args_test_solver_template(args_path, solver);

L = load(args_path);
options = L.options;

goal_img_path = {'~/maya/projects/fire/data/from_dmitry/cam1/goal1-aligned.png'};
goal_mask_img_path = {'~/maya/projects/fire/data/from_dmitry/cam1/tri-map-aligned.png'};
in_img_path = {'~/maya/projects/fire/images/test110_like_109_close_camera/test110_like_109_close_camera.tif'};
in_img_bg_path = {'~/maya/projects/fire/images/test110_like_109_close_camera/background-new.png'};
mask_img_path = {'~/maya/projects/fire/images/test110_like_109_close_camera/mask.png'};
raw_file_path = 'data/from_dmitry/vox_bin_00841_clean_128.raw2';
density_file_path = '~/maya/projects/fire/data/from_dmitry/vox_bin_00841_clean_128.raw2';

scene_name = 'test110_like_109_close_camera';
scene_img_folder = fullfile(L.project_path, 'images', [scene_name '/']);

error_foo = {@MSEPerceptual};
prior_fncs = {};
add_background = true;
prior_weights = 1;

add_background = true;

density_scales_range = [0.01 1000];

use_cache = false;

options.OutputFcn = [options.OutputFcn, {@gradestimate_density_scale}];

max_ite = inf; % Num of maximum iterations
maxFunEvals = max_ite; % Maximum number of allowed function evaluations
time_limit = 24 * 60 * 60; % 24 hours

options.MaxIterations = max_ite;
options.MaxFunctionEvaluations = maxFunEvals;

% Save all but L
save(args_path, '-regexp','^(?!(L|data_dir)$).', '-append');

end
