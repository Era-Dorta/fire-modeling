function [args_path] = args_test77()
%ARGS_TEST77 GRAD scene111, camera
%   ARGS_PATH = ARGS_TEST60() Returns in ARGS_PATH the file path of a .mat
%   file with arguments defined here.
%
%   See also heatMapReconstruction, args_test_template,
%   args_test_solver_template

%% Change common parameters
data_dir = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'data');
args_path = fullfile(data_dir, [mfilename('clas') '.mat']);
args_test_template(args_path, false);

solver = 'grad';

% Save all but L
save(args_path, '-regexp','^(?!(L|data_dir)$).', '-append');

% Update solver parameters
args_test_solver_template(args_path, solver);

L = load(args_path);

goal_img_path = {'~/maya/projects/fire/data/from_dmitry/volumes/RequestedFrames/goal1-f1.png'};
goal_mask_img_path = {'~/maya/projects/fire/data/from_dmitry/volumes/RequestedFrames/goal-renamed/mask-full.png'};
in_img_path = goal_img_path;
in_img_bg_path = in_img_path;
mask_img_path = goal_mask_img_path;
raw_file_path = 'data/from_dmitry/volumes/frame00001vox_clean_32.raw2';
density_file_path = '~/maya/projects/fire/data/from_dmitry/volumes/frame00001vox_clean_32.raw2';

scene_name = 'test111_no_background_for_cam_align';
scene_img_folder = fullfile(L.project_path, 'images', [scene_name '/']);

error_foo = {@MSEPerceptual};
prior_fncs = {};
add_background = true;
prior_weights = [0.5, 0.5];

add_background = false;

density_scales_range = [0.01 1000];

cam_t = [0, 0, 8];
cam_r = [0, 0, 0];
cam_focal_length = 19;

cam_t_lb = [-20, -20, -20];
cam_t_ub = [20, 20, 20];
cam_r_lb = [0, 0, 0];
cam_r_ub = [360, 360, 360];
cam_focal_length_lb = 2.5;
cam_focal_length_ub = 500;

LB = [cam_t_lb, cam_r_lb, cam_focal_length_lb];
UB = [cam_t_ub, cam_r_ub, cam_focal_length_ub];

initGuessFnc = @getInitHeatMap_icm;

use_cache = false;

% Save all but L
save(args_path, '-regexp','^(?!(L|data_dir)$).', '-append');

end
