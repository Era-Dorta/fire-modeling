function [args_path] = args_test64()
%ARGS_TEST64 ICM_RE voxel 64 two goal
%   ARGS_PATH = ARGS_TEST64() Returns in ARGS_PATH the file path of a .mat
%   file with arguments defined here.
%
%   See also heatMapReconstruction, args_test_template,
%   args_test_solver_template

%% Change common parameters
data_dir = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'data');
args_path = fullfile(data_dir, [mfilename('clas') '.mat']);
args_test_template(args_path, false);

solver = 'icm-re';

% Save all but L
save(args_path, '-regexp','^(?!(L|data_dir)$).', '-append');

% Update solver parameters
args_test_solver_template(args_path, solver);

L = load(args_path);
options = L.options;

goal_img_path = {'~/maya/projects/fire/data/from_dmitry/cam1/goal1-aligned.png',...
    '~/maya/projects/fire/data/from_dmitry/cam2/goal2-aligned.png'};
goal_mask_img_path = {'~/maya/projects/fire/data/from_dmitry/cam1/tri-map-aligned.png',...
    '~/maya/projects/fire/data/from_dmitry/cam2/tri-map2-aligned.png'};
in_img_path = {'~/maya/projects/fire/images/test110_like_109_close_camera/test110_like_109_close_camera.tif', ...
    '~/maya/projects/fire/images/test111_no_background/synthetic2.tif'};
in_img_bg_path = {'~/maya/projects/fire/images/test110_like_109_close_camera/background-new.png', ...
    '~/maya/projects/fire/images/test110_like_109_close_camera/background-new.png'};
mask_img_path = {'~/maya/projects/fire/images/test110_like_109_close_camera/mask.png',...
    '~/maya/projects/fire/images/test111_no_background/mask2.png'};
raw_file_path = 'data/from_dmitry/vox_bin_00841_clean_64.raw2';
density_file_path = '~/maya/projects/fire/data/from_dmitry/vox_bin_00841_clean_64.raw2';

scene_name = 'test111_no_background';
scene_img_folder = fullfile(L.project_path, 'images', [scene_name '/']);

error_foo = {@MSEPerceptual};
prior_fncs = {};
prior_weights = 1;

density_scales_range = [0.01 1000];
exposure_scales_range = [0.01 1000];

use_cache = false;

options.CreateSamplesFcn = @generate_gaussian_temperatures_icm;
options.UpdateSampleRangeFcn = @update_range_none_icm;
options.DataTermApproxFcn = {@eval_render_function_always_icm};
options.DataTermFcn = {@eval_render_function_always_icm};
options.PairWiseTermFcn = {@zero_pairwise_score_icm};
options.PairWiseTermFactors = [10];

initGuessFnc = @getMeanTemp_icm;

options.NeighbourhoodSize = 1;

% Save all but L
save(args_path, '-regexp','^(?!(L|data_dir)$).', '-append');

end
