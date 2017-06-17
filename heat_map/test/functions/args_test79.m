function [args_path] = args_test79()
%ARGS_TEST79 Synthetic goal, SA
%   ARGS_PATH = ARGS_TEST70() Returns in ARGS_PATH the file path of a .mat
%   file with arguments defined here.
%
%   See also heatMapReconstruction, args_test_template,
%   args_test_solver_template

%% Change common parameters
data_dir = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'data');
args_path = fullfile(data_dir, [mfilename('clas') '.mat']);
args_test_template(args_path, false);

solver = 'sa';

% Save all but L
save(args_path, '-regexp','^(?!(L|data_dir)$).', '-append');

% Update solver parameters
args_test_solver_template(args_path, solver);

L = load(args_path);
options = L.options;

goal_img_path = {'~/maya/projects/fire/images/test111_no_background/goal_cam1_synthetic_transfer.tif'};
goal_mask_img_path = {'~/maya/projects/fire/images/test111_no_background/fullmask.png'};
in_img_path = {'~/maya/projects/fire/images/test110_like_109_close_camera/test110_like_109_close_camera.tif'};
in_img_bg_path = in_img_path;
mask_img_path = goal_mask_img_path;
raw_file_path = 'data/from_dmitry/vox_bin_00841_clean_32.raw2';
density_file_path = '~/maya/projects/fire/data/from_dmitry/vox_bin_00841_clean_32.raw2';

scene_name = 'test111_no_background';
scene_img_folder = fullfile(L.project_path, 'images', [scene_name '/']);

skip_img_preprocessing = true;

error_foo = {@histogramErrorOpti, @imageSideDistributionInvariant};
prior_fncs = {};
prior_weights = [0.75, 0.25];

use_cache = false;

color_space = 'Lab';


maya_new_density_scale = 500;
init_exposure = 100;

options = L.options;

options.MaxIter = 1e6;
options.MaxFunEvals = 1e8;
time_limit = 6 * 60 * 60;
options.InitialTemperature = 1/6; % Factor to multiply (UB - LB)

% Save all but L
save(args_path, '-regexp','^(?!(L|data_dir)$).', '-append');

end
